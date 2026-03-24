import Combine
import Foundation
import MultipeerConnectivity
import CoreData

// MARK: - Manifest

struct ManifestEntry: Codable {
    let entityName: String
    let id: String
    let updatedAt: Date
}

// MARK: - MeshSyncEngine

actor MeshSyncEngine: NSObject {
    enum SyncPhase: Equatable {
        case idle
        case discovering
        case connected(peerName: String)
        case syncing(peerName: String, progress: Double)
        case done(peerName: String, sent: Int, received: Int)
        case failed(peerName: String, error: String)
    }

    @MainActor @Published var discoveredPeers: [MCPeerID] = []
    @MainActor @Published var peerPhases: [MCPeerID: SyncPhase] = [:]
    @MainActor @Published var overallPhase: SyncPhase = .idle

    private let persistence: PersistenceController
    private let myPeerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    init(persistence: PersistenceController, displayName: String) {
        self.persistence = persistence
        self.myPeerID = MCPeerID(displayName: displayName)
        super.init()
    }

    // MARK: - Start / Stop

    func start() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: AppConfig.meshServiceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: AppConfig.meshServiceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        Task { @MainActor in
            overallPhase = .discovering
        }
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        Task { @MainActor in
            overallPhase = .idle
            discoveredPeers = []
            peerPhases = [:]
        }
    }

    // MARK: - Manifest

    func buildManifest() async -> [ManifestEntry] {
        let context = persistence.backgroundContext
        var entries: [ManifestEntry] = []
        await context.perform {
            // SightingLog
            if let sightings = try? context.fetchAll(SightingLog.self) {
                for s in sightings {
                    entries.append(ManifestEntry(
                        entityName: "SightingLog",
                        id: s.id?.uuidString ?? "",
                        updatedAt: s.updatedAt ?? Date.distantPast
                    ))
                }
            }
            // PatrolRecord
            if let patrols = try? context.fetchAll(PatrolRecord.self) {
                for p in patrols {
                    entries.append(ManifestEntry(
                        entityName: "PatrolRecord",
                        id: p.id?.uuidString ?? "",
                        updatedAt: p.updatedAt ?? Date.distantPast
                    ))
                }
            }
            // PesticideUsageRecord
            if let usages = try? context.fetchAll(PesticideUsageRecord.self) {
                for u in usages {
                    entries.append(ManifestEntry(
                        entityName: "PesticideUsageRecord",
                        id: u.id?.uuidString ?? "",
                        updatedAt: u.updatedAt ?? Date.distantPast
                    ))
                }
            }
        }
        return entries
    }

    func sendManifest(to peer: MCPeerID) async {
        let manifest = await buildManifest()
        struct ManifestMessage: Encodable {
            let type: String
            let entries: [ManifestEntry]
        }
        guard let data = try? JSONEncoder().encode(ManifestMessage(type: "manifest", entries: manifest)) else { return }
        try? session?.send(data, toPeers: [peer], with: .reliable)
    }

    // MARK: - Data helpers

    private func sendJSON<T: Encodable>(_ value: T, to peer: MCPeerID) throws {
        let data = try JSONEncoder().encode(value)
        try session?.send(data, toPeers: [peer], with: .reliable)
    }
}

// MARK: - MCSession Delegate

extension MeshSyncEngine: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task {
            switch state {
            case .connected:
                await MainActor.run {
                    self.peerPhases[peerID] = .connected(peerName: peerID.displayName)
                }
                await sendManifest(to: peerID)
            case .notConnected:
                await MainActor.run {
                    self.peerPhases.removeValue(forKey: peerID)
                }
            default: break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task {
            await handleReceivedData(data, from: peerID)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    private func handleReceivedData(_ data: Data, from peer: MCPeerID) async {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "manifest":
            if let entriesData = try? JSONSerialization.data(withJSONObject: json["entries"] ?? []),
               let theirEntries = try? JSONDecoder().decode([ManifestEntry].self, from: entriesData) {
                let myEntries = await buildManifest()
                let needed = diffManifest(theirs: theirEntries, mine: myEntries)
                await sendRecordRequests(needed, to: peer)
            }
        case "records":
            if let recordsData = try? JSONSerialization.data(withJSONObject: json["records"] ?? []) {
                await receiveRecords(recordsData, from: peer)
            }
        default:
            break
        }
    }

    func diffManifest(theirs: [ManifestEntry], mine: [ManifestEntry]) -> [ManifestEntry] {
        let myIndex = Dictionary(uniqueKeysWithValues: mine.map { ($0.id, $0.updatedAt) })
        return theirs.filter { entry in
            if let myDate = myIndex[entry.id] {
                return entry.updatedAt > myDate
            }
            return true // They have it, I don't
        }
    }

    func sendRecordRequests(_ needed: [ManifestEntry], to peer: MCPeerID) async {
        guard !needed.isEmpty else { return }
        let ids = needed.map { $0.id }
        let request: [String: Any] = ["type": "request", "ids": ids]
        if let data = try? JSONSerialization.data(withJSONObject: request) {
            try? session?.send(data, toPeers: [peer], with: .reliable)
        }
    }

    func receiveRecords(_ data: Data, from peer: MCPeerID) async {
        // In PoC: parse array of SightingLogDTO and write to CoreData
        if let dtos = try? JSONDecoder().decode([SightingLogDTO].self, from: data) {
            let context = persistence.backgroundContext
            await context.perform {
                for dto in dtos {
                    let predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
                    if let existing = try? context.fetchFirst(SightingLog.self, predicate: predicate) {
                        let incoming = DateFormatter.iso8601Full.date(from: dto.updatedAt) ?? Date.distantPast
                        let local = existing.updatedAt ?? Date.distantPast
                        if incoming > local {
                            existing.variant = dto.variant
                            existing.infestationSize = dto.infestationSize
                            existing.notes = dto.notes
                            existing.updatedAt = incoming
                        }
                    } else {
                        let log = SightingLog(context: context)
                        log.id = UUID(uuidString: dto.id)
                        log.latitude = dto.latitude
                        log.longitude = dto.longitude
                        log.variant = dto.variant
                        log.infestationSize = dto.infestationSize
                        log.notes = dto.notes
                        log.createdAt = DateFormatter.iso8601Full.date(from: dto.createdAt)
                        log.updatedAt = DateFormatter.iso8601Full.date(from: dto.updatedAt)
                        log.syncStatus = SyncStatus.pendingCreate.rawValue
                    }
                }
                try? context.save()
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MeshSyncEngine: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept from any device in the trusted ranger group (PoC)
        Task {
            invitationHandler(true, await self.session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MeshSyncEngine: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task {
            await MainActor.run {
                if !self.discoveredPeers.contains(peerID) {
                    self.discoveredPeers.append(peerID)
                }
            }
            // Auto-invite discovered peers
            await self.session.map { browser.invitePeer(peerID, to: $0, withContext: nil, timeout: 30) }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task {
            await MainActor.run {
                self.discoveredPeers.removeAll { $0 == peerID }
            }
        }
    }
}

// Helper extension for JSON encoding of mixed dictionary
private extension Dictionary where Key == String {
    func jsonData() throws -> Any { self }
}
