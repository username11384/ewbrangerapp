import Combine
import Foundation
import MultipeerConnectivity

@MainActor
final class MeshSyncViewModel: ObservableObject {
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var peerStatuses: [String: String] = [:]
    @Published var overallStatus: String = "Idle"
    @Published var isSyncing = false
    @Published var lastSyncSummary: String?

    private let meshEngine: MeshSyncEngine
    private let currentRangerName: String

    init(persistence: PersistenceController, currentRangerName: String) {
        self.currentRangerName = currentRangerName
        self.meshEngine = MeshSyncEngine(persistence: persistence, displayName: currentRangerName)
    }

    func startDiscovery() {
        Task {
            await meshEngine.start()
            isSyncing = true
            overallStatus = "Discovering nearby rangers…"
        }
    }

    func stopDiscovery() {
        Task {
            await meshEngine.stop()
            isSyncing = false
            overallStatus = "Idle"
        }
    }
}
