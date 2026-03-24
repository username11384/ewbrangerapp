import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController
    let syncEngine: SyncEngine
    let locationManager: LocationManager
    let authManager: AuthManager

    static let shared: AppEnvironment = AppEnvironment()

    private init() {
        let persistence = PersistenceController.shared
        self.persistence = persistence
        self.authManager = AuthManager()
        self.locationManager = LocationManager()
        self.syncEngine = SyncEngine(persistence: persistence)
    }
}
