import UIKit
import FakeService

class LoginViewController: UIViewController {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loginError: UILabel!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    @IBOutlet weak var loginButton: UIButton!
    
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
        
        // Wire textfield events to the "updateUI" function to keep ui updated
        self.emailTextField.addTarget(self, action: #selector(self.emailTextFieldChanged), for: .allEditingEvents)
        self.passwordTextfield.addTarget(self, action: #selector(self.passwordTextFieldChanged), for: .allEditingEvents)
    }
            
    /// Shows/hides errors related to email textfields
    @objc private func emailTextFieldChanged() {
        // We check if the password is valid
        let validEmail = self.emailTextField.text?.isValidEmail() ?? false
        // We update the UI with the new calculated value and the previous one that was stored on isHidden
        self.updateUI(validEmail: validEmail, validPassword: self.passwordErrorLabel.isHidden)
    }

    /// Shows/hides errors related to password textfields
    @objc private func passwordTextFieldChanged() {
        // We check if the password is valid
        let validPassword = self.passwordTextfield.text?.isValidPassword() ?? false
        // We update the UI with the new calculated value and the previous one that was stored on isHidden
        self.updateUI(validEmail: self.emailErrorLabel.isHidden, validPassword: validPassword)
    }
    
    /// Updates the UI based on whether the email and password are valid
    ///
    /// - parameter validEmail:    Whether the email is valid
    /// - parameter validPassword: Whether the password is valid
    private func updateUI(validEmail: Bool, validPassword: Bool) {
        UIView.animate(withDuration: 0.3) {
            // If the email is not valid the error label below the email textfielf is shown
            if self.emailErrorLabel.isHidden != validEmail { // To prevent bug with StackViews
                self.emailErrorLabel.isHidden = validEmail
            }
            
            // If the password is not valid the error label below the password textfielf is shown
            if self.passwordErrorLabel.isHidden != validPassword { // To prevent bug with StackViews
                self.passwordErrorLabel.isHidden = validPassword
            }
            
            // Only when both email and password are valid the login button is made enabled
            self.loginButton.isEnabled = validEmail && validPassword
        }
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
