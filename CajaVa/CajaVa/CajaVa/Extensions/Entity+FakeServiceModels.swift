import FakeService

extension Entity {
    init(package: Package) {
        let subtitle: String
        if package.delivered {
            subtitle = "Delivered"
        } else if package.courierId != nil {
            subtitle = "In Transit"
        } else {
            subtitle = "Pending"
        }
        
        self.init(title: package.id,subtitle: subtitle)
    }
    
    init(courier: Courier) {
        let subtitle: String
        if courier.idle {
            subtitle = "Idle"
        } else {
            switch (courier.packageId, courier.vehicleId) {
            case (.some, .some):
                subtitle = "Delivering - Vehicle"
            case (.some, .none):
                subtitle = "Delivering - Foot"
            case (.none, .some):
                subtitle = "Returning - Vehicle"
            case (.none, .none):
                subtitle = "Returning - Foot"
            }
        }
        
        self.init(title: courier.name, subtitle: subtitle)
    }
    
    init(vehicle: Vehicle) {
        self.init(title: vehicle.name, subtitle: vehicle.courierId != nil ? "In use" : "Idle")
    }
}
