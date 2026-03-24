import Foundation
import CoreData

actor PhotoUploadManager {
    private let supabaseClient: SupabaseClient
    private let persistence: PersistenceController

    init(supabaseClient: SupabaseClient = .shared, persistence: PersistenceController) {
        self.supabaseClient = supabaseClient
        self.persistence = persistence
    }

    func uploadPendingPhotos(rangerID: UUID, jwt: String) async {
        let photosDir = photosDirectory()
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: photosDir.path) else { return }

        for filename in contents {
            let fileURL = photosDir.appendingPathComponent(filename)
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            // Path: {rangerID}/{sightingID}/{filename}
            let parts = filename.split(separator: "_")
            let sightingID = parts.count > 1 ? String(parts[0]) : "unknown"
            let remotePath = "\(rangerID.uuidString)/\(sightingID)/\(filename)"
            do {
                try await supabaseClient.uploadPhoto(
                    bucketName: AppConfig.photosBucket,
                    path: remotePath,
                    data: data,
                    contentType: "image/heif",
                    jwt: jwt
                )
            } catch {
                print("Photo upload failed for \(filename): \(error)")
            }
        }
    }

    private func photosDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(AppConfig.photosDirectoryName)
    }
}
