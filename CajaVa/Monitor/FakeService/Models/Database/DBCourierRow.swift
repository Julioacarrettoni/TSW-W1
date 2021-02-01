import Foundation

public struct DBCourierRow: Codable, Equatable, IdentifiableRow {
    public let tick: Int
    public let id: String
    public let name: String
    public let tripId: String?
    public let packageId: String?
    public let vehicleId: String?
    
    public init(tick: Int, id: String, name: String, tripId: String?, packageId: String?, vehicleId: String?) {
        self.tick = tick
        self.id = id
        self.name = name
        self.tripId = tripId
        self.packageId = packageId
        self.vehicleId = vehicleId
    }
}

public func distinctCourierRow(lhs: DBCourierRow, rhs: DBCourierRow) -> Bool {
    let a = DBCourierRow(tick: 0, id: lhs.id, name: lhs.name, tripId: lhs.tripId, packageId: lhs.packageId, vehicleId: lhs.vehicleId)
    let b = DBCourierRow(tick: 0, id: rhs.id, name: rhs.name, tripId: rhs.tripId, packageId: rhs.packageId, vehicleId: rhs.vehicleId)
    return a != b
}
