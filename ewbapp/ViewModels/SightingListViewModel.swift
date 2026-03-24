import Combine
import Foundation
import CoreData
import CoreLocation

@MainActor
final class SightingListViewModel: ObservableObject {
    @Published var sightings: [SightingLog] = []
    @Published var searchText: String = ""
    @Published var filterVariant: LantanaVariant?

    private let repository: SightingRepository
    private let locationManager: LocationManager

    init(persistence: PersistenceController, locationManager: LocationManager) {
        self.repository = SightingRepository(persistence: persistence)
        self.locationManager = locationManager
        load()
    }

    func load() {
        sightings = (try? repository.fetchAllSightings()) ?? []
    }

    func delete(_ sighting: SightingLog) {
        Task {
            try? await repository.deleteSighting(sighting)
            load()
        }
    }

    var filtered: [SightingLog] {
        var result = sightings
        if !searchText.isEmpty {
            result = result.filter {
                $0.variant?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        if let variant = filterVariant {
            result = result.filter { $0.variant == variant.rawValue }
        }
        return result
    }

    func distance(to sighting: SightingLog) -> CLLocationDistance? {
        guard let current = locationManager.currentLocation else { return nil }
        let target = CLLocation(latitude: sighting.latitude, longitude: sighting.longitude)
        return current.distance(from: target)
    }

    func formattedDistance(_ sighting: SightingLog) -> String? {
        guard let d = distance(to: sighting) else { return nil }
        if d < 1000 { return String(format: "%.0fm", d) }
        return String(format: "%.1fkm", d / 1000)
    }
}
