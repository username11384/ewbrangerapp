import XCTest
import CoreData
@testable import ewbapp

final class ConflictResolverTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        context = PersistenceController.preview.mainContext
    }

    func testServerWinsOnNewerDate() {
        let localDate = Date().addingTimeInterval(-100)
        let serverDate = Date()

        var applyCalled = false
        let result = ConflictResolver.resolve(
            local: SightingLog(context: context),
            incomingUpdatedAt: serverDate,
            incomingApply: { _ in applyCalled = true },
            localUpdatedAt: localDate,
            localPhotoFilenames: nil
        )
        XCTAssertTrue(result)
        XCTAssertTrue(applyCalled)
    }

    func testLocalWinsOnOlderIncoming() {
        let localDate = Date()
        let serverDate = Date().addingTimeInterval(-100)

        var applyCalled = false
        let result = ConflictResolver.resolve(
            local: SightingLog(context: context),
            incomingUpdatedAt: serverDate,
            incomingApply: { _ in applyCalled = true },
            localUpdatedAt: localDate,
            localPhotoFilenames: nil
        )
        XCTAssertFalse(result)
        XCTAssertFalse(applyCalled)
    }

    func testPhotosAreMerged() {
        let sighting = SightingLog(context: context)
        sighting.photoFilenames = ["server_photo.jpg"] as NSArray

        let localDate = Date().addingTimeInterval(-100)
        let serverDate = Date()

        ConflictResolver.resolve(
            local: sighting,
            incomingUpdatedAt: serverDate,
            incomingApply: { obj in
                (obj as? SightingLog)?.photoFilenames = ["server_photo.jpg"] as NSArray
            },
            localUpdatedAt: localDate,
            localPhotoFilenames: ["local_photo.jpg"]
        )

        let photos = sighting.photoFilenames as? [String] ?? []
        XCTAssertTrue(photos.contains("server_photo.jpg"))
        XCTAssertTrue(photos.contains("local_photo.jpg"))
    }
}
