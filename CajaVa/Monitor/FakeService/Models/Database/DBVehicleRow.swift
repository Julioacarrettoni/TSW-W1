import Foundation

public struct DBVehicleRow: Codable, Equatable, IdentifiableRow {
    public let tick: Int
    public let id: String
    public let name: String
    public let courierId: String?
    
    public init(tick: Int, id: String, name: String, courierId: String?) {
        self.tick = tick
        self.id = id
        self.name = name
        self.courierId = courierId
    }
}

public func distinctVehicleRow(lhs: DBVehicleRow, rhs: DBVehicleRow) -> Bool {
    let a = DBVehicleRow(tick: 0, id: lhs.id, name: lhs.name, courierId: lhs.courierId)
    let b = DBVehicleRow(tick: 0, id: rhs.id, name: rhs.name, courierId: rhs.courierId)
    return a != b
}
