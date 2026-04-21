import Combine
import Foundation
import CoreData
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var totalSightings: Int = 0
    @Published var sightingsThisMonth: Int = 0
    @Published var treatmentsThisMonth: Int = 0
    @Published var zoneStatusCounts: [String: Int] = [:]
    @Published var monthlySightingData: [(date: Date, count: Int, variant: String)] = []
    @Published var pendingSyncCount: Int = 0
    @Published var lastSyncDate: Date?
    @Published var rangerSightingCounts: [(name: String, count: Int)] = []
    @Published var clearedZonePercent: Double = 0
    @Published var openFollowUpTasks: Int = 0

    private let persistence: PersistenceController
    private let syncEngine: SyncEngine

    init(persistence: PersistenceController, syncEngine: SyncEngine) {
        self.persistence = persistence
        self.syncEngine = syncEngine
        load()
    }

    func load() {
        let context = persistence.mainContext
        let now = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now

        totalSightings = (try? context.fetchAll(SightingLog.self))?.count ?? 0

        sightingsThisMonth = (try? context.fetchAll(
            SightingLog.self,
            predicate: NSPredicate(format: "createdAt >= %@", startOfMonth as CVarArg)
        ))?.count ?? 0

        treatmentsThisMonth = (try? context.fetchAll(
            TreatmentRecord.self,
            predicate: NSPredicate(format: "treatmentDate >= %@", startOfMonth as CVarArg)
        ))?.count ?? 0

        let zones = (try? context.fetchAll(InfestationZone.self)) ?? []
        zoneStatusCounts = Dictionary(grouping: zones, by: { $0.status ?? "unknown" })
            .mapValues { $0.count }

        buildMonthlySightingData(context: context, now: now)

        pendingSyncCount = (try? context.fetchAll(SyncQueue.self))?.count ?? 0
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncTimestamp") as? Date

        // Per-ranger sighting counts
        let allSightings = (try? context.fetchAll(SightingLog.self)) ?? []
        let byRanger = Dictionary(grouping: allSightings, by: { $0.ranger?.displayName ?? "Unknown" })
        rangerSightingCounts = byRanger.map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        // Zone cleared %
        let allZones = (try? context.fetchAll(InfestationZone.self)) ?? []
        let cleared = allZones.filter { $0.status == "cleared" }.count
        clearedZonePercent = allZones.isEmpty ? 0 : Double(cleared) / Double(allZones.count) * 100

        // Open follow-up tasks
        openFollowUpTasks = (try? context.fetchAll(
            RangerTask.self,
            predicate: NSPredicate(format: "isComplete == NO AND sourceTreatment != nil")
        ))?.count ?? 0
    }

    private func buildMonthlySightingData(context: NSManagedObjectContext, now: Date) {
        var data: [(date: Date, count: Int, variant: String)] = []
        let calendar = Calendar.current
        for monthOffset in (0..<6).reversed() {
            guard let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: thisMonth) else { continue }
            guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", monthStart as CVarArg, monthEnd as CVarArg)
            let monthSightings = (try? context.fetchAll(SightingLog.self, predicate: predicate)) ?? []
            let byVariant = Dictionary(grouping: monthSightings, by: { $0.variant ?? "unknown" })
            for (variant, sightings) in byVariant {
                let label = InvasiveSpecies.from(legacyVariant: variant).displayName
                data.append((date: monthStart, count: sightings.count, variant: label))
            }
        }
        monthlySightingData = data
    }
}
