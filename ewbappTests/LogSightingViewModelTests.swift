import XCTest
import CoreLocation
import CoreData
@testable import ewbapp

@MainActor
final class LogSightingViewModelTests: XCTestCase {

    var persistence: PersistenceController!
    var locationManager: LocationManager!
    var rangerID: UUID!

    override func setUp() async throws {
        try await super.setUp()
        persistence = PersistenceController.preview
        locationManager = LocationManager()
        rangerID = UUID()
    }

    override func tearDown() async throws {
        persistence = nil
        locationManager = nil
        rangerID = nil
        try await super.tearDown()
    }

    private func makeVM() -> LogSightingViewModel {
        LogSightingViewModel(locationManager: locationManager, persistence: persistence, rangerID: rangerID)
    }

    // MARK: - canSave

    func test_canSave_isFalse_whenVariantAndLocationAreNil() {
        let vm = makeVM()
        vm.capturedLocation = nil
        vm.selectedVariant = nil
        XCTAssertFalse(vm.canSave)
    }

    func test_canSave_isFalse_whenVariantIsNil() {
        let vm = makeVM()
        vm.capturedLocation = CLLocation(latitude: 0, longitude: 0)
        vm.selectedVariant = nil
        XCTAssertFalse(vm.canSave)
    }

    func test_canSave_isFalse_whenLocationIsNil() {
        let vm = makeVM()
        vm.capturedLocation = nil
        vm.selectedVariant = .pink
        XCTAssertFalse(vm.canSave)
    }

    func test_canSave_isTrue_whenBothLocationAndVariantAreSet() {
        let vm = makeVM()
        vm.capturedLocation = CLLocation(latitude: -14.7019, longitude: 143.7075)
        vm.selectedVariant = .pink
        XCTAssertTrue(vm.canSave)
    }

    func test_canSave_becomesFalse_whenVariantSetThenClearedBackToNil() {
        let vm = makeVM()
        vm.capturedLocation = CLLocation(latitude: 0, longitude: 0)
        vm.selectedVariant = .red
        XCTAssertTrue(vm.canSave)

        vm.selectedVariant = nil
        XCTAssertFalse(vm.canSave)
    }

    func test_canSave_becomesFalse_whenLocationClearedBackToNil() {
        let vm = makeVM()
        vm.capturedLocation = CLLocation(latitude: 0, longitude: 0)
        vm.selectedVariant = .red
        XCTAssertTrue(vm.canSave)

        vm.capturedLocation = nil
        XCTAssertFalse(vm.canSave)
    }

    // MARK: - notes

    func test_notes_defaultIsEmptyString() {
        let vm = makeVM()
        XCTAssertEqual(vm.notes, "")
    }

    func test_notes_emptyStringIsPermitted_andDoesNotBlockCanSave() {
        let vm = makeVM()
        vm.capturedLocation = CLLocation(latitude: 0, longitude: 0)
        vm.selectedVariant = .pink
        vm.notes = ""
        XCTAssertTrue(vm.canSave)
    }

    // MARK: - GPS initial state

    func test_capturedLocation_isNil_immediatelyAfterInitBeforeCaptureResolves() {
        let vm = LogSightingViewModel(locationManager: locationManager, persistence: persistence, rangerID: rangerID)
        XCTAssertNil(vm.capturedLocation)
    }

    func test_accuracyLevel_isUnknown_onInitBeforeCaptureResolves() {
        let vm = LogSightingViewModel(locationManager: locationManager, persistence: persistence, rangerID: rangerID)
        XCTAssertEqual(vm.accuracyLevel, .unknown)
    }

    // MARK: - accuracyLevel thresholds mirror LocationManager

    func test_accuracyLevel_good_hasGreenColorString() {
        XCTAssertEqual(LocationManager.AccuracyLevel.good.color, "green")
    }

    func test_accuracyLevel_fair_hasYellowColorString() {
        XCTAssertEqual(LocationManager.AccuracyLevel.fair.color, "yellow")
    }

    func test_accuracyLevel_poor_hasRedColorString() {
        XCTAssertEqual(LocationManager.AccuracyLevel.poor.color, "red")
    }

    func test_accuracyLevel_unknown_hasGrayColorString() {
        XCTAssertEqual(LocationManager.AccuracyLevel.unknown.color, "gray")
    }

    // MARK: - photoFilenames

    func test_photoFilenames_isEmpty_onInit() {
        let vm = makeVM()
        XCTAssertTrue(vm.photoFilenames.isEmpty)
    }

    // MARK: - default selected size

    func test_selectedSize_defaultsToSmall() {
        let vm = makeVM()
        XCTAssertEqual(vm.selectedSize, .small)
    }

    // MARK: - controlRecommendation

    func test_controlRecommendation_isNil_whenVariantIsNil() {
        let vm = makeVM()
        vm.selectedVariant = nil
        XCTAssertNil(vm.controlRecommendation)
    }

    func test_controlRecommendation_isNonNil_whenVariantIsSet() {
        let vm = makeVM()
        vm.selectedVariant = .pink
        XCTAssertNotNil(vm.controlRecommendation)
        XCTAssertTrue(vm.controlRecommendation?.starts(with: "Recommended:") == true)
    }

    // MARK: - save with bogus ranger ID is handled gracefully

    func test_save_withBogusRangerID_doesNotCrash_andLeavesVMInConsistentState() async {
        let vm = makeVM()
        vm.capturedLocation = CLLocation(latitude: 0, longitude: 0)
        vm.selectedVariant = .pink

        await vm.save()

        XCTAssertFalse(vm.isSaving)
    }

    func test_save_whenCannotSave_isNoOp_andDoesNotMarkDidSave() async {
        let vm = makeVM()
        vm.capturedLocation = nil
        vm.selectedVariant = nil

        await vm.save()

        XCTAssertFalse(vm.didSave)
        XCTAssertFalse(vm.isSaving)
        XCTAssertNil(vm.saveError)
    }

    // MARK: - initial flags

    func test_isSaving_isFalse_onInit() {
        let vm = makeVM()
        XCTAssertFalse(vm.isSaving)
    }

    func test_didSave_isFalse_onInit() {
        let vm = makeVM()
        XCTAssertFalse(vm.didSave)
    }

    func test_saveError_isNil_onInit() {
        let vm = makeVM()
        XCTAssertNil(vm.saveError)
    }
}
