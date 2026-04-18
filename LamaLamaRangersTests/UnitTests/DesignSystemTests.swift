import XCTest
import SwiftUI
@testable import ewbapp

final class DesignSystemTests: XCTestCase {

    // MARK: - 6-char hex parsing

    func test_hexInit_parses6CharHex_F4EFE4() {
        let c = Color(hex: "F4EFE4")
        XCTAssertNotEqual(c, Color(hex: "000000"))
        XCTAssertNotEqual(c, Color(hex: "FFFFFF"))
    }

    func test_hexInit_parses6CharHex_2E4634() {
        let c = Color(hex: "2E4634")
        XCTAssertNotEqual(c, Color(hex: "000000"))
        XCTAssertNotEqual(c, Color(hex: "FFFFFF"))
    }

    func test_hexInit_parses6CharHex_C26A2A() {
        let c = Color(hex: "C26A2A")
        XCTAssertNotEqual(c, Color(hex: "000000"))
        XCTAssertNotEqual(c, Color(hex: "FFFFFF"))
    }

    // MARK: - Case insensitivity

    func test_hexInit_uppercaseAndLowercase_produceSameColor() {
        let upper = Color(hex: "F4EFE4")
        let lower = Color(hex: "f4efe4")
        XCTAssertEqual(upper, lower)
    }

    func test_hexInit_mixedCase_produceSameColor() {
        let mixed = Color(hex: "f4EfE4")
        let upper = Color(hex: "F4EFE4")
        XCTAssertEqual(mixed, upper)
    }

    // MARK: - Hash prefix stripping

    func test_hexInit_withHashPrefix_stripsHash() {
        let withHash = Color(hex: "#F4EFE4")
        let noHash = Color(hex: "F4EFE4")
        XCTAssertEqual(withHash, noHash)
    }

    func test_hexInit_withWhitespaceAndHash_stillParses() {
        let prefixed = Color(hex: "#2E4634")
        let plain = Color(hex: "2E4634")
        XCTAssertEqual(prefixed, plain)
    }

    // MARK: - Invalid / malformed input

    func test_hexInit_withEmptyString_returnsFallbackColor() {
        let c = Color(hex: "")
        XCTAssertNotNil(c)
    }

    func test_hexInit_with3CharHex_returnsFallbackColorWithoutCrash() {
        let c = Color(hex: "ABC")
        XCTAssertNotNil(c)
    }

    func test_hexInit_with8CharHex_returnsFallbackColorWithoutCrash() {
        let c = Color(hex: "DEADBEEF")
        XCTAssertNotNil(c)
    }

    func test_hexInit_withNonHexChars_stripsToAlphanumericsWithoutCrash() {
        let c = Color(hex: "!!!!zzzzz")
        XCTAssertNotNil(c)
    }

    func test_hexInit_withOnlyHashChar_doesNotCrash() {
        let c = Color(hex: "#")
        XCTAssertNotNil(c)
    }

    // MARK: - Named tokens exist and are not clear / black

    func test_paperToken_isNotBlack() {
        XCTAssertNotEqual(Color.paper, Color(hex: "000000"))
    }

    func test_eucToken_isNotBlack() {
        XCTAssertNotEqual(Color.euc, Color(hex: "000000"))
    }

    func test_ochreToken_isNotBlack() {
        XCTAssertNotEqual(Color.ochre, Color(hex: "000000"))
    }

    func test_eucDarkToken_isNotBlack() {
        XCTAssertNotEqual(Color.eucDark, Color(hex: "000000"))
    }

    func test_barkToken_isNotBlack() {
        XCTAssertNotEqual(Color.bark, Color(hex: "000000"))
    }

    func test_inkToken_isNotWhite() {
        XCTAssertNotEqual(Color.ink, Color(hex: "FFFFFF"))
    }

    func test_statusClearedToken_isNotBlack() {
        XCTAssertNotEqual(Color.statusCleared, Color(hex: "000000"))
    }

    func test_statusActiveToken_isNotBlack() {
        XCTAssertNotEqual(Color.statusActive, Color(hex: "000000"))
    }

    func test_namedTokens_distinctFromEachOther() {
        XCTAssertNotEqual(Color.paper, Color.euc)
        XCTAssertNotEqual(Color.euc, Color.ochre)
        XCTAssertNotEqual(Color.ochre, Color.bark)
        XCTAssertNotEqual(Color.statusActive, Color.statusCleared)
    }
}
