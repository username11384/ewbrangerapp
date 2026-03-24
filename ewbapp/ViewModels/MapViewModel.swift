import Foundation
import MapKit
import CoreData
import Combine

@MainActor
final class MapViewModel: ObservableObject {
    @Published var sightings: [SightingLog] = []
    @Published var zones: [InfestationZone] = []
    @Published var mapType: MKMapType = .satellite
    @Published var showSightings = true
    @Published var showZones = true
    @Published var showPatrols = false
    @Published var timelineDate: Date = Date()
    @Published var isPlayingTimeline = false

    private let sightingRepository: SightingRepository
    private let zoneRepository: ZoneRepository
    private var timelineTimer: Timer?

    init(persistence: PersistenceController) {
        self.sightingRepository = SightingRepository(persistence: persistence)
        self.zoneRepository = ZoneRepository(persistence: persistence)
        load()
    }

    func load() {
        sightings = (try? sightingRepository.fetchAllSightings()) ?? []
        zones = (try? zoneRepository.fetchAllZones()) ?? []
    }

    var filteredSightings: [SightingLog] {
        guard showSightings else { return [] }
        return sightings.filter { ($0.createdAt ?? Date()) <= timelineDate }
    }

    func toggleTimeline() {
        if isPlayingTimeline {
            timelineTimer?.invalidate()
            isPlayingTimeline = false
        } else {
            isPlayingTimeline = true
            timelineDate = sightings.compactMap { $0.createdAt }.min() ?? Date()
            timelineTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let newDate = Calendar.current.date(byAdding: .month, value: 1, to: self.timelineDate) ?? Date()
                    if newDate > Date() {
                        self.isPlayingTimeline = false
                        self.timelineTimer?.invalidate()
                    } else {
                        self.timelineDate = newDate
                    }
                }
            }
        }
    }

    var dateRange: ClosedRange<Date> {
        let earliest = sightings.compactMap { $0.createdAt }.min() ?? Date()
        return earliest...Date()
    }
}
