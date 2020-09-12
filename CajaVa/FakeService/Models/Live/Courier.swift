import Foundation

public struct Courier {
    public let id: String
    public let name: String
    public let location: Location
    public let idle: Bool
    public let packageId: String?
    public let vehicleId: String?
}

extension Courier: Hashable {}

extension Courier {
    init(row: DBCourierRow, location: Location) {
        self.id = row.id
        self.name = row.name
        self.location = location
        self.idle = row.tripId == nil
        self.packageId = row.packageId
        self.vehicleId = row.vehicleId
    }
}
