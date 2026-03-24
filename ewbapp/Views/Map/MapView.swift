import SwiftUI
import MapKit

// Subclass so we can carry zone status through the overlay pipeline
final class ZoneCircleOverlay: MKCircle {
    var zoneStatus: String = "active"
    var zoneID: UUID?
}

final class ZonePolygonOverlay: MKPolygon {
    var zoneStatus: String = "active"
}

struct MapView: UIViewRepresentable {
    var mapType: MKMapType
    var annotations: [SightingAnnotation]
    var patrolAnnotations: [PatrolAnnotation]
    var zones: [InfestationZone]
    var showZones: Bool
    var tileOverlay: LocalTileOverlay?
    var onSelectSighting: (SightingLog) -> Void
    // Draw mode
    var drawVertices: [CLLocationCoordinate2D] = []
    var onMapTapped: ((CLLocationCoordinate2D) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectSighting: onSelectSighting, onMapTapped: onMapTapped)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        let centre = CLLocationCoordinate2D(latitude: -14.7, longitude: 143.7)
        mapView.setRegion(MKCoordinateRegion(center: centre, latitudinalMeters: 50000, longitudinalMeters: 50000), animated: false)
        mapView.showsUserLocation = true
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        mapView.addGestureRecognizer(tap)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.onMapTapped = onMapTapped
        mapView.mapType = mapType

        // Tile overlay
        mapView.overlays.filter { $0 is MKTileOverlay }.forEach { mapView.removeOverlay($0) }
        if let overlay = tileOverlay {
            mapView.insertOverlay(overlay, at: 0)
        }

        // Zone overlays (circles for zones without polygons, polygons for those with snapshots)
        mapView.overlays.filter { $0 is ZoneCircleOverlay || $0 is ZonePolygonOverlay }.forEach { mapView.removeOverlay($0) }
        if showZones {
            for zone in zones {
                let status = zone.status ?? "active"
                // If zone has a snapshot with polygon coordinates, draw that
                if let snapshots = zone.snapshots as? [InfestationZoneSnapshot],
                   let latest = snapshots.sorted(by: { ($0.snapshotDate ?? .distantPast) > ($1.snapshotDate ?? .distantPast) }).first,
                   let coords = latest.polygonCoordinates as? [[Double]], coords.count >= 3 {
                    var mkCoords = coords.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
                    let polygon = ZonePolygonOverlay(coordinates: &mkCoords, count: mkCoords.count)
                    polygon.zoneStatus = status
                    mapView.addOverlay(polygon, level: .aboveRoads)
                } else if let sightingsSet = zone.sightings as? Set<SightingLog>, !sightingsSet.isEmpty {
                    // Fall back to centroid circle from linked sightings
                    let coords = sightingsSet.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                    let centroidLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
                    let centroidLon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
                    let centroid = CLLocationCoordinate2D(latitude: centroidLat, longitude: centroidLon)
                    let distances = coords.map { coord -> Double in
                        let a = CLLocation(latitude: centroidLat, longitude: centroidLon)
                        let b = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                        return a.distance(from: b)
                    }
                    let radius = max((distances.max() ?? 0) + 50, 100)
                    let circle = ZoneCircleOverlay(center: centroid, radius: radius)
                    circle.zoneStatus = status
                    circle.zoneID = zone.id
                    mapView.addOverlay(circle, level: .aboveRoads)
                }
            }
        }

        // Draw mode preview
        mapView.overlays.filter { ($0 as? MKPolyline)?.title == "__drawPreview__" }.forEach { mapView.removeOverlay($0) }
        mapView.annotations.filter { ($0 as? MKPointAnnotation)?.title == "__vertex__" }.forEach { mapView.removeAnnotation($0) }
        if drawVertices.count >= 2 {
            var verts = drawVertices
            let preview = MKPolyline(coordinates: &verts, count: verts.count)
            preview.title = "__drawPreview__"
            mapView.addOverlay(preview, level: .aboveLabels)
        }
        for (i, vertex) in drawVertices.enumerated() {
            let pin = MKPointAnnotation()
            pin.coordinate = vertex
            pin.title = "__vertex__"
            pin.subtitle = "\(i + 1)"
            mapView.addAnnotation(pin)
        }

        // Sighting annotations
        let existing = Set(mapView.annotations.compactMap { $0 as? SightingAnnotation }.map { $0.sighting.id })
        let incoming = Set(annotations.map { $0.sighting.id })
        mapView.removeAnnotations(mapView.annotations.compactMap { $0 as? SightingAnnotation }.filter { !incoming.contains($0.sighting.id) })
        mapView.addAnnotations(annotations.filter { !existing.contains($0.sighting.id) })

        // Patrol annotations
        mapView.removeAnnotations(mapView.annotations.compactMap { $0 as? PatrolAnnotation })
        mapView.addAnnotations(patrolAnnotations)
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        let onSelectSighting: (SightingLog) -> Void
        var onMapTapped: ((CLLocationCoordinate2D) -> Void)?

        init(onSelectSighting: @escaping (SightingLog) -> Void, onMapTapped: ((CLLocationCoordinate2D) -> Void)?) {
            self.onSelectSighting = onSelectSighting
            self.onMapTapped = onMapTapped
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView = recognizer.view as? MKMapView,
                  let handler = onMapTapped else { return }
            let point = recognizer.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            handler(coord)
        }

        // Allow tap gesture alongside map's built-in gestures
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let sightingAnnotation = annotation as? SightingAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "sighting") as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "sighting")
                view.annotation = annotation
                let variant = LantanaVariant(rawValue: sightingAnnotation.sighting.variant ?? "") ?? .unknown
                view.markerTintColor = UIColor(variant.color)
                view.canShowCallout = true
                return view
            }
            if let patrolAnnotation = annotation as? PatrolAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "patrol") as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "patrol")
                view.annotation = patrolAnnotation
                view.markerTintColor = patrolAnnotation.patrol.endTime == nil ? .systemBlue : .systemPurple
                view.glyphImage = UIImage(systemName: "figure.walk")
                view.canShowCallout = true
                return view
            }
            if let vertex = annotation as? MKPointAnnotation, vertex.title == "__vertex__" {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "vertex")
                view.markerTintColor = .systemYellow
                view.glyphText = vertex.subtitle
                view.canShowCallout = false
                return view
            }
            return nil
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
                applyZoneStyle(to: renderer, status: zoneCircle.zoneStatus)
                return renderer
            }
            if let zonePolygon = overlay as? ZonePolygonOverlay {
                let renderer = MKPolygonRenderer(polygon: zonePolygon)
                applyZoneStyle(to: renderer, status: zonePolygon.zoneStatus)
                return renderer
            }
            if let polyline = overlay as? MKPolyline, polyline.title == "__drawPreview__" {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemYellow
                renderer.lineWidth = 2
                renderer.lineDashPattern = [6, 4]
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        private func applyZoneStyle(to renderer: MKOverlayPathRenderer, status: String) {
            switch status {
            case "underTreatment":
                renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.25)
                renderer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.8)
            case "cleared":
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.8)
            default:
                renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.25)
                renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.8)
            }
            renderer.lineWidth = 2
        }
    }
}
