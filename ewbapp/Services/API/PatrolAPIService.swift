import Foundation

final class PatrolAPIService {
    private let client: SupabaseClient
    private let path = "patrol_records"

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    func upload(_ dto: PatrolRecordDTO, jwt: String) async throws -> PatrolRecordDTO {
        let data = try JSONEncoder().encode(dto)
        let response = try await client.post(path: path, jwt: jwt, body: data)
        let decoded = try JSONDecoder().decode([PatrolRecordDTO].self, from: response)
        guard let first = decoded.first else { throw SyncError.encodingError }
        return first
    }

    func patch(_ dto: PatrolRecordDTO, jwt: String) async throws -> PatrolRecordDTO {
        let data = try JSONEncoder().encode(dto)
        let response = try await client.patch(
            path: path, jwt: jwt, body: data,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(dto.id)")]
        )
        let decoded = try JSONDecoder().decode([PatrolRecordDTO].self, from: response)
        guard let first = decoded.first else { throw SyncError.encodingError }
        return first
    }

    func fetch(since: Date, jwt: String) async throws -> [PatrolRecordDTO] {
        let isoDate = since.iso8601String
        let data = try await client.get(
            path: path, jwt: jwt,
            queryItems: [
                URLQueryItem(name: "updated_at", value: "gt.\(isoDate)"),
                URLQueryItem(name: "order", value: "updated_at.asc")
            ]
        )
        return try JSONDecoder().decode([PatrolRecordDTO].self, from: data)
    }
}
