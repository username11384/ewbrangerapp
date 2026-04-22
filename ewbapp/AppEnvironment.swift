import Combine
import CoreData
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController
    let syncEngine: SyncEngine
    let meshSyncEngine: MeshSyncEngine
    let locationManager: LocationManager
    let authManager: AuthManager

    static let shared: AppEnvironment = AppEnvironment()

    private init() {
        let persistence = PersistenceController.shared
        self.persistence = persistence
        self.authManager = AuthManager()
        self.locationManager = LocationManager()
        self.syncEngine = SyncEngine(persistence: persistence)
        self.meshSyncEngine = MeshSyncEngine(persistence: persistence, displayName: "Ranger")

        // Seed demo rangers synchronously before any UI renders.
        // Uses performAndWait so rangers exist in the store before ContentView checks auth.
        let ctx = persistence.backgroundContext
        let isEmpty = (try? persistence.mainContext.fetchAll(RangerProfile.self))?.isEmpty ?? true
        if isEmpty {
            ctx.performAndWait {
                let demoData: [(String, String)] = [
                    ("Alice Johnson", RangerRole.seniorRanger.rawValue),
                    ("Bob Smith",     RangerRole.ranger.rawValue),
                    ("Carol White",   RangerRole.ranger.rawValue)
                ]
                for (name, role) in demoData {
                    let ranger = RangerProfile(context: ctx)
                    ranger.id = UUID()
                    ranger.createdAt = Date()
                    ranger.updatedAt = Date()
                    ranger.displayName = name
                    ranger.role = role
                    ranger.supabaseUID = UUID().uuidString
                    ranger.isCurrentDevice = false
                    ranger.syncStatus = SyncStatus.synced.rawValue
                }
                try? ctx.save()
            }
            // Set default PIN if none exists
            if KeychainService.load(.pin) == nil {
                self.authManager.setPIN("1234", for: UUID())
            }
        }

        // Seed rich demo data (idempotent — runs once, guarded by UserDefaults flag)
        DemoSeeder.seed(in: persistence)

        // Validate restored session: if the stored rangerID no longer exists in CoreData
        // (e.g. app data was cleared but Keychain wasn't), force re-login.
        if let rangerID = authManager.currentRangerID {
            let pred = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if (try? persistence.mainContext.fetchFirst(RangerProfile.self, predicate: pred)) == nil {
                authManager.logout()
            }
        }
    }
}
