import Foundation

public struct Courier {
    public let id: String
    public let name: String
    public let location: Location
    public let packageId: String?
    public let vehicleId: String?
}

extension Courier: Equatable {}

extension Courier {
    init(row: DBCourierRow, location: Location) {
        self.id = row.id
        self.name = row.name
        self.location = location
        self.packageId = row.packageId
        self.vehicleId = row.vehicleId
    }
}
