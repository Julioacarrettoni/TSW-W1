import MapKit
import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak private var segmentedControl: UISegmentedControl!
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var menuButton: UIButton!
    
    /// Abstraction to handle rendering the TableView
    private lazy var tableViewHandler = TableViewHandler(tableView: self.tableView)
    
    /// Flag to keep track if we already refreshed the UI once
    private var uiWasLoadedOnce = false
    
    /// The current state of the system
    private var systemState: SystemState? {
        didSet {
            self.updateUI()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setLoading(true)
        self.segmentedControl.addTarget(self, action: #selector(self.onSegmentedControlValueChanged), for: .valueChanged)
        self.tableView.alpha = 0.0
        self.segmentedControl.alpha = 0.0
        self.fetchSystemState()
    }
    
    /// Set the UI to the loading state
    ///
    ///- parameter isLoading: Whether the UI should be shown as loading or not
    private func setLoading(_ isLoading: Bool) {
        self.view.isUserInteractionEnabled = !isLoading
        self.mainStack.alpha = isLoading ? 0.3 : 1.0
        self.activityIndicator.theOtherIsAnimating = isLoading
    }
    
    /// Fetches the system state from the server, updates the UI with the new state and repeats the loop forever
    private func fetchSystemState() {
        Services.getSystemState { [weak self] state in
            self?.systemState = state
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self?.fetchSystemState()
            }
        }
    }
        
    /// Updates the UI based on the current SystemState
    private func updateUI() {
        if !self.uiWasLoadedOnce {
            self.uiWasLoadedOnce = true
            self.setLoading(false)
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.tableView.alpha = 1.0
                self?.segmentedControl.alpha = 1.0
            }
        }

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
    /// - returns: Array of Entitity built from elements of the current SystemState given the selected value on the segmented control
    private func selectedTypeToEntities() -> [Entity] {
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            return self.systemState?.temperatures.map { Entity(title: $0.name, subtitle: $0.value) } ?? []
        case 1:
            return self.systemState?.pressure.map { Entity(title: $0.name, subtitle: $0.value) } ?? []
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
