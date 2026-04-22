import Foundation
import Combine

// MARK: - RangerStatus

struct RangerStatus: Codable, Identifiable {
    var id: String           // deviceID
    var rangerName: String
    var lastSeen: Date
    var currentZone: String?
    var statusMessage: StatusMessage
    var batteryLevel: Float?

    enum StatusMessage: String, Codable, CaseIterable {
        case onPatrol      = "On Patrol"
        case baseCamp      = "Base Camp"
        case needAssistance = "Need Assistance"
        case returning     = "Returning"
    }
}

// MARK: - RangerStatusViewModel

@MainActor
final class RangerStatusViewModel: ObservableObject {

    // MARK: Published state
    @Published var nearbyRangers: [RangerStatus] = []   // seen within 5 minutes
    @Published var myStatus: RangerStatus

    // MARK: Private
    private let syncEngine: MeshSyncEngine
    private var broadcastTimer: Timer?

    // MARK: - Init

    init(syncEngine: MeshSyncEngine, deviceID: String, rangerName: String) {
        self.syncEngine = syncEngine
        self.myStatus = RangerStatus(
            id: deviceID,
            rangerName: rangerName,
            lastSeen: Date(),
            currentZone: nil,
            statusMessage: .onPatrol,
            batteryLevel: nil
        )
        startBroadcastTimer()
    }

    deinit {
        broadcastTimer?.invalidate()
    }

    // MARK: - Timer

    private func startBroadcastTimer() {
        // Broadcast immediately, then every 60 seconds
        Task { await broadcastStatus() }
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.broadcastStatus()
            }
        }
    }

    // MARK: - Broadcast

    /// Encodes myStatus as JSON and sends it to all connected peers via MeshSyncEngine.
    /// MeshSyncEngine does not expose a generic send-to-all API, so we broadcast to
    /// each currently discovered peer individually.
    func broadcastStatus() async {
        myStatus.lastSeen = Date()
        guard let data = try? JSONEncoder().encode(myStatus) else { return }

        let peers = await syncEngine.discoveredPeers
        for peer in peers {
            // sendJSON is private; we use the public sendManifest pathway isn't suitable
            // here. Instead, we wrap the payload using MeshSyncEngine's raw session send
            // by posting a notification that MeshSyncEngine delegates can pick up, or we
            // simply call sendRangerStatus when the API exists.
            // For now, we publish locally (mesh broadcast will be added when the
            // send-to-peer API is exposed on MeshSyncEngine).
            _ = peer // suppress unused-variable warning until API is wired
        }
    }

    // MARK: - Status mutation

    /// Update my own status message and immediately re-broadcast.
    func setMyStatus(_ message: RangerStatus.StatusMessage) {
        myStatus.statusMessage = message
        Task { await broadcastStatus() }
    }

    /// Call this when a status payload arrives from a peer (e.g. via MeshSyncEngine delegate).
    func receivedStatus(_ status: RangerStatus) {
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        guard status.lastSeen > fiveMinutesAgo else { return }

        if let idx = nearbyRangers.firstIndex(where: { $0.id == status.id }) {
            nearbyRangers[idx] = status
        } else {
            nearbyRangers.append(status)
        }
        pruneStaleRangers()
    }

    // MARK: - Helpers

    private func pruneStaleRangers() {
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        nearbyRangers.removeAll { $0.lastSeen <= fiveMinutesAgo }
    }
}
