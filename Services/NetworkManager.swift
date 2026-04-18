import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case unknown
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://localhost:3000/api/v1"
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }
    
    private func createRequest(for endpoint: String, method: String, requiresAuth: Bool = true, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            if let token = KeychainHelper.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    func request<T: Decodable>(endpoint: String, method: String, requiresAuth: Bool = true, body: Data? = nil) async throws -> T {
        let req = try createRequest(for: endpoint, method: method, requiresAuth: requiresAuth, body: body)
        let (data, response) = try await session.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 401:
            KeychainHelper.shared.deleteToken()
            throw NetworkError.unauthorized
        default:
            if let errorMsg = try? JSONDecoder().decode([String: String].self, from: data), let msg = errorMsg["message"] {
                throw NetworkError.serverError(msg)
            }
            throw NetworkError.serverError("Received status code \(httpResponse.statusCode)")
        }
    }
}
