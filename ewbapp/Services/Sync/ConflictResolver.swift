import Foundation
import CoreData

/// Last-Write-Wins conflict resolver shared by cloud sync and mesh sync.
struct ConflictResolver {

    /// Resolves a conflict between a local CoreData object and incoming server/peer data.
    /// Server wins on all scalar fields. Photo filenames are merged (union, never lost).
    /// Returns true if local record was updated.
    @discardableResult
    static func resolve(
        local: NSManagedObject,
        incomingUpdatedAt: Date,
        incomingApply: (NSManagedObject) -> Void,
        localUpdatedAt: Date,
        localPhotoFilenames: [String]?
    ) -> Bool {
        guard incomingUpdatedAt > localUpdatedAt else { return false }
        // Server wins — apply incoming data
        incomingApply(local)
        // Merge photo filenames: union of both arrays
        if let localPhotos = localPhotoFilenames,
           let existingPhotos = local.value(forKey: "photoFilenames") as? [String] {
            let merged = Array(Set(localPhotos).union(Set(existingPhotos)))
            local.setValue(merged, forKey: "photoFilenames")
        }
        return true
    }
}
