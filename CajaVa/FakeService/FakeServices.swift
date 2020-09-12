import Foundation

public struct Environment {
    public var tick: () -> Double
    public var delay: () -> Double
    public var failNext: () -> Bool
    public var courierFile :String
    public var tripsFile :String
    public var packagesFile :String
    public var vahiclesFile :String
    public var centralLocation: Location
}

var appLaunchedDate = Date()

public extension Environment {
    static var production = Environment(tick: { -appLaunchedDate.timeIntervalSinceNow },
                                               delay: { 0.5 },
                                               failNext: { false },
                                               courierFile: "couriers",
                                               tripsFile: "trips",
                                               packagesFile: "packages",
                                               vahiclesFile: "vehicles",
                                               centralLocation: Location.centralLocation
    )
    
    static var mock = Environment(tick: { 1 },
                                  delay: { 0 },
                                  failNext: { false },
                                  courierFile: "mockCouriers",
                                  tripsFile: "mockTrips",
                                  packagesFile: "mockPackages",
                                  vahiclesFile: "mockVehicles",
                                  centralLocation: Location.centralLocation
    )
}

public var Current = Environment.production

public final class FakeServices {
    public static var shared = FakeServices()
    
    private let courierRows: [DBCourierRow]
    private let tripRows: [DBTripRow]
    private let packagesRows: [DBPackageRow]
    private let vehiclesRows: [DBVehicleRow]
    
    init() {
        self.courierRows = loadJSON(file: Current.courierFile, bundle: Bundle(for: FakeServices.self))
        self.tripRows = loadJSON(file: Current.tripsFile, bundle: Bundle(for: FakeServices.self))
        self.packagesRows = loadJSON(file: Current.packagesFile, bundle: Bundle(for: FakeServices.self))
        self.vehiclesRows = loadJSON(file: Current.vahiclesFile, bundle: Bundle(for: FakeServices.self))
    }
    
    public func login(email: String, password: String, completion: @escaping (String?) -> ()) {
        self.asyncDelay {
            if email.contains("admin") {
                completion("0000")
            } else if email.contains("support") {
                completion("1111")
            } else {
                completion(nil)
            }
        }
    }
    
    public func getSystemState(completion: @escaping (GlobalState?) -> ()) {
        guard !Current.failNext() else {
            return self.asyncDelay { completion(nil) }
        }

        let tick = Int(Current.tick())
        let couriers = self.latestCourierState(for: tick)
        let packages = self.latestPackagesState(for: tick, given: couriers)
        let vehicles = self.latestVehiclesState(for: tick, given: couriers)
        self.asyncDelay {
            completion(GlobalState(
                central: Current.centralLocation,
                couriers: couriers,
                packages: packages,
                vehicles: vehicles)
            )
        }
    }
    
    public func getConfiguration(completion: @escaping (Configuration?) -> ()) {
        guard !Current.failNext() else {
            return self.asyncDelay { completion(nil) }
        }
        
        self.asyncDelay {
            completion(Configuration(delays: .init(configuration: 10,
                                                   map: 1,
                                                   path: 1),
                                     central: .centralLocation))
        }
    }
}

// MARK: - Private methods
extension FakeServices {
    private func latestCourierState(for tick: Int) -> [Courier] {
        let locationsPerTripId: [String: Location] = self.latest(from: self.tripRows, upToTick: tick).reduce([:]) {
            var dict = $0
            dict[$1.id] = $1.position
            return dict
        }
        
        return self.latest(from: self.courierRows, upToTick: tick).map { row in
            let location: Location = row.tripId.flatMap { locationsPerTripId[$0] } ?? Current.centralLocation
            return Courier(row: row, location: location)
        }
        .sorted(by: { $0.id < $1.id })
    }
    
    private func latestPackagesState(for tick: Int, given couriers: [Courier]) -> [Package] {
        self.latest(from: self.packagesRows, upToTick: tick).map { row in
            let location = couriers.first(where: { $0.packageId == row.id })?.location ?? (row.delivered ? row.destination : Current.centralLocation)
            return Package(row: row, location: location)
        }
        .sorted(by: { $0.id < $1.id })
    }

    private func latestVehiclesState(for tick: Int, given couriers: [Courier]) -> [Vehicle] {
        self.latest(from: self.vehiclesRows, upToTick: tick).map { row in
            let location = couriers.first(where: { $0.vehicleId == row.id })?.location ?? Current.centralLocation
            return Vehicle(row: row, location: location)
        }
        .sorted(by: { $0.id < $1.id })
    }
    
    private func asyncDelay(closure: @escaping ()-> Void ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Current.delay()) {
            closure()
        }
    }
    
    private func latest<T: IdentifiableRow>(from array: [T], upToTick tick: Int) -> [T] {
        let uptoIndex = array.firstIndex(where: { $0.tick > tick }) ?? array.count
        let subArray = array[0 ..< uptoIndex]

        let latestPerId: [String: T] = subArray.reduce([:], {
            var dict = $0
            dict[$1.id] = $1
            return dict
        })
        
        return Array(latestPerId.values)
    }
}
