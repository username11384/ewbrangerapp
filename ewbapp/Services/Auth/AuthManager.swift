import Combine
import Foundation
import UIKit

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentRangerID: UUID?

    init() {
        restoreSession()
    }

    // MARK: - PIN Login (offline-capable)
    // PoC: single shared PIN for all rangers, stored as hashed value only.

    func loginWithPIN(rangerID: UUID, pin: String) -> Bool {
        let stored = KeychainService.load(.pin)
        let hashed = hashPIN(pin)
        // Accept if PIN matches stored hash, OR if no PIN has been set yet (first run)
        guard stored == nil || stored == hashed else { return false }
        if stored == nil { KeychainService.save(hashed, for: .pin) }
        KeychainService.save(rangerID.uuidString, for: .rangerID)
        currentRangerID = rangerID
        isAuthenticated = true
        return true
    }

    func setPIN(_ pin: String, for rangerID: UUID) {
        // PoC: store a single shared PIN hash — same PIN works for all rangers
        KeychainService.save(hashPIN(pin), for: .pin)
    }

    // MARK: - Supabase Auth (stubbed for PoC — offline PIN only)

    func loginOnline(email: String, password: String) async throws {
        // PoC: no backend — PIN auth is the only mechanism
        print("[AuthManager] Online login stubbed for PoC")
    }

    func refreshTokenIfNeeded() async {
        // PoC: no-op
    }

    func logout() {
        KeychainService.clearAll()
        isAuthenticated = false
        currentRangerID = nil
    }

    // MARK: - Session restore

    private func restoreSession() {
        if let rangerIDString = KeychainService.load(.rangerID),
           let rangerID = UUID(uuidString: rangerIDString) {
            currentRangerID = rangerID
            isAuthenticated = true
        }
    }

    // MARK: - Helpers

    private func hashPIN(_ pin: String) -> String {
        // Simple deterministic hash — in production use CryptoKit SHA256
        var hash = 5381
        for char in pin.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(char.value)
        }
        return String(hash)
    }

    var currentJWT: String? {
        KeychainService.load(.jwt)
    }
}
