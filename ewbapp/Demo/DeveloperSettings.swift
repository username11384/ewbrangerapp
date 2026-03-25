import Foundation
import CoreLocation
import Combine

/// Persisted developer overrides. Demo branch only.
final class DeveloperSettings: ObservableObject {
    static let shared = DeveloperSettings()

    @Published var spoofLocationEnabled: Bool {
        didSet { UserDefaults.standard.set(spoofLocationEnabled, forKey: "dev_spoofLocation") }
    }
    @Published var spoofedPresetName: String {
        didSet { UserDefaults.standard.set(spoofedPresetName, forKey: "dev_spoofPreset") }
    }

    private init() {
        spoofLocationEnabled = UserDefaults.standard.bool(forKey: "dev_spoofLocation")
        spoofedPresetName    = UserDefaults.standard.string(forKey: "dev_spoofPreset") ?? LocationPreset.all.first!.name
    }

    var spoofedCoordinate: CLLocationCoordinate2D? {
        guard spoofLocationEnabled else { return nil }
        return LocationPreset.all.first { $0.name == spoofedPresetName }?.coordinate
    }
}

// MARK: - Presets

struct LocationPreset: Identifiable {
    let name: String
    let coordinate: CLLocationCoordinate2D
    var id: String { name }

    static let all: [LocationPreset] = [
        // Zone centroids
        LocationPreset(name: "North Creek Gully",   coordinate: .init(latitude: -14.685,  longitude: 143.712)),
        LocationPreset(name: "Boundary Road East",  coordinate: .init(latitude: -14.718,  longitude: 143.698)),
        LocationPreset(name: "Homestead Track",     coordinate: .init(latitude: -14.703,  longitude: 143.722)),
        LocationPreset(name: "Rocky Point Scrub",   coordinate: .init(latitude: -14.695,  longitude: 143.683)),
        LocationPreset(name: "Mangrove Flat",       coordinate: .init(latitude: -14.725,  longitude: 143.715)),
        LocationPreset(name: "Station Dam",         coordinate: .init(latitude: -14.710,  longitude: 143.730)),
        // Patrol area centroids
        LocationPreset(name: "North Beach Dunes",         coordinate: .init(latitude: -14.677,  longitude: 143.702)),
        LocationPreset(name: "River Mouth Flats",         coordinate: .init(latitude: -14.711,  longitude: 143.722)),
        LocationPreset(name: "Camping Ground Perimeter",  coordinate: .init(latitude: -14.700,  longitude: 143.699)),
        LocationPreset(name: "Airstrip Corridor",         coordinate: .init(latitude: -14.720,  longitude: 143.690)),
        LocationPreset(name: "Creek Line East",           coordinate: .init(latitude: -14.708,  longitude: 143.730)),
        LocationPreset(name: "Central Clearing",          coordinate: .init(latitude: -14.710,  longitude: 143.700)),
    ]
}
