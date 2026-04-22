import Combine
import CoreData
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var recentRainFlagged: Bool
    @Published var isOnline = false
    @Published var pendingSyncCount = 0
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var tileStatus: OfflineTileManager.TileStatus
    @Published var currentRangerName: String = ""
    @Published var pinChangeError: String? = nil
    @Published var pinChangeSuccess = false

    private let authManager: AuthManager
    private let syncEngine: SyncEngine
    private let tileManager: OfflineTileManager
    private let persistence: PersistenceController

    init(authManager: AuthManager, syncEngine: SyncEngine, persistence: PersistenceController) {
        self.authManager = authManager
        self.syncEngine = syncEngine
        self.tileManager = OfflineTileManager.shared
        self.persistence = persistence
        self.recentRainFlagged = UserDefaults.standard.bool(forKey: SeasonalAlertConfig.recentRainKey)
        self.tileStatus = OfflineTileManager.shared.tileStatus
        refreshSyncStatus()
        loadProfile()
    }

    func loadProfile() {
        guard let rangerID = authManager.currentRangerID else { return }
        let ctx = persistence.mainContext
        let pred = NSPredicate(format: "id == %@", rangerID as CVarArg)
        if let ranger = try? ctx.fetchFirst(RangerProfile.self, predicate: pred) {
            currentRangerName = ranger.displayName ?? ""
        }
    }

    func updateDisplayName(_ name: String) {
        guard let rangerID = authManager.currentRangerID, !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let ctx = persistence.backgroundContext
        Task {
            await ctx.perform {
                let pred = NSPredicate(format: "id == %@", rangerID as CVarArg)
                if let ranger = try? ctx.fetchFirst(RangerProfile.self, predicate: pred) {
                    ranger.displayName = name.trimmingCharacters(in: .whitespaces)
                    ranger.updatedAt = Date()
                    try? ctx.save()
                }
            }
            await MainActor.run {
                currentRangerName = name.trimmingCharacters(in: .whitespaces)
            }
        }
    }

    func changePIN(oldPIN: String, newPIN: String, confirmPIN: String) {
        pinChangeError = nil
        pinChangeSuccess = false
        guard newPIN == confirmPIN else {
            pinChangeError = "New PINs don't match."
            return
        }
        guard newPIN.count >= 4 else {
            pinChangeError = "PIN must be at least 4 digits."
            return
        }
        guard authManager.changePIN(oldPIN: oldPIN, newPIN: newPIN) else {
            pinChangeError = "Current PIN is incorrect."
            return
        }
        pinChangeSuccess = true
    }

    func toggleRecentRain() {
        recentRainFlagged.toggle()
        UserDefaults.standard.set(recentRainFlagged, forKey: SeasonalAlertConfig.recentRainKey)
    }

    func syncNow() {
        guard !isSyncing else { return }
        isSyncing = true
        Task {
            // Fake a realistic 2–3 s sync round-trip for the demo
            try? await Task.sleep(for: .seconds(Double.random(in: 2.0...3.2)))
            UserDefaults.standard.set(Date(), forKey: "lastSyncTimestamp")
            refreshSyncStatus()
            isSyncing = false
        }
    }

    func resetDemoData() {
        let ctx = persistence.backgroundContext
        ctx.performAndWait {
            let entities = ["SightingLog", "TreatmentRecord", "RangerTask",
                            "InfestationZone", "InfestationZoneSnapshot",
                            "PatrolRecord", "PesticideStock", "PesticideUsageRecord", "SyncQueue"]
            for name in entities {
                let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let batch = NSBatchDeleteRequest(fetchRequest: req)
                _ = try? ctx.execute(batch)
            }
            try? ctx.save()
        }
        UserDefaults.standard.removeObject(forKey: "demoDataSeeded_v2")
        UserDefaults.standard.removeObject(forKey: "demoDataSeeded_v3")
        UserDefaults.standard.removeObject(forKey: "lastSyncTimestamp")
        DemoSeeder.seed(in: persistence)
    }

    func logout() {
        authManager.logout()
    }

    private func refreshSyncStatus() {
        pendingSyncCount = (try? persistence.mainContext.fetchAll(SyncQueue.self))?.count ?? 0
        lastSyncDate = syncEngine.lastSyncDate
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
