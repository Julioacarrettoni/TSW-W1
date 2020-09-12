















// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// HERE BE DRAGONS!
// The code is ugly and dangerous please don't use it in production
// You should consider reading the other files instead
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=




































// Don't say I didn't warn ya!
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

import Foundation
import MapKit
import FakeService

final class MapViewDelegate: NSObject, MKMapViewDelegate {
    var mapView: MKMapView
    
    init(mapView: MKMapView) {
        self.mapView = mapView
        super.init()
        self.mapView.delegate = self
    }
    
    var annotations: [TrackerPointAnnotation] = [] {
        didSet {
            refreshAnnotations(annotations)
        }
    }
    
    func refreshAnnotations(_ updatedAnnotations: [TrackerPointAnnotation]) {
        let mapView = self.mapView
        let currentAnnotations = mapView.annotations.compactMap{ $0 as? TrackerPointAnnotation }
        let newAnnotations = updatedAnnotations.filter { annotation in !currentAnnotations.contains(where: { $0.kind == annotation.kind }) }
        let existingAnnotations = updatedAnnotations.filter { annotation in currentAnnotations.contains(where: { $0.kind == annotation.kind })}
        let oldAnnotations = currentAnnotations.filter { annotation in !updatedAnnotations.contains(where: { $0.kind == annotation.kind })}
        
        mapView.removeAnnotations(oldAnnotations)
        mapView.addAnnotations(newAnnotations)
        
        UIView.animate(withDuration: 1.0) {
            for annotation in existingAnnotations {
                if let existingAnnotation = currentAnnotations.first(where: { $0.kind == annotation.kind }) {
                    if existingAnnotation.kind.imageRequiresRefresh(comparedTo: annotation.kind) {
                        if let annotationView = mapView.view(for: existingAnnotation),
                           let image = annotation.kind.icon {
                            annotationView.image = image
                            annotationView.centerOffset = image.annotationImageOffset
                        }
                    }
                    existingAnnotation.kind = annotation.kind
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let trackerAnnotation = annotation as? TrackerPointAnnotation else {
            fatalError()
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: trackerAnnotation.kind.identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: trackerAnnotation.kind.identifier)
            annotationView?.canShowCallout = true
            annotationView?.calloutOffset = .zero
            annotationView?.clusteringIdentifier = nil
        } else {
            annotationView?.annotation = annotation
        }
        let image = trackerAnnotation.kind.icon
        annotationView?.image = image
        annotationView?.centerOffset = image?.annotationImageOffset ?? .zero
        
        return annotationView
    }
}

final class TrackerPointAnnotation: MKPointAnnotation {
    enum Kind: Equatable {
        case courier(Courier)
        case central(Location)
        case destination(Location)
        
        var title: String {
            switch self {
            case .courier(let courier):
                return courier.name
            case .central:
                return "Central"
            case .destination:
                return "Client"
            }
        }
        
        var locationCoordinate: CLLocationCoordinate2D {
            switch self {
            case .courier(let courier):
                return CLLocationCoordinate2D(latitude: courier.location.lat, longitude: courier.location.lng)
            case .central(let location), .destination(let location):
                return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
            }
        }
        
        var icon: UIImage? {
            return UIImage(systemName: self.imageName)?
                .tinted(with: self.imageTint)
        }
        
        private var imageName: String {
            switch self {
            case .courier(let courier) where courier.vehicleId != nil:
                return "car.fill"
            case .courier:
                return "person.crop.circle.fill"
            case .central:
                return "square.and.arrow.up"
            case .destination:
                return "square.and.arrow.down"
            }
        }
        
        private var imageTint: UIColor {
            switch self {
            case .courier(let courier) where courier.packageId != nil:
                return .label
            case .courier:
                return .systemGray2
            case .central:
                return .systemBlue
            case .destination:
                return .label
            }
        }
        
        var identifier: String { "Marker" }
        
        static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case (.courier(let lhsCourier), .courier(let rhsCourier)):
                return lhsCourier.id == rhsCourier.id
            case (.central, .central):
                return true
            case (.destination(let lhsDestination), .destination(let rhsDestination)):
                return lhsDestination == rhsDestination
            case (_, _):
                return false
            }
        }
        
        func imageRequiresRefresh(comparedTo other: Kind) -> Bool {
            return self.imageTint != other.imageTint
                || self.imageName != other.imageName
        }
    }
    
    var kind: Kind {
        didSet {
            self.title = kind.title
            self.coordinate = kind.locationCoordinate
        }
    }
    
    init(kind: Kind) {
        self.kind = kind
        super.init()
        self.title = kind.title
        self.coordinate = kind.locationCoordinate
    }
}

extension UIImage {
    var annotationImageOffset: CGPoint {
        .zero
    }
    
    func tinted(with color: UIColor) -> UIImage? {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.set()
        self.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// Are you happy now?
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
