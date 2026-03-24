import Foundation

struct PesticideStockDTO: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let productName: String
    let unit: String
    let currentQuantity: Double
    let minThreshold: Double
    let syncStatus: Int

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case productName = "product_name"
        case unit
        case currentQuantity = "current_quantity"
        case minThreshold = "min_threshold"
        case syncStatus = "sync_status"
    }
}

struct PesticideUsageRecordDTO: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let usedQuantity: Double
    let usedAt: String
    let notes: String?
    let stockID: String
    let treatmentID: String?
    let rangerID: String
    let syncStatus: Int

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case usedQuantity = "used_quantity"
        case usedAt = "used_at"
        case notes
        case stockID = "stock_id"
        case treatmentID = "treatment_id"
        case rangerID = "ranger_id"
        case syncStatus = "sync_status"
    }
}

final class PesticideAPIService {
    private let client: SupabaseClient

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    func uploadStock(_ dto: PesticideStockDTO, jwt: String) async throws -> PesticideStockDTO {
        let data = try JSONEncoder().encode(dto)
        let response = try await client.post(path: "pesticide_stocks", jwt: jwt, body: data)
        let decoded = try JSONDecoder().decode([PesticideStockDTO].self, from: response)
        guard let first = decoded.first else { throw SyncError.encodingError }
        return first
    }

    func uploadUsage(_ dto: PesticideUsageRecordDTO, jwt: String) async throws -> PesticideUsageRecordDTO {
        let data = try JSONEncoder().encode(dto)
        let response = try await client.post(path: "pesticide_usage_records", jwt: jwt, body: data)
        let decoded = try JSONDecoder().decode([PesticideUsageRecordDTO].self, from: response)
        guard let first = decoded.first else { throw SyncError.encodingError }
        return first
    }

    func fetchUsage(since: Date, jwt: String) async throws -> [PesticideUsageRecordDTO] {
        let isoDate = since.iso8601String
        let data = try await client.get(
            path: "pesticide_usage_records", jwt: jwt,
            queryItems: [
                URLQueryItem(name: "updated_at", value: "gt.\(isoDate)"),
                URLQueryItem(name: "order", value: "updated_at.asc")
            ]
        )
        return try JSONDecoder().decode([PesticideUsageRecordDTO].self, from: data)
    }
}
