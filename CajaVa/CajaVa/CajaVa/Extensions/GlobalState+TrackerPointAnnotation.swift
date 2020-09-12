import FakeService

extension GlobalState {
    func makeAnnotations() -> [TrackerPointAnnotation] {
        let central = TrackerPointAnnotation(kind: .central(self.central))
        let couriers = self.couriers.filter{ !$0.idle }.map { TrackerPointAnnotation(kind: .courier($0)) }
        let destinations = self.packages.filter{ !$0.delivered }.map { TrackerPointAnnotation(kind: .destination($0.destination)) }
        
        return [central] + couriers + destinations
    }
}
