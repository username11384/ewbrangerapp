import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var accuracyLevel: AccuracyLevel = .unknown

    enum AccuracyLevel {
        case good       // < 10m
        case fair       // 10–50m
        case poor       // > 50m
        case unknown

        var color: String {
            switch self {
            case .good: return "green"
            case .fair: return "yellow"
            case .poor: return "red"
            case .unknown: return "gray"
            }
        }
    }

    private let locationManager = CLLocationManager()
    private var isSingleCapture = false
    var singleCaptureCompletion: ((CLLocation?) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    /// Captures a single high-accuracy location, then stops.
    /// Falls back to Port Stewart default after 8 seconds (handles simulator + poor signal).
    func captureLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            isSingleCapture = true
            var resumed = false
            singleCaptureCompletion = { location in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: location)
            }
            locationManager.startUpdatingLocation()
            // Timeout fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                guard let self, !resumed else { return }
                resumed = true
                self.isSingleCapture = false
                // Default: Port Stewart, Cape York
                let fallback = CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: -14.7019, longitude: 143.7075),
                    altitude: 5, horizontalAccuracy: 50, verticalAccuracy: 10, timestamp: Date()
                )
                self.currentLocation = fallback
                self.accuracyLevel = .fair
                continuation.resume(returning: fallback)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            let acc = location.horizontalAccuracy
            if acc < 10 { self.accuracyLevel = .good }
            else if acc < 50 { self.accuracyLevel = .fair }
            else { self.accuracyLevel = .poor }

            if self.isSingleCapture && acc < 30 {
                self.isSingleCapture = false
                manager.stopUpdatingLocation()
                self.singleCaptureCompletion?(location)
                self.singleCaptureCompletion = nil
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}
