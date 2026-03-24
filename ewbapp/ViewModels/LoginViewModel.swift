import Combine
import Foundation
import CoreData

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var rangers: [RangerProfile] = []
    @Published var selectedRanger: RangerProfile?
    @Published var enteredPIN = ""
    @Published var loginError: String?
    @Published var isLoggedIn = false

    private let authManager: AuthManager
    private let rangerRepository: RangerRepository

    init(authManager: AuthManager, persistence: PersistenceController) {
        self.authManager = authManager
        self.rangerRepository = RangerRepository(persistence: persistence)
        loadRangers()
    }

    func loadRangers() {
        rangers = (try? rangerRepository.fetchAllRangers()) ?? []
    }

    func appendPINDigit(_ digit: String) {
        guard enteredPIN.count < 4 else { return }
        enteredPIN += digit
        if enteredPIN.count == 4 {
            attemptLogin()
        }
    }

    func deletePINDigit() {
        guard !enteredPIN.isEmpty else { return }
        enteredPIN.removeLast()
    }

    private func attemptLogin() {
        guard let ranger = selectedRanger, let rangerID = ranger.id else {
            loginError = "Please select a ranger first"
            enteredPIN = ""
            return
        }
        if authManager.loginWithPIN(rangerID: rangerID, pin: enteredPIN) {
            isLoggedIn = true
        } else {
            loginError = "Incorrect PIN"
            enteredPIN = ""
        }
    }

    func selectRanger(_ ranger: RangerProfile) {
        selectedRanger = ranger
        enteredPIN = ""
        loginError = nil
    }

    func seedDemoRangersIfNeeded(authManager: AuthManager, persistence: PersistenceController) {
        guard rangers.isEmpty else { return }
        let demoNames = [("Alice Johnson", RangerRole.seniorRanger), ("Bob Smith", RangerRole.ranger), ("Carol White", RangerRole.ranger)]
        let context = persistence.backgroundContext
        context.perform {
            for (name, role) in demoNames {
                let ranger = RangerProfile(context: context)
                ranger.id = UUID()
                ranger.createdAt = Date()
                ranger.updatedAt = Date()
                ranger.displayName = name
                ranger.role = role.rawValue
                ranger.supabaseUID = UUID().uuidString
                ranger.isCurrentDevice = false
                ranger.syncStatus = SyncStatus.synced.rawValue
            }
            try? context.save()
            DispatchQueue.main.async {
                // Set the shared PIN once on the main actor
                authManager.setPIN("1234", for: UUID())
                self.loadRangers()
            }
        }
    }
}
