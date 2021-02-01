import Foundation

public struct Package {
    public let id: String
    public let destination: Location
    public let courierId: String?
    public let delivered: Bool
    public let location: Location
}

extension Package: Equatable {}

extension Package {
    init(row: DBPackageRow, location: Location) {
        self.id = row.id
        self.destination = row.destination
        self.courierId = row.courierId
        self.delivered = row.delivered
        self.location = location
    }
}
