import Foundation

final class ZoneAPIService {
    private let client: SupabaseClient
    private let path = "infestation_zones"

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    func fetch(since: Date, jwt: String) async throws -> [ZoneSnapshotDTO] {
        let isoDate = since.iso8601String
        let data = try await client.get(
            path: "infestation_zone_snapshots", jwt: jwt,
            queryItems: [
                URLQueryItem(name: "created_at", value: "gt.\(isoDate)"),
                URLQueryItem(name: "order", value: "created_at.asc")
            ]
        )
        return try JSONDecoder().decode([ZoneSnapshotDTO].self, from: data)
    }
}
