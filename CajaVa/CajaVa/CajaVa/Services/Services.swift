import Combine
import FakeService
import Foundation

/// Possible login erros
enum LoginError: Error {
    /// When the credentials are right but there is a problem with the account (maybe blocked)
    case contactSupport
    /// When either the email or the password is wrong
    case wrongCredentials
}

/// Generic errors associated with network requests
enum NetworkError: Error {
    /// A network error the app was unabled to properly identity
    case unknown
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
    
    //MARK: - Combine alternatives
    /// Retrieves the configuration for the current user, includes delays for the services
    ///
    /// - returns a publisher that emits configurations or network errors
    static func getConfiguration() -> AnyPublisher<Configuration, NetworkError> {
        return Deferred {
            Future { promise in
                FakeServices.shared.getConfiguration { configuration in
                    if let configuration = configuration {
                        promise(.success(configuration))
                    } else {
                        promise(.failure(.unknown))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Retrieves the current state of the system
    ///
    /// - returns a publisher that emits the current global state or nil if not available
    static func getSystemState() -> AnyPublisher<GlobalState?, Never> {
        return Deferred {
            Future { promise in
                FakeServices.shared.getSystemState { state in
                    promise(.success(state))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Used to setup different network scenarios for demo purposes
    static func setup() {
        Environment.setNotFailsWithSpeedMultipler(of: 4)
//        Environment.setIntermitentFailure()
//        Environment.set4thDelayed(by: 10)
//        Environment.setProduction()
    }
}
