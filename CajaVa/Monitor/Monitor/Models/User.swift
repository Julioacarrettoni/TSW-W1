import Foundation

private let kTokenKeyForPersistance = "token"

/// Notification event tha is emited whenever the user logs in and out
extension Notification.Name {
    static let userLoggedStateChanged = Notification.Name("userLoggedStateChanged")
}

/// The user of the app
final class User {
    /// Token required to make service calls
    let token: String

    init(token: String) {
        self.token = token
    }
    
    /// Convinience access to the current user if any
    static private(set) var currentUser: User?
        
    /// Sets a given user as the currently logged in user, caches and emmits related events
    static func setUser(to user: User) {
        self.currentUser = user
        UserDefaults.standard.setValue(user.token, forKey: kTokenKeyForPersistance)
        NotificationCenter.default.post(name: .userLoggedStateChanged, object: nil)
    }
    
    /// logs out the current user, clears the cache and emmits related events
    static func logout() {
        User.currentUser = nil
        UserDefaults.standard.removeObject(forKey: kTokenKeyForPersistance)
        NotificationCenter.default.post(name: .userLoggedStateChanged, object: nil)
    }
    
    /// Tries to retrieve a user from the cache
    static func loadFromCache() {
        guard let token = UserDefaults.standard.value(forKey: kTokenKeyForPersistance) as? String else {
            return
        }
        
        self.currentUser = User(token: token)
    }
}
