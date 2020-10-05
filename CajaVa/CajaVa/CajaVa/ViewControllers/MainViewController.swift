import Combine
import FakeService
import MapKit
import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak private var mapView: MKMapView!
    @IBOutlet weak private var segmentedControl: UISegmentedControl!
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var menuButton: UIButton!
    
    /// Abstraction to handle rendering markers and path on the map
    private lazy var mapViewDelegate = MapViewDelegate(mapView: self.mapView)
    /// Abstraction to handle rendering the TableView
    private lazy var tableViewHandler = TableViewHandler(tableView: self.tableView)

    /// Configuration used for pooling
    @Published private var configuration: Configuration?
    
    /// The current global state of the system, includes map information and entities details
    @Published private var globalState: GlobalState? = nil
    
    /// Set of cancelables related to subscriptions we want to keep active as long as the view controller is alive
    private var cancellables = Set<AnyCancellable>()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setLoading(true)
        
        // Only fires once removing the loading indicator and zooming on the map
        self.$globalState                                                       // This is a publisher that emits whenver the value of self.globalState changes
            .compactMap { $0 }                                                  // Turns the output of the publisher from GlobalState? to GlobalState by non emitting the nil values
            .first()                                                            // The publisher will complete terminating the subscription after a single element is emited
            .map { state in                                                     // Turns the output of the publisher from GlobalState into CLLocationCoordinate2D
                CLLocationCoordinate2D(latitude: state.central.lat, longitude: state.central.lng)
            }
            .sink { [weak self] location in                                     // Attaches a closure to the publisher that will be executed on each event emission, in this case it will happens a maximum of one time due to the "first"
                self?.setLoading(false)
                self?.mapView.setCamera(MKMapCamera(lookingAtCenter: location, fromEyeCoordinate: location, eyeAltitude: 7000.0), animated: false)
            }
            .store(in: &self.cancellables)                                      // We need to keep the cancellable alive for as long as we want this behavior to continue
        
        // We turn global states into annotations and bind them to the mapViewDelegate
        self.$globalState                                                       // This is a publisher that emits whenver the value of self.globalState changes
            .compactMap { $0 }                                                  // Turns the output of the publisher from GlobalState? to GlobalState by non emitting the nil values
            .map { $0.makeAnnotations() }                                       // Turns the output of the publisher from GlobalState to [TrackerPointAnnotation]
            .removeDuplicates()                                                 // Makes the publisher only emit if the new value is different from the last emited value
            .assign(to: \.annotations, on: self.mapViewDelegate)                // Assigns the value emited by the publisher directly into a property in an object
            .store(in: &self.cancellables)                                      // We need to keep the cancellable alive for as long as we want this behavior to continue
        
        // Everytime the either rhe global state or the segmented button change we
        // reclaculate which entities to show and bind them into the tableViewHandler
        self.segmentedControl.publisher(for: \.selectedSegmentIndex)            // This is a publisher based on KVO that will emit an event everytime the specified property changes value
            .combineLatest(self.$globalState.compactMap { $0 } )                // Creates a new publisher that emits a tuple with the most recent value whenever any of them emits and we have enought emited valus to fill the tuple
            .removeDuplicates(by: { $0 == $1 })                                 // Makes the publisher only emit if the new value is different from the last emited value using a closure as the mechanism to degine equality
            .map { index, state -> [Entity] in                                  // Maps a tuple of Int,GLobalState into [Entity]
                switch index {
                    case 0:
                        return state.packages.map(Entity.init(package:))
                    case 1:
                        return state.couriers.map(Entity.init(courier:))
                    case 2:
                        return state.vehicles.map(Entity.init(vehicle:))
                    default:
                        return []
                }
            }
            .assign(to: \.entities, on: self.tableViewHandler)                  // Assigns the value emited by the publisher directly into a property in an object
            .store(in: &self.cancellables)                                      // We need to keep the cancellable alive for as long as we want this behavior to continue
        
        self.startPoling()
    }
    
    /// Set the UI to the loading state
    ///
    ///- parameter isLoading: Whether the UI should be shown as loading or not
    private func setLoading(_ isLoading: Bool) {
        self.view.isUserInteractionEnabled = !isLoading
        self.mainStack.alpha = isLoading ? 0.3 : 1.0
        self.activityIndicator.theOtherIsAnimating = isLoading
    }
    
    /// Starts poling for configuration and global state changes
    private func startPoling() {
        // We will use this subject to trigger configuration refreshes
        let fetchConfiguration = PassthroughSubject<Void, Never>()
        
        // Used to re-fetch configurations and store them on the local propery
        fetchConfiguration
            .map { _ in return Services.getConfiguration().retry(.max) }    // Every time fetchConfiguration emits an event we request the configuration and we keep retrying the request forever
            .switchToLatest()                                               // This cancels previous publishers, so any still ongoing network request gets cancel
            .map { value -> Configuration? in return value }                // This map is a trick to turn the Output from Configuration to Configuration?
            .replaceError(with: nil)                                        // Now that the stream supports optionals we replace errors with nils turning the stream into <Configuration?, Never>
            .removeDuplicates()                                             // We ignore events if the values are the same as before
            .assign(to: &self.$configuration)                               // As the stream matched the published property we can assign directly
        
        // On every configuration change a new timer is created based on the
        // value for configuration.delays.configuration
        self.$configuration                                                 // Everytime the configuration value changes an event is emited
            .compactMap { $0 }                                              // We ignore events where the value is nil
            .map (\.delays.configuration)                                   // We are only interested on the value of configuration.delays.configuration
            .removeDuplicates()                                             // We can avoid unnecesary operations by ignoring duplicated events
            .map { delay in
                Timer.publish(every: delay, on: .main, in: .default)        // Each even is a value for delay different than before so we create a new timer
                    .autoconnect()                                          // Starts the timer as soon as it has a subscriber
            }
            .switchToLatest()                                               // This cancels any other publisher previously generated so any previous timer gets invalidated.
            .sink { _ in fetchConfiguration.send() }                        // Every time the timer fires se send an even throw fetchConfiguration triggering a new call to fetch the configuration
            .store(in: &self.cancellables)                                  // We need to keep the cancellable alive for as long as we want this behavior to continue
        
        // As soon as we have the first configuration we want to fetch the global state
        self.$configuration                                                 // Everytime the configuration value changes an event is emited
            .compactMap { $0 }                                              // We ignore events where the value is nil
            .first()                                                        // The publisher will complete terminating the subscription after a single element is emited
            .flatMap { _ in Services.getSystemState() }                     // We swap the publisher with a getSystemState one. As we have a first() no other publishers will be created so we don't need to do map+switchToLatest
            .compactMap { $0 }                                              // We are not interested in nil valies
            .assign(to: &self.$globalState)                                 // We can bind the stream directly into the Published property
        
        // On every configuration change a new timer is created based on the
        // value for configuration.delays.map and a call to getSystemState is performed
        self.$configuration
            .compactMap { $0 }                                              // We ignore events where the value is nil
            .map { $0.delays.map }                                          // We are only interested on the value of configuration.delays.configuration
            .removeDuplicates()                                             // We can avoid unnecesary operations by ignoring duplicated events
            .map { delay in
                Timer.publish(every: delay, on: .main, in: .default)        // Each even is a value for delay different than before so we create a new timer
                    .autoconnect()                                          // Starts the timer as soon as it has a subscriber
            }
            .switchToLatest()                                               // This cancels any other publisher previously generated so any previous timer gets invalidated.
            .map { _ in Services.getSystemState() }                         // Everytime the timer fires a network call to retrieve the system state is made
            .switchToLatest()                                               // This cancels previous publishers, so any still ongoing network request gets cancel
            .compactMap { $0 }                                              // We are not interested in nil valies
            .assign(to: &self.$globalState)                                 // We can bind the stream directly into the Published property
            
        
        // And this is the event that kickstarts the whole ordeal
        fetchConfiguration.send()
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in fetchConfiguration.send() }
            .store(in: &self.cancellables)
    }
    
    // MARK: - Actions
    /// Fires when the menu button is touched
    @IBAction func onMenuButtonTouchUpInside() {
        let alert = UIAlertController(title: "Fancy Menu", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive , handler:{ (UIAlertAction)in
            User.logout()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true)
    }
}

extension MainViewController {
    /// Convenience factory to instantiate and instace from the Main storyboard
    static func createFromStoryboard() -> UIViewController {
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Main")
    }
}
