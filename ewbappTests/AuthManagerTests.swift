import XCTest
import CoreData
@testable import ewbapp

@MainActor
final class AuthManagerTests: XCTestCase {

    var authManager: AuthManager!
    var rangerID: UUID!

    override func setUp() async throws {
        try await super.setUp()
        KeychainService.clearAll()
        authManager = AuthManager()
        authManager.logout()
        rangerID = UUID()
    }

    override func tearDown() async throws {
        KeychainService.clearAll()
        authManager = nil
        rangerID = nil
        try await super.tearDown()
    }

    // MARK: - First-run PIN acceptance

    func test_loginWithPIN_onFirstRun_acceptsAnyPINAndStoresIt() {
        let ok = authManager.loginWithPIN(rangerID: rangerID, pin: "9999")
        XCTAssertTrue(ok)
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(KeychainService.load(.pin))
    }

    func test_loginWithPIN_onFirstRun_withEmptyPIN_stillStores() {
        let ok = authManager.loginWithPIN(rangerID: rangerID, pin: "")
        XCTAssertTrue(ok)
        XCTAssertNotNil(KeychainService.load(.pin))
    }

    // MARK: - Correct vs wrong PIN

    func test_loginWithPIN_correctPIN_succeeds() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        authManager.logout()

        let ok = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        XCTAssertTrue(ok)
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(authManager.currentRangerID, rangerID)
    }

    func test_loginWithPIN_wrongPIN_failsAndDoesNotAuthenticate() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        authManager.logout()

        let ok = authManager.loginWithPIN(rangerID: rangerID, pin: "0000")
        XCTAssertFalse(ok)
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentRangerID)
    }

    // MARK: - Lockout behaviour

    func test_loginWithPIN_repeatedWrongAttempts_doNotLockOut() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        authManager.logout()

        for _ in 0..<20 {
            let failed = authManager.loginWithPIN(rangerID: rangerID, pin: "0000")
            XCTAssertFalse(failed)
            XCTAssertFalse(authManager.isAuthenticated)
        }

        let ok = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        XCTAssertTrue(ok)
        XCTAssertTrue(authManager.isAuthenticated)
    }

    // MARK: - Ranger ID lifecycle

    func test_currentRangerID_isNil_beforeLogin() {
        XCTAssertNil(authManager.currentRangerID)
        XCTAssertFalse(authManager.isAuthenticated)
    }

    func test_currentRangerID_isSet_afterSuccessfulLogin() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        XCTAssertEqual(authManager.currentRangerID, rangerID)
    }

    func test_logout_clearsAuthenticationAndRangerID() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        XCTAssertTrue(authManager.isAuthenticated)

        authManager.logout()

        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentRangerID)
    }

    func test_logout_clearsStoredPINFromKeychain() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        XCTAssertNotNil(KeychainService.load(.pin))

        authManager.logout()

        XCTAssertNil(KeychainService.load(.pin))
        XCTAssertNil(KeychainService.load(.rangerID))
    }

    // MARK: - changePIN

    func test_changePIN_withCorrectOldPIN_succeeds() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")

        let ok = authManager.changePIN(oldPIN: "1234", newPIN: "5678")
        XCTAssertTrue(ok)

        authManager.logout()
        let loggedInWithNew = authManager.loginWithPIN(rangerID: rangerID, pin: "5678")
        XCTAssertTrue(loggedInWithNew)
    }

    func test_changePIN_withWrongOldPIN_failsAndLeavesPINUnchanged() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")

        let ok = authManager.changePIN(oldPIN: "0000", newPIN: "5678")
        XCTAssertFalse(ok)

        authManager.logout()
        let stillWorks = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        XCTAssertTrue(stillWorks)
    }

    func test_changePIN_withWrongOldPIN_newPINDoesNotWork() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        _ = authManager.changePIN(oldPIN: "0000", newPIN: "5678")

        authManager.logout()
        let shouldFail = authManager.loginWithPIN(rangerID: rangerID, pin: "5678")
        XCTAssertFalse(shouldFail)
    }

    // MARK: - currentRanger

    func test_currentRanger_isNil_whenNotLoggedIn() {
        XCTAssertNil(authManager.currentRanger)
    }

    func test_currentRanger_isNil_whenRangerIDHasNoMatchingProfile() {
        _ = authManager.loginWithPIN(rangerID: UUID(), pin: "1234")
        XCTAssertNil(authManager.currentRanger)
    }

    // MARK: - Hash determinism

    func test_pinHash_isDeterministic_acrossManagerInstances() {
        let firstManager = AuthManager()
        _ = firstManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        firstManager.logout()
        // Re-save because logout clears
        _ = firstManager.loginWithPIN(rangerID: rangerID, pin: "1234")

        let secondManager = AuthManager()
        let ok = secondManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        XCTAssertTrue(ok)
    }

    func test_pinHash_differentPINs_produceDifferentHashes() {
        _ = authManager.loginWithPIN(rangerID: rangerID, pin: "1234")
        authManager.logout()

        let wrong = authManager.loginWithPIN(rangerID: rangerID, pin: "4321")
        XCTAssertFalse(wrong)
    }
}
