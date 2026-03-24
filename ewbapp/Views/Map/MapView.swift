import SwiftUI
import MapKit

// Subclass so we can carry zone status through the overlay pipeline
final class ZoneCircleOverlay: MKCircle {
    var zoneStatus: String = "active"
    var zoneID: UUID?
}

struct MapView: UIViewRepresentable {
    var mapType: MKMapType
    var annotations: [SightingAnnotation]
    var zones: [InfestationZone]
    var showZones: Bool
    var tileOverlay: LocalTileOverlay?
    var onSelectSighting: (SightingLog) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSelectSighting: onSelectSighting) }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        // Port Stewart centre
        let centre = CLLocationCoordinate2D(latitude: -14.7, longitude: 143.7)
        mapView.setRegion(MKCoordinateRegion(center: centre, latitudinalMeters: 50000, longitudinalMeters: 50000), animated: false)
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType

        // Update tile overlay
        mapView.overlays.filter { $0 is MKTileOverlay }.forEach { mapView.removeOverlay($0) }
        if let overlay = tileOverlay {
            mapView.insertOverlay(overlay, at: 0)
        }

        // Update zone overlays
        mapView.overlays.filter { $0 is ZoneCircleOverlay }.forEach { mapView.removeOverlay($0) }
        if showZones {
            for zone in zones {
                guard let sightingsSet = zone.sightings as? Set<SightingLog>, !sightingsSet.isEmpty else { continue }
                let coords = sightingsSet.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                let centroidLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
                let centroidLon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
                let centroid = CLLocationCoordinate2D(latitude: centroidLat, longitude: centroidLon)
                // Radius: encompass all sightings + 50m buffer
                let distances = coords.map { coord -> Double in
                    let a = CLLocation(latitude: centroidLat, longitude: centroidLon)
                    let b = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                    return a.distance(from: b)
                }
                let radius = max((distances.max() ?? 0) + 50, 100)
                let circle = ZoneCircleOverlay(center: centroid, radius: radius)
                circle.zoneStatus = zone.status ?? "active"
                circle.zoneID = zone.id
                mapView.addOverlay(circle, level: .aboveRoads)
            }
        }

        // Update annotations
        let existing = Set(mapView.annotations.compactMap { $0 as? SightingAnnotation }.map { $0.sighting.id })
        let incoming = Set(annotations.map { $0.sighting.id })
        let toRemove = mapView.annotations.compactMap { $0 as? SightingAnnotation }.filter { !incoming.contains($0.sighting.id) }
        let toAdd = annotations.filter { !existing.contains($0.sighting.id) }
        mapView.removeAnnotations(toRemove)
        mapView.addAnnotations(toAdd)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let onSelectSighting: (SightingLog) -> Void
        init(onSelectSighting: @escaping (SightingLog) -> Void) {
            self.onSelectSighting = onSelectSighting
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let sightingAnnotation = annotation as? SightingAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "sighting") as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "sighting")
            view.annotation = annotation
            let variant = LantanaVariant(rawValue: sightingAnnotation.sighting.variant ?? "") ?? .unknown
            view.markerTintColor = UIColor(variant.color)
            view.canShowCallout = true
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let sa = view.annotation as? SightingAnnotation else { return }
            onSelectSighting(sa.sighting)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tile)
            }
            if let zoneCircle = overlay as? ZoneCircleOverlay {
                let renderer = MKCircleRenderer(circle: zoneCircle)
                switch zoneCircle.zoneStatus {
                case "underTreatment":
                    renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.8)
                case "cleared":
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.8)
                default: // active
                    renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.8)
                }
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
