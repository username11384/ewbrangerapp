import MapKit

final class PatrolAnnotation: NSObject, MKAnnotation {
    let patrol: PatrolRecord
    var coordinate: CLLocationCoordinate2D

    var title: String? { patrol.areaName }
    var subtitle: String? {
        guard let start = patrol.startTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        if patrol.endTime != nil {
            return "Completed \(formatter.string(from: start))"
        } else {
            return "Active since \(formatter.string(from: start))"
        }
    }

    init(patrol: PatrolRecord, coordinate: CLLocationCoordinate2D) {
        self.patrol = patrol
        self.coordinate = coordinate
    }
}
