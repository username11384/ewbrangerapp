import XCTest
@testable import ewbapp

final class ControlProtocolLogicTests: XCTestCase {

    func testPinkVariantRecommendsSpray() {
        let methods = LantanaVariant.pink.controlMethods
        XCTAssertTrue(methods.contains(.foliarSpray))
    }

    func testRedVariantRecommendsCutStump() {
        let methods = LantanaVariant.red.controlMethods
        XCTAssertTrue(methods.contains(.cutStump))
    }

    func testPinkHasBiocontrolConcern() {
        XCTAssertTrue(LantanaVariant.pink.hasBiocontrolConcern)
    }

    func testRedNoBiocontrolConcern() {
        XCTAssertFalse(LantanaVariant.red.hasBiocontrolConcern)
    }

    func testAllVariantsCovered() {
        for variant in LantanaVariant.allCases {
            XCTAssertFalse(variant.controlMethods.isEmpty, "\(variant.rawValue) has no control methods")
        }
    }

    func testAllMethodsHaveInstructions() {
        for method in TreatmentMethod.allCases {
            XCTAssertFalse(method.instructions.isEmpty)
            XCTAssertFalse(method.displayName.isEmpty)
        }
    }
}
