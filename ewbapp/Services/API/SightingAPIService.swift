import Foundation
import CoreData

final class SightingAPIService {
    private let client: SupabaseClient
    private let path = "sighting_logs"

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    func uploadSighting(_ dto: SightingLogDTO, jwt: String) async throws -> SightingLogDTO {
        let data = try JSONEncoder().encode(dto)
        let response = try await client.post(path: path, jwt: jwt, body: data)
        let decoded = try JSONDecoder().decode([SightingLogDTO].self, from: response)
        guard let first = decoded.first else { throw SyncError.encodingError }
        return first
    }

    func patchSighting(_ dto: SightingLogDTO, jwt: String) async throws -> SightingLogDTO {
        let data = try JSONEncoder().encode(dto)
        let response = try await client.patch(
            path: path,
            jwt: jwt,
            body: data,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(dto.id)")]
        )
        let decoded = try JSONDecoder().decode([SightingLogDTO].self, from: response)
        guard let first = decoded.first else { throw SyncError.encodingError }
        return first
    }

    func fetchSightings(since: Date, jwt: String) async throws -> [SightingLogDTO] {
        let isoDate = since.iso8601String
        let data = try await client.get(
            path: path,
            jwt: jwt,
            queryItems: [
                URLQueryItem(name: "updated_at", value: "gt.\(isoDate)"),
                URLQueryItem(name: "order", value: "updated_at.asc")
            ]
        )
        return try JSONDecoder().decode([SightingLogDTO].self, from: data)
    }

    func deleteSighting(id: String, jwt: String) async throws {
        try await client.delete(
            path: path,
            jwt: jwt,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id)")]
        )
    }
}
