import Foundation
import Network
import CoreData

actor SyncEngine {
    private let persistence: PersistenceController
    private let syncQueueManager: SyncQueueManager
    private let photoUploadManager: PhotoUploadManager

    private var pathMonitor: NWPathMonitor?
    private var isOnline = false
    private var isSyncing = false

    private let lastSyncKey = "lastSyncTimestamp"

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.syncQueueManager = SyncQueueManager(persistence: persistence)
        self.photoUploadManager = PhotoUploadManager(persistence: persistence)
    }

    // MARK: - Network monitoring

    func startMonitoring() {
        let monitor = NWPathMonitor()
        self.pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.handlePathChange(path.status == .satisfied)
            }
        }
        monitor.start(queue: DispatchQueue(label: "SyncEngine.NWPathMonitor"))
    }

    private func handlePathChange(_ online: Bool) async {
        let wasOffline = !isOnline
        isOnline = online
        if online && wasOffline {
            await triggerSync()
        }
    }

    // MARK: - Sync trigger

    /// PoC: cloud sync is stubbed out — no Supabase backend required.
    /// All data lives locally in CoreData. Mesh sync (MultipeerConnectivity) handles
    /// device-to-device sync without any internet or paid services.
    func triggerSync() async {
        print("[SyncEngine] Cloud sync disabled for PoC — data is local only.")
    }

    // MARK: - Status

    var pendingSyncCount: Int {
        (try? persistence.mainContext.fetchAll(SyncQueue.self))?.count ?? 0
    }

    var lastSyncDate: Date? {
        UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }
}
