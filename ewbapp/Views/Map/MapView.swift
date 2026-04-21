import SwiftUI
import MapKit

final class ZoneCircleOverlay: MKCircle {
    var zoneStatus: String = "active"
    var zoneID: UUID?
}

final class ZonePolygonOverlay: MKPolygon {
    var zoneStatus: String = "active"
    var zoneID: UUID?
}

final class DrawPreviewPolyline: MKPolyline {}

final class VertexAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    init(index: Int, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.title = "\(index + 1)"
    }
}

struct MapView: UIViewRepresentable {
    var mapType: MKMapType
    var annotations: [SightingAnnotation]
    var patrolAnnotations: [PatrolAnnotation]
    var zones: [InfestationZone]
    var showZones: Bool
    var tileOverlay: LocalTileOverlay?
    // Callbacks carry the screen-space anchor point so the caller can position a popover
    var onSelectSighting: (SightingLog, CGPoint) -> Void
    var onSelectPatrol: ((PatrolRecord, CGPoint) -> Void)? = nil
    var onSelectZone: ((InfestationZone, CGPoint) -> Void)? = nil
    var drawVertices: [CLLocationCoordinate2D] = []
    var onMapTapped: ((CLLocationCoordinate2D) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSelectSighting: onSelectSighting,
            onSelectPatrol: onSelectPatrol,
            onSelectZone: onSelectZone,
            onMapTapped: onMapTapped
        )
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
        context.coordinator.onSelectPatrol = onSelectPatrol
        context.coordinator.onSelectZone = onSelectZone
        context.coordinator.zones = zones
        mapView.mapType = mapType

        mapView.overlays.filter { $0 is MKTileOverlay }.forEach { mapView.removeOverlay($0) }
        if let overlay = tileOverlay { mapView.insertOverlay(overlay, at: 0) }

        mapView.overlays.filter { $0 is ZoneCircleOverlay || $0 is ZonePolygonOverlay }.forEach { mapView.removeOverlay($0) }
        if showZones {
            for zone in zones {
                let status = zone.status ?? "active"
                if let snapshots = zone.snapshots?.array as? [InfestationZoneSnapshot],
                   let latest = snapshots.sorted(by: { ($0.snapshotDate ?? .distantPast) > ($1.snapshotDate ?? .distantPast) }).first,
                   let coords = latest.polygonCoordinates as? [[Double]], coords.count >= 3 {
                    var mkCoords = coords.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
                    let polygon = ZonePolygonOverlay(coordinates: &mkCoords, count: mkCoords.count)
                    polygon.zoneStatus = status
                    polygon.zoneID = zone.id
                    mapView.addOverlay(polygon, level: .aboveRoads)
                } else if let sightingsSet = zone.sightings as? Set<SightingLog>, !sightingsSet.isEmpty {
                    let coords = sightingsSet.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                    let centroidLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
                    let centroidLon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
                    let centroid = CLLocationCoordinate2D(latitude: centroidLat, longitude: centroidLon)
                    let distances = coords.map { CLLocation(latitude: centroidLat, longitude: centroidLon).distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) }
                    let radius = max((distances.max() ?? 0) + 50, 100)
                    let circle = ZoneCircleOverlay(center: centroid, radius: radius)
                    circle.zoneStatus = status
                    circle.zoneID = zone.id
                    mapView.addOverlay(circle, level: .aboveRoads)
                }
            }
        }

        mapView.overlays.filter { $0 is DrawPreviewPolyline }.forEach { mapView.removeOverlay($0) }
        mapView.removeAnnotations(mapView.annotations.compactMap { $0 as? VertexAnnotation })
        if drawVertices.count >= 2 {
            var verts = drawVertices
            let preview = DrawPreviewPolyline(coordinates: &verts, count: verts.count)
            mapView.addOverlay(preview, level: .aboveLabels)
        }
        for (i, vertex) in drawVertices.enumerated() {
            mapView.addAnnotation(VertexAnnotation(index: i, coordinate: vertex))
        }

        let existing = Set(mapView.annotations.compactMap { $0 as? SightingAnnotation }.map { $0.sighting.id })
        let incoming = Set(annotations.map { $0.sighting.id })
        mapView.removeAnnotations(mapView.annotations.compactMap { $0 as? SightingAnnotation }.filter { !incoming.contains($0.sighting.id) })
        mapView.addAnnotations(annotations.filter { !existing.contains($0.sighting.id) })

        mapView.removeAnnotations(mapView.annotations.compactMap { $0 as? PatrolAnnotation })
        mapView.addAnnotations(patrolAnnotations)
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        let onSelectSighting: (SightingLog, CGPoint) -> Void
        var onSelectPatrol: ((PatrolRecord, CGPoint) -> Void)?
        var onSelectZone: ((InfestationZone, CGPoint) -> Void)?
        var onMapTapped: ((CLLocationCoordinate2D) -> Void)?
        var zones: [InfestationZone] = []

        init(onSelectSighting: @escaping (SightingLog, CGPoint) -> Void,
             onSelectPatrol: ((PatrolRecord, CGPoint) -> Void)?,
             onSelectZone: ((InfestationZone, CGPoint) -> Void)?,
             onMapTapped: ((CLLocationCoordinate2D) -> Void)?) {
            self.onSelectSighting = onSelectSighting
            self.onSelectPatrol = onSelectPatrol
            self.onSelectZone = onSelectZone
            self.onMapTapped = onMapTapped
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView = recognizer.view as? MKMapView else { return }
            let point = recognizer.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)

            if let handler = onMapTapped {
                handler(coord)
                return
            }

            // Zone overlay hit-test
            let mapPoint = MKMapPoint(coord)
            for overlay in mapView.overlays {
                if let polygon = overlay as? ZonePolygonOverlay,
                   let id = polygon.zoneID,
                   let zone = zones.first(where: { $0.id == id }) {
                    let renderer = MKPolygonRenderer(polygon: polygon)
                    let viewPoint = renderer.point(for: mapPoint)
                    if renderer.path?.contains(viewPoint) == true {
                        onSelectZone?(zone, point)
                        return
                    }
                }
                if let circle = overlay as? ZoneCircleOverlay,
                   let id = circle.zoneID,
                   let zone = zones.first(where: { $0.id == id }) {
                    let center = CLLocation(latitude: circle.coordinate.latitude, longitude: circle.coordinate.longitude)
                    if CLLocation(latitude: coord.latitude, longitude: coord.longitude).distance(from: center) <= circle.radius {
                        onSelectZone?(zone, point)
                        return
                    }
                }
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let sa = annotation as? SightingAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "sighting") as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "sighting")
                view.annotation = annotation
                view.markerTintColor = UIColor(InvasiveSpecies.from(legacyVariant: sa.sighting.variant ?? "").color)
                view.canShowCallout = false
                return view
            }
            if let pa = annotation as? PatrolAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "patrol") as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "patrol")
                view.annotation = pa
                view.markerTintColor = pa.patrol.endTime == nil ? .systemBlue : .systemPurple
                view.glyphImage = UIImage(systemName: "figure.walk")
                view.canShowCallout = false
                return view
            }
            if let va = annotation as? VertexAnnotation {
                let view = MKMarkerAnnotationView(annotation: va, reuseIdentifier: "vertex")
                view.markerTintColor = .systemYellow
                view.glyphText = va.title
                view.canShowCallout = false
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            mapView.deselectAnnotation(view.annotation, animated: false)
            guard let coord = view.annotation?.coordinate else { return }
            // Anchor point = the coordinate's screen position (tip of the pin)
            let tipPoint = mapView.convert(coord, toPointTo: mapView)

            if let sa = view.annotation as? SightingAnnotation {
                onSelectSighting(sa.sighting, tipPoint)
            }
            if let pa = view.annotation as? PatrolAnnotation {
                onSelectPatrol?(pa.patrol, tipPoint)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? MKTileOverlay { return MKTileOverlayRenderer(tileOverlay: tile) }
            if let c = overlay as? ZoneCircleOverlay {
                let r = MKCircleRenderer(circle: c); applyZoneStyle(to: r, status: c.zoneStatus); return r
            }
            if let p = overlay as? ZonePolygonOverlay {
                let r = MKPolygonRenderer(polygon: p); applyZoneStyle(to: r, status: p.zoneStatus); return r
            }
            if let l = overlay as? DrawPreviewPolyline {
                let r = MKPolylineRenderer(polyline: l)
                r.strokeColor = .systemYellow; r.lineWidth = 2; r.lineDashPattern = [6, 4]; return r
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
