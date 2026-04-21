import MapKit
import SwiftUI

class SightingAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let sighting: SightingLog
    var title: String? { InvasiveSpecies.from(legacyVariant: sighting.variant ?? "").displayName }
    var subtitle: String? { InfestationSize(rawValue: sighting.infestationSize ?? "")?.displayName }

    init(sighting: SightingLog) {
        self.coordinate = CLLocationCoordinate2D(latitude: sighting.latitude, longitude: sighting.longitude)
        self.sighting = sighting
    }
}
