import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var recentRainFlagged: Bool
    @Published var isOnline = false
    @Published var pendingSyncCount = 0
    @Published var lastSyncDate: Date?
    @Published var tileStatus: OfflineTileManager.TileStatus

    private let authManager: AuthManager
    private let syncEngine: SyncEngine
    private let tileManager: OfflineTileManager

    init(authManager: AuthManager, syncEngine: SyncEngine) {
        self.authManager = authManager
        self.syncEngine = syncEngine
        self.tileManager = OfflineTileManager.shared
        self.recentRainFlagged = UserDefaults.standard.bool(forKey: SeasonalAlertConfig.recentRainKey)
        self.tileStatus = OfflineTileManager.shared.tileStatus
        Task { await refreshSyncStatus() }
    }

    func toggleRecentRain() {
        recentRainFlagged.toggle()
        UserDefaults.standard.set(recentRainFlagged, forKey: SeasonalAlertConfig.recentRainKey)
    }

    func syncNow() {
        Task {
            await syncEngine.triggerSync()
            await refreshSyncStatus()
        }
    }

    func logout() {
        authManager.logout()
    }

    private func refreshSyncStatus() async {
        pendingSyncCount = await syncEngine.pendingSyncCount
        lastSyncDate = await syncEngine.lastSyncDate
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
