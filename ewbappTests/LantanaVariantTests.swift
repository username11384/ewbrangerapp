import XCTest
import SwiftUI
@testable import ewbapp

final class LantanaVariantTests: XCTestCase {

    // MARK: - displayName

    func test_displayName_isNonEmpty_forAllCases() {
        for variant in LantanaVariant.allCases {
            XCTAssertFalse(variant.displayName.isEmpty, "displayName empty for \(variant)")
        }
    }

    func test_displayName_doesNotEqualRawValue_forMultiWordCases() {
        XCTAssertNotEqual(LantanaVariant.pinkEdgedRed.displayName, LantanaVariant.pinkEdgedRed.rawValue)
    }

    // MARK: - color

    func test_color_isNotClear_forAllCases() {
        for variant in LantanaVariant.allCases {
            XCTAssertNotEqual(variant.color, Color.clear, "color is clear for \(variant)")
        }
    }

    func test_color_pinkAndRed_areDistinct() {
        XCTAssertNotEqual(LantanaVariant.pink.color, LantanaVariant.red.color)
    }

    func test_color_unknown_isGray() {
        XCTAssertEqual(LantanaVariant.unknown.color, Color.gray)
    }

    // MARK: - hasBiocontrolConcern

    func test_hasBiocontrolConcern_isTrue_onlyForPink() {
        XCTAssertTrue(LantanaVariant.pink.hasBiocontrolConcern)
        XCTAssertFalse(LantanaVariant.red.hasBiocontrolConcern)
        XCTAssertFalse(LantanaVariant.pinkEdgedRed.hasBiocontrolConcern)
        XCTAssertFalse(LantanaVariant.orange.hasBiocontrolConcern)
        XCTAssertFalse(LantanaVariant.white.hasBiocontrolConcern)
        XCTAssertFalse(LantanaVariant.unknown.hasBiocontrolConcern)
    }

    func test_hasBiocontrolConcern_exactlyOneCaseReturnsTrue() {
        let count = LantanaVariant.allCases.filter { $0.hasBiocontrolConcern }.count
        XCTAssertEqual(count, 1)
    }

    // MARK: - controlMethods

    func test_controlMethods_isNonEmpty_forAllCases() {
        for variant in LantanaVariant.allCases {
            XCTAssertFalse(variant.controlMethods.isEmpty, "controlMethods empty for \(variant)")
        }
    }

    // MARK: - distinguishingFeatures

    func test_distinguishingFeatures_isNonEmpty_forAllCases() {
        for variant in LantanaVariant.allCases {
            XCTAssertFalse(variant.distinguishingFeatures.isEmpty, "distinguishingFeatures empty for \(variant)")
        }
    }

    func test_distinguishingFeatures_differsBetweenCases() {
        let all = LantanaVariant.allCases.map { $0.distinguishingFeatures }
        XCTAssertEqual(Set(all).count, all.count)
    }

    // MARK: - rawValue round-trip

    func test_rawValue_roundTrips_forAllCases() {
        for variant in LantanaVariant.allCases {
            XCTAssertEqual(LantanaVariant(rawValue: variant.rawValue), variant)
        }
    }

    func test_rawValueInit_withUnknownString_returnsNil() {
        XCTAssertNil(LantanaVariant(rawValue: "nonexistent"))
    }

    func test_rawValueInit_withEmptyString_returnsNil() {
        XCTAssertNil(LantanaVariant(rawValue: ""))
    }

    func test_rawValueInit_caseSensitivity_wrongCaseReturnsNil() {
        XCTAssertNil(LantanaVariant(rawValue: "PINK"))
        XCTAssertNil(LantanaVariant(rawValue: "Pink"))
    }

    // MARK: - allCases coverage

    func test_allCases_containsSixVariants() {
        XCTAssertEqual(LantanaVariant.allCases.count, 6)
    }
}
