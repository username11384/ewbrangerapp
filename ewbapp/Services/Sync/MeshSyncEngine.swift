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
            if let sightings = try? context.fetchAll(SightingLog.self) {
                for s in sightings {
                    entries.append(ManifestEntry(entityName: "SightingLog", id: s.id?.uuidString ?? "", updatedAt: s.updatedAt ?? .distantPast))
                }
            }
            if let patrols = try? context.fetchAll(PatrolRecord.self) {
                for p in patrols {
                    entries.append(ManifestEntry(entityName: "PatrolRecord", id: p.id?.uuidString ?? "", updatedAt: p.updatedAt ?? .distantPast))
                }
            }
            if let usages = try? context.fetchAll(PesticideUsageRecord.self) {
                for u in usages {
                    entries.append(ManifestEntry(entityName: "PesticideUsageRecord", id: u.id?.uuidString ?? "", updatedAt: u.updatedAt ?? .distantPast))
                }
            }
            if let treatments = try? context.fetchAll(TreatmentRecord.self) {
                for t in treatments {
                    entries.append(ManifestEntry(entityName: "TreatmentRecord", id: t.id?.uuidString ?? "", updatedAt: t.updatedAt ?? .distantPast))
                }
            }
            if let tasks = try? context.fetchAll(RangerTask.self) {
                for t in tasks {
                    entries.append(ManifestEntry(entityName: "RangerTask", id: t.id?.uuidString ?? "", updatedAt: t.updatedAt ?? .distantPast))
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
        case "request":
            if let ids = json["ids"] as? [String] {
                await sendRequestedRecords(ids: ids, to: peer)
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

    func sendRequestedRecords(ids: [String], to peer: MCPeerID) async {
        let context = persistence.backgroundContext
        var records: [[String: Any]] = []
        await context.perform {
            let uuids = ids.compactMap { UUID(uuidString: $0) }
            for uuid in uuids {
                let pred = NSPredicate(format: "id == %@", uuid as CVarArg)
                if let s = try? context.fetchFirst(SightingLog.self, predicate: pred) {
                    records.append(["type": "SightingLog", "id": s.id?.uuidString ?? "",
                                    "latitude": s.latitude, "longitude": s.longitude,
                                    "variant": s.variant ?? "unknown", "infestationSize": s.infestationSize ?? "small",
                                    "notes": s.notes ?? "", "createdAt": s.createdAt?.iso8601String ?? "",
                                    "updatedAt": s.updatedAt?.iso8601String ?? ""])
                } else if let t = try? context.fetchFirst(TreatmentRecord.self, predicate: pred) {
                    records.append(["type": "TreatmentRecord", "id": t.id?.uuidString ?? "",
                                    "method": t.method ?? "", "herbicideProduct": t.herbicideProduct ?? "",
                                    "outcomeNotes": t.outcomeNotes ?? "",
                                    "treatmentDate": t.treatmentDate?.iso8601String ?? "",
                                    "updatedAt": t.updatedAt?.iso8601String ?? "",
                                    "sightingID": t.sighting?.id?.uuidString ?? ""])
                } else if let task = try? context.fetchFirst(RangerTask.self, predicate: pred) {
                    records.append(["type": "RangerTask", "id": task.id?.uuidString ?? "",
                                    "title": task.title ?? "", "notes": task.notes ?? "",
                                    "priority": task.priority ?? "medium",
                                    "isComplete": task.isComplete,
                                    "dueDate": task.dueDate?.iso8601String ?? "",
                                    "updatedAt": task.updatedAt?.iso8601String ?? ""])
                }
            }
        }
        guard !records.isEmpty else { return }
        let msg: [String: Any] = ["type": "records", "records": records]
        if let data = try? JSONSerialization.data(withJSONObject: msg) {
            try? session?.send(data, toPeers: [peer], with: .reliable)
        }
    }

    func receiveRecords(_ data: Data, from peer: MCPeerID) async {
        guard let records = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return }
        let context = persistence.backgroundContext
        await context.perform {
            for record in records {
                guard let type = record["type"] as? String,
                      let idStr = record["id"] as? String,
                      let id = UUID(uuidString: idStr) else { continue }
                let pred = NSPredicate(format: "id == %@", id as CVarArg)
                let incoming = DateFormatter.iso8601Full.date(from: record["updatedAt"] as? String ?? "") ?? Date.distantPast

                switch type {
                case "SightingLog":
                    if let existing = try? context.fetchFirst(SightingLog.self, predicate: pred) {
                        if incoming > (existing.updatedAt ?? .distantPast) {
                            existing.variant = record["variant"] as? String
                            existing.infestationSize = record["infestationSize"] as? String
                            existing.notes = record["notes"] as? String
                            existing.updatedAt = incoming
                        }
                    } else {
                        let log = SightingLog(context: context)
                        log.id = id
                        log.latitude = record["latitude"] as? Double ?? 0
                        log.longitude = record["longitude"] as? Double ?? 0
                        log.variant = record["variant"] as? String
                        log.infestationSize = record["infestationSize"] as? String
                        log.notes = record["notes"] as? String
                        log.createdAt = DateFormatter.iso8601Full.date(from: record["createdAt"] as? String ?? "")
                        log.updatedAt = incoming
                        log.syncStatus = SyncStatus.pendingCreate.rawValue
                    }
                case "TreatmentRecord":
                    if let existing = try? context.fetchFirst(TreatmentRecord.self, predicate: pred) {
                        if incoming > (existing.updatedAt ?? .distantPast) {
                            existing.method = record["method"] as? String
                            existing.herbicideProduct = record["herbicideProduct"] as? String
                            existing.outcomeNotes = record["outcomeNotes"] as? String
                            existing.updatedAt = incoming
                        }
                    } else {
                        let t = TreatmentRecord(context: context)
                        t.id = id
                        t.method = record["method"] as? String
                        t.herbicideProduct = record["herbicideProduct"] as? String
                        t.outcomeNotes = record["outcomeNotes"] as? String
                        t.treatmentDate = DateFormatter.iso8601Full.date(from: record["treatmentDate"] as? String ?? "")
                        t.updatedAt = incoming
                        t.syncStatus = SyncStatus.pendingCreate.rawValue
                        // Link sighting if present
                        if let sID = UUID(uuidString: record["sightingID"] as? String ?? ""),
                           let sighting = try? context.fetchFirst(SightingLog.self, predicate: NSPredicate(format: "id == %@", sID as CVarArg)) {
                            t.sighting = sighting
                        }
                    }
                case "RangerTask":
                    if let existing = try? context.fetchFirst(RangerTask.self, predicate: pred) {
                        if incoming > (existing.updatedAt ?? .distantPast) {
                            existing.title = record["title"] as? String
                            existing.notes = record["notes"] as? String
                            existing.priority = record["priority"] as? String
                            existing.isComplete = record["isComplete"] as? Bool ?? false
                            existing.updatedAt = incoming
                        }
                    } else {
                        let task = RangerTask(context: context)
                        task.id = id
                        task.title = record["title"] as? String
                        task.notes = record["notes"] as? String
                        task.priority = record["priority"] as? String
                        task.isComplete = record["isComplete"] as? Bool ?? false
                        if let dueDateStr = record["dueDate"] as? String, !dueDateStr.isEmpty {
                            task.dueDate = DateFormatter.iso8601Full.date(from: dueDateStr)
                        }
                        task.createdAt = Date()
                        task.updatedAt = incoming
                        task.syncStatus = SyncStatus.pendingCreate.rawValue
                    }
                default:
                    break
                }
            }
            try? context.save()
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
