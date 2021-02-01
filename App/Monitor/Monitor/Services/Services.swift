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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if email.contains("admin") {
                let user = User(token: "some-magic-token")
                completion(.success(user))
                User.setUser(to: user)
            } else {
                completion(.failure(.wrongCredentials))
            }
        }
    }
    
    /// Retrieves the current state of the system
    ///
    /// - parameter completion: Completion block with the current system state if it was possible to fetch.
    static func getSystemState(completion: @escaping (SystemState?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(self.fakeSystemState())
        }
    }
    
    /// Fake system states that shows random values and sometimes an error in a reading
    private static func fakeSystemState() -> SystemState {
        let temperatureGenerator: () -> String = { "\(76+Int.random(in: -2...2)) °F" }
        let pressureGenerator: () -> String = { "\(700+Int.random(in: -99...99)) mm Hg" }
        let temperatureWithErrorGenerator: () -> String = { Int.random(in: 0...100) < 10 ? "ERROR!" : temperatureGenerator() }
        let pressureWithErrorGenerator: () -> String = { Int.random(in: 0...100) < 10 ? "ERROR!" : pressureGenerator() }
        
        return SystemState(date: Date(),
                           temperatures: [
                            Reading(name: "Wagon A", value: temperatureWithErrorGenerator() ),
                            Reading(name: "Wagon B", value: temperatureWithErrorGenerator() ),
                            Reading(name: "Wagon C", value: temperatureWithErrorGenerator() ),
                            Reading(name: "Wagon D", value: temperatureWithErrorGenerator() ),
                            Reading(name: "Wagon E", value: temperatureWithErrorGenerator() ),
                           ],
                           pressure: [
                            Reading(name: "Container A-1", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container A-2", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container A-3", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container B-1", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container B-2", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container B-3", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container C-1", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container D-1", value: pressureWithErrorGenerator() ),
                            Reading(name: "Container E-1", value: pressureWithErrorGenerator() ),
                           ])
    }
}
