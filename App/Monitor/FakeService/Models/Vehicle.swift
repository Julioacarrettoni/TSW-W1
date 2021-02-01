import Foundation

public struct Vehicle {
    public let id: String
    public let courierId: String?
    public let location: Location
    public let name: String
}

extension Vehicle: Equatable {}

extension Vehicle {
    init(row: DBVehicleRow, location: Location) {
        self.id = row.id
        self.courierId = row.courierId
        self.location = location
        self.name = row.name
    }
}
