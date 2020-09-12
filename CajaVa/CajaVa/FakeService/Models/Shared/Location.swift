import Foundation

public struct Location: Codable, Hashable {
    public let lat: Double
    public let lng: Double
    
    public init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
}

extension Location: Equatable {}

extension Location {
    public static var centralLocation: Location { Location(lat: 37.785808985747316, lng:-122.40639245940856) }
}
