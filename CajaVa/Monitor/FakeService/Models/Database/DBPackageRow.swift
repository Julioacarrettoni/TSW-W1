import Foundation

public struct DBPackageRow: Codable, Equatable, IdentifiableRow {
    public let tick: Int
    public let id: String
    public let destination: Location
    public let courierId: String?
    public let delivered: Bool
    
    public init(tick: Int, id: String, destination: Location, courierId: String?, delivered: Bool) {
        self.tick = tick
        self.id = id
        self.destination = destination
        self.courierId = courierId
        self.delivered = delivered
    }
}

public func distinctPackageRow(lhs: DBPackageRow, rhs: DBPackageRow) -> Bool {
    let a = DBPackageRow(tick: 0, id: lhs.id, destination: lhs.destination, courierId: lhs.courierId, delivered: lhs.delivered)
    let b = DBPackageRow(tick: 0, id: rhs.id, destination: rhs.destination, courierId: rhs.courierId, delivered: rhs.delivered)
    return a != b
}
