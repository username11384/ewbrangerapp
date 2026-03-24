import Foundation

final class RangerAPIService {
    private let client: SupabaseClient
    private let path = "ranger_profiles"

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    func upload(_ dto: RangerProfileDTO, jwt: String) async throws -> RangerProfileDTO {
        let data = try JSONEncoder().encode(dto)
        let response = try await client.post(path: path, jwt: jwt, body: data)
        let decoded = try JSONDecoder().decode([RangerProfileDTO].self, from: response)
        guard let first = decoded.first else { throw SyncError.encodingError }
        return first
    }

    func fetch(since: Date, jwt: String) async throws -> [RangerProfileDTO] {
        let isoDate = since.iso8601String
        let data = try await client.get(
            path: path, jwt: jwt,
            queryItems: [
                URLQueryItem(name: "updated_at", value: "gt.\(isoDate)"),
                URLQueryItem(name: "order", value: "updated_at.asc")
            ]
        )
        return try JSONDecoder().decode([RangerProfileDTO].self, from: data)
    }
}
