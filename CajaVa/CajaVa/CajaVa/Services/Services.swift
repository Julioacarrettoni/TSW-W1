import FakeService
import Foundation

/// Possible login erros
enum LoginError: Error {
    /// When the credentials are right but there is a problem with the account (maybe blocked)
    case contactSupport
    /// When either the email or the password is wrong
    case wrongCredentials
}

enum Services {
    /// Request a valid user for the provided credentials if they match the records
    ///
    /// - parameter email:      Valid user email that must exist on the database
    /// - parameter password:   Valid password that matches the email
    /// - parameter completion: Completion block with a result of either the User or a login erro
    static func login(email: String, password: String, completion: @escaping (Result<User, LoginError>) -> Void) {        
        FakeServices.shared.login(email: email, password: password) { token in
            guard let user = token.map(User.init(token:)) else {
                completion(.failure(.wrongCredentials))
                return
            }
            
            completion(.success(user))
            User.setUser(to: user)
        }
    }
    
    /// Retrieves the current state of the system
    ///
    /// - parameter completion: Completion block with the current global state if it was possible to fetch.
    static func getSystemState(completion: @escaping (GlobalState?) -> Void) {
        FakeServices.shared.getSystemState(completion: completion)
    }
    
    /// Retrieves the configuration for the current user, includes delays for the services
    /// - parameter completion: Completion block with the current configuration values if it was possible to fetch.
    static func getConfiguration(completion: @escaping (Configuration?) -> Void) {
        FakeServices.shared.getConfiguration(completion: completion)
    }
    
    
    /// Used to setup different network scenarios for demo purposes
    static func setup() {
        Environment.setNotFailsWithSpeedMultipler(of: 4)
//        Environment.setIntermitentFailure()
//        Environment.set4thDelayed(by: 10)
//        Environment.setProduction()
    }
}
