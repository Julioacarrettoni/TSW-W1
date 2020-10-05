import UIKit
import FakeService
import Combine

class LoginViewController: UIViewController {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loginError: UILabel!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @Published private var emailIsValid: Bool = false       // This is both a property and a Published
    @Published private var passwordIsValid: Bool = false    // This is both a property and a Published
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Login button initially disabled
        self.loginButton.isEnabled = false
        
        // All errors initially hidden
        self.loginError.isHidden = true
        self.emailErrorLabel.isHidden = true
        self.passwordErrorLabel.isHidden = true
        
        // Send errors to back so it doesn't look ugly when animating in/out
        self.loginError.sendToBack()
        self.emailErrorLabel.sendToBack()
        self.passwordErrorLabel.sendToBack()
        
        self.$emailIsValid                                      // This is a publisher that emits whenever self.emailIsValid changes
            .dropFirst()                                        // Ignores the first emited event
            .removeDuplicates()                                 // Makes the publisher only emit if the new value is different from the last emited value
            .sink { [weak self] isValid in                      // Attaches a closure to a publisher whose output is Bool, everytime an event is emited the closure is executed
                UIView.animate(withDuration: 0.3) {
                    self?.emailErrorLabel.isHidden = isValid
                }
            }
            .store(in: &self.cancellables)                      // We need to keep the cancellable alive for as long as we want this behavior to continue
        
        self.$passwordIsValid                                   // This is a publisher that emits whenever self.emailIsValid changes
            .dropFirst()                                        // Ignores the first emited event
            .removeDuplicates()                                 // Makes the publisher only emit if the new value is different from the last emited value
            .sink { [weak self] isValid in                      // Attaches a closure to a publisher whose output is Bool, everytime an event is emited the closure is executed
                UIView.animate(withDuration: 0.3) {
                    self?.passwordErrorLabel.isHidden = isValid
                }
            }
            .store(in: &self.cancellables)                      // We need to keep the cancellable alive for as long as we want this behavior to continue
        
        self.$emailIsValid.combineLatest(self.$passwordIsValid) // Creates a new publisher that emits a tuple with the most recent value whenever any of them emits and we have enought emited valus to fill the tuple
            .map { $0 && $1 }                                   // Turns the output of the Publisher from (Bool, Bool) to just Bool where is only true if both were true
            .removeDuplicates()                                 // Makes the publisher only emit if the new value is different from the last emited value
            .assign(to: \.isEnabled, on: self.loginButton)      // Assigns the value emited by the publisher directly into a property in an object
            .store(in: &self.cancellables)                      // We need to keep the cancellable alive for as long as we want this behavior to continue
        
        // Wire textfield events to the "updateUI" function to keep ui updated
        self.emailTextField.addTarget(self, action: #selector(self.emailTextFieldChanged), for: .allEditingEvents)
        self.passwordTextfield.addTarget(self, action: #selector(self.passwordTextFieldChanged), for: .allEditingEvents)
    }
            
    /// Shows/hides errors related to email textfields
    @objc private func emailTextFieldChanged() {
        // We check if the password is valid
        self.emailIsValid = self.emailTextField.text?.isValidEmail() ?? false
    }

    /// Shows/hides errors related to password textfields
    @objc private func passwordTextFieldChanged() {
        // We check if the password is valid
        self.passwordIsValid = self.passwordTextfield.text?.isValidPassword() ?? false
    }
    
    /// Action fired when the login button is activated
    @IBAction func onLoginButtonTouchUpInside() {
        // If we don't have both an email and a password we show an error and short the function
        guard let email = self.emailTextField.text,
              let password = self.passwordTextfield.text
        else {
            // The the UI to show the wrong credentials error
            return self.setLoginError(.wrongCredentials)
        }
        
        // Set the UI to the loading state
        self.setLoading(true)
        // Hide any login error that might be currently showing
        self.setLoginError(nil)
        // Request the user for the given email+password to the service, if any
        Services.login(email: email, password: password) { [weak self] result in
            self?.setLoading(false)
            switch result {
            case .success:
                break;
            case .failure(let error):
                self?.setLoginError(error)
            }
        }
    }
    
    /// Set the UI to the loading state
    ///
    ///- parameter isLoading: Whether the UI should be shown as loading or not
    private func setLoading(_ isLoading: Bool) {
        self.view.isUserInteractionEnabled = !isLoading
        self.mainStackView.alpha = isLoading ? 0.3 : 1.0
        self.activityIndicator.theOtherIsAnimating = isLoading
    }
    
    /// Updates the UI to show/hide login errors
    ///
    /// - parameter error: The error to show or nil if no error should be shown at all.
    private func setLoginError(_ error: LoginError?) {
        UIView.animate(withDuration: 0.5) {
            switch error {
            case .none:
                self.loginError.isHidden = true
            case .some(.wrongCredentials):
                self.loginError.text = "Email or password does not match"
                self.loginError.isHidden = false
            case .some(.contactSupport):
                self.loginError.text = "Please contact support"
                self.loginError.isHidden = false
            }
        }
    }
}

extension LoginViewController {
    /// Convenience factory to instantiate and instace from the Main storyboard
    static func createFromStoryboard() -> UIViewController {
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Login")
    }
}
