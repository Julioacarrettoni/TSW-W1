import Foundation

public struct GlobalState: Equatable {
    public let central: Location
    public let couriers: [Courier]
    public let packages: [Package]
    public let vehicles: [Vehicle]
}
