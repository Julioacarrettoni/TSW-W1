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
    
    /// Flag to keep track if we already did a zoom on the map or not
    private var mapZoomed = false

    /// Configuration used for pooling
    private var configuration: Configuration?
    
    /// The current global state of the system, includes map information and entities details
    private var globalState: GlobalState? {
        didSet {
            self.updateUI()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setLoading(true)
        self.fetchConfiguration()
        self.segmentedControl.addTarget(self, action: #selector(self.onSegmentedControlValueChanged), for: .valueChanged)
    }
    
    /// Set the UI to the loading state
    ///
    ///- parameter isLoading: Whether the UI should be shown as loading or not
    private func setLoading(_ isLoading: Bool) {
        self.view.isUserInteractionEnabled = !isLoading
        self.mainStack.alpha = isLoading ? 0.3 : 1.0
        self.activityIndicator.theOtherIsAnimating = isLoading
    }
    
    /// Fetches the configuration for the current user and then kicks a refresh of the system state based on said configuration
    private func fetchConfiguration() {
        Services.getConfiguration {[weak self] configuration in
            guard let configuration = configuration  else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.fetchConfiguration()
                }
                return
            }
            
            self?.configuration = configuration
            self?.fetchSystemState()
        }
    }
    
    /// Fetches the global state from the server, updates the UI with the new state and repeats the loop forever
    private func fetchSystemState() {
        Services.getSystemState { [weak self] state in
            self?.setLoading(false)
            self?.globalState = state
            
            if let delay = self?.configuration?.delays.map {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.fetchSystemState()
                }
            }
        }
    }
        
    /// Updates the UI based on the current GlobalState
    private func updateUI() {
        guard let state = self.globalState else {
            return
        }
        
        // Centers the map on the central but only once
        if !self.mapZoomed {
            self.mapZoomed.toggle()
            let location = CLLocationCoordinate2D(latitude: state.central.lat, longitude: state.central.lng)
            self.mapView.setCamera(MKMapCamera(lookingAtCenter: location, fromEyeCoordinate: location, eyeAltitude: 7000.0), animated: false)
        }
        
        self.mapViewDelegate.annotations = state.makeAnnotations()
        self.tableViewHandler.entities = self.selectedTypeToEntities()
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
    
    /// Fires whenever the segmented button value chanegs
    @objc func onSegmentedControlValueChanged() {
        self.updateUI()
    }
    
    /// Return an array of Entity based on the current state of the app
    ///
    /// - returns: Array of Entitity built from elements of the current GlobalState given the selected value on the segmented control
    private func selectedTypeToEntities() -> [Entity] {
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            return self.globalState?.packages.map(Entity.init(package:)) ?? []
        case 1:
            return self.globalState?.couriers.map(Entity.init(courier:)) ?? []
        case 2:
            return self.globalState?.vehicles.map(Entity.init(vehicle:)) ?? []
        default:
            return []
        }
    }
}

extension MainViewController {
    /// Convenience factory to instantiate and instace from the Main storyboard
    static func createFromStoryboard() -> UIViewController {
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Main")
    }
}
