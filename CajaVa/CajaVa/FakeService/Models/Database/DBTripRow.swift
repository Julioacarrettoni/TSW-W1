import Foundation

public struct DBTripRow: Codable, Equatable, IdentifiableRow {
    public let tick: Int
    public let id: String
    public let position: Location
    
    public init(tick: Int, id: String, position: Location) {
        self.tick = tick
        self.id = id
        self.position = position
    }
}

public func distincTripRow(lhs: DBTripRow, rhs: DBTripRow) -> Bool {
    let a = DBTripRow(tick: 0, id: lhs.id, position: lhs.position)
    let b = DBTripRow(tick: 0, id: rhs.id, position: rhs.position)
    return a != b
}
