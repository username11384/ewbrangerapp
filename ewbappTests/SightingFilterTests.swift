import XCTest
import CoreData
import CoreLocation
@testable import ewbapp

@MainActor
final class SightingFilterTests: XCTestCase {

    var persistence: PersistenceController!
    var locationManager: LocationManager!
    private var testRangerID: UUID!
    private var insertedIDs: [UUID] = []

    override func setUp() async throws {
        try await super.setUp()
        persistence = PersistenceController.preview
        locationManager = LocationManager()
        testRangerID = UUID()
        insertedIDs = []
        try ensureRangerExists(id: testRangerID)
    }

    override func tearDown() async throws {
        try deleteInsertedSightings()
        persistence = nil
        locationManager = nil
        insertedIDs = []
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func ensureRangerExists(id: UUID) throws {
        let ctx = persistence.mainContext
        let pred = NSPredicate(format: "id == %@", id as CVarArg)
        if try ctx.fetchFirst(RangerProfile.self, predicate: pred) == nil {
            let r = RangerProfile(context: ctx)
            r.id = id
            r.displayName = "Test Ranger"
            r.role = RangerRole.ranger.rawValue
            r.createdAt = Date()
            r.updatedAt = Date()
            r.isCurrentDevice = false
            r.syncStatus = SyncStatus.synced.rawValue
            try ctx.save()
        }
    }

    @discardableResult
    private func insertSighting(variant: LantanaVariant, notes: String? = nil) throws -> SightingLog {
        let ctx = persistence.mainContext
        let s = SightingLog(context: ctx)
        let id = UUID()
        s.id = id
        s.createdAt = Date()
        s.updatedAt = Date()
        s.latitude = -14.7019
        s.longitude = 143.7075
        s.horizontalAccuracy = 10
        s.variant = variant.rawValue
        s.infestationSize = InfestationSize.small.rawValue
        s.notes = notes
        s.deviceID = "test"
        s.syncStatus = SyncStatus.synced.rawValue
        try ctx.save()
        insertedIDs.append(id)
        return s
    }

    private func deleteInsertedSightings() throws {
        let ctx = persistence.mainContext
        for id in insertedIDs {
            if let s = try ctx.fetchFirst(SightingLog.self, predicate: NSPredicate(format: "id == %@", id as CVarArg)) {
                ctx.delete(s)
            }
        }
        if ctx.hasChanges { try ctx.save() }
    }

    private func makeVM() -> SightingListViewModel {
        SightingListViewModel(persistence: persistence, locationManager: locationManager)
    }

    private func filteredByInserted(_ vm: SightingListViewModel) -> [SightingLog] {
        let ids = Set(insertedIDs)
        return vm.filtered.filter { s in s.id.map { ids.contains($0) } ?? false }
    }

    private func sightingsByInserted(_ vm: SightingListViewModel) -> [SightingLog] {
        let ids = Set(insertedIDs)
        return vm.sightings.filter { s in s.id.map { ids.contains($0) } ?? false }
    }

    // MARK: - Tests

    func test_filterByVariant_returnsOnlyMatchingSightings() throws {
        _ = try insertSighting(variant: .pink)
        _ = try insertSighting(variant: .pink)
        _ = try insertSighting(variant: .red)

        let vm = makeVM()
        vm.filterVariant = .pink

        let mine = filteredByInserted(vm)
        XCTAssertEqual(mine.count, 2)
        XCTAssertTrue(mine.allSatisfy { $0.variant == LantanaVariant.pink.rawValue })
    }

    func test_filterNil_returnsEverythingInOurFixture() throws {
        _ = try insertSighting(variant: .pink)
        _ = try insertSighting(variant: .red)
        _ = try insertSighting(variant: .orange)

        let vm = makeVM()
        vm.filterVariant = nil

        let mine = filteredByInserted(vm)
        XCTAssertEqual(mine.count, 3)
    }

    func test_switchingFilterVariant_replacesPreviousFilter() throws {
        _ = try insertSighting(variant: .pink)
        _ = try insertSighting(variant: .red)

        let vm = makeVM()

        vm.filterVariant = .pink
        XCTAssertEqual(filteredByInserted(vm).count, 1)

        vm.filterVariant = .red
        let redOnly = filteredByInserted(vm)
        XCTAssertEqual(redOnly.count, 1)
        XCTAssertEqual(redOnly.first?.variant, LantanaVariant.red.rawValue)
    }

    func test_filterWithNoMatchingSightings_returnsEmpty() throws {
        _ = try insertSighting(variant: .pink)
        _ = try insertSighting(variant: .pink)

        let vm = makeVM()
        vm.filterVariant = .white

        XCTAssertEqual(filteredByInserted(vm).count, 0)
    }

    func test_searchText_filtersByNotesCaseInsensitive() throws {
        let uniqueTag = "UNIQ-\(UUID().uuidString.prefix(8))"
        _ = try insertSighting(variant: .pink, notes: "contains \(uniqueTag) here")
        _ = try insertSighting(variant: .pink, notes: "does not match")

        let vm = makeVM()
        vm.searchText = uniqueTag.lowercased()

        let mine = filteredByInserted(vm)
        XCTAssertEqual(mine.count, 1)
    }

    func test_searchText_matchesVariantField() throws {
        _ = try insertSighting(variant: .pink)
        _ = try insertSighting(variant: .red)

        let vm = makeVM()
        vm.searchText = "pink"

        let mine = filteredByInserted(vm)
        XCTAssertTrue(mine.contains { $0.variant == LantanaVariant.pink.rawValue })
        XCTAssertFalse(mine.contains { $0.variant == LantanaVariant.red.rawValue })
    }

    func test_emptySightings_inOurScope_withFilter_returnsEmpty() {
        // No inserts for this test — insertedIDs stays empty.
        let vm = makeVM()
        vm.filterVariant = .pink

        XCTAssertTrue(filteredByInserted(vm).isEmpty)
    }

    func test_emptySightings_inOurScope_withNilFilter_returnsEmpty() {
        let vm = makeVM()
        vm.filterVariant = nil

        XCTAssertTrue(filteredByInserted(vm).isEmpty)
    }

    func test_searchAndFilter_compose() throws {
        _ = try insertSighting(variant: .pink, notes: "alpha")
        _ = try insertSighting(variant: .pink, notes: "beta")
        _ = try insertSighting(variant: .red, notes: "alpha")

        let vm = makeVM()
        vm.filterVariant = .pink
        vm.searchText = "alpha"

        let mine = filteredByInserted(vm)
        XCTAssertEqual(mine.count, 1)
        XCTAssertEqual(mine.first?.variant, LantanaVariant.pink.rawValue)
    }
}
