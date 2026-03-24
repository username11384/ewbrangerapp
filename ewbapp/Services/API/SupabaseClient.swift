import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

final class SupabaseClient {
    static let shared = SupabaseClient()

    private let baseURL: String
    private let anonKey: String
    private let session: URLSession

    private init() {
        self.baseURL = AppConfig.supabaseURL
        self.anonKey = AppConfig.supabaseAnonKey
        self.session = URLSession.shared
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func refreshToken(_ token: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=refresh_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["refresh_token": token]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    // MARK: - REST helpers

    func get(path: String, jwt: String?, queryItems: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(path)")!
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        applyHeaders(&request, jwt: jwt)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    func post(path: String, jwt: String?, body: Data) async throws -> Data {
        let url = URL(string: "\(baseURL)/rest/v1/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        applyHeaders(&request, jwt: jwt)
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    func patch(path: String, jwt: String?, body: Data, queryItems: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(path)")!
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        applyHeaders(&request, jwt: jwt)
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    func delete(path: String, jwt: String?, queryItems: [URLQueryItem] = []) async throws {
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(path)")!
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        applyHeaders(&request, jwt: jwt)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - Storage

    func uploadPhoto(bucketName: String, path: String, data: Data, contentType: String, jwt: String) async throws {
        let url = URL(string: "\(baseURL)/storage/v1/object/\(bucketName)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        applyHeaders(&request, jwt: jwt)
        request.httpBody = data
        let (_, response) = try await session.data(for: request)
        try validateResponse(response, data: Data())
    }

    // MARK: - Private helpers

    private func applyHeaders(_ request: inout URLRequest, jwt: String?) {
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let jwt = jwt {
            request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        switch httpResponse.statusCode {
        case 200...299: return
        case 409: throw SyncError.conflict(data)
        case 401, 403: throw SyncError.unauthorized
        default: throw SyncError.httpError(httpResponse.statusCode, data)
        }
    }
}

enum SyncError: Error {
    case conflict(Data)
    case unauthorized
    case httpError(Int, Data)
    case encodingError
    case offline
}
