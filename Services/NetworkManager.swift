import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case unknown
    case invalidResponse
    case statusCode(Int)
}

struct ApiErrorDetail: Decodable {
    let field: String
    let message: String
}

struct ApiErrorResponse: Decodable {
    let success: Bool?
    let error: String?
    let details: [ApiErrorDetail]?
    let message: String?
}

struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
}

final class NetworkManager: Sendable {
    static let shared = NetworkManager()
    private let baseURL = "https://justplantsbackend-cmdtdze0dhavgpbh.canadacentral-01.azurewebsites.net/api/v1"
    
    private var authToken: String? {
        KeychainHelper.shared.getToken()
    }
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }
    
    private func createRequest(for endpoint: String, method: String, requiresAuth: Bool = true, body: Data? = nil) throws -> URLRequest {
        let cleanEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let cleanBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        
        guard let url = URL(string: "\(cleanBase)/\(cleanEndpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            if let token = authToken {
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
        
        print("\n🌐 [NETWORK] Sending \(method) to \(req.url?.absoluteString ?? "")")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [NETWORK] Invalid response cast.")
                throw NetworkError.invalidResponse
            }
            
            print("🌐 [NETWORK] HTTP Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorStr = String(data: data, encoding: .utf8) ?? "None"
                print("❌ [NETWORK] Server Error Body: \(errorStr)")
                
                if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                    if let details = apiError.details, !details.isEmpty {
                        let combined = details.map { $0.message }.joined(separator: "\n")
                        throw NetworkError.serverError(combined)
                    } else if let errMsgs = apiError.error {
                        throw NetworkError.serverError(errMsgs)
                    } else if let msg = apiError.message {
                        throw NetworkError.serverError(msg)
                    }
                }
                throw NetworkError.serverError("Received status code \(httpResponse.statusCode)")
            }
            
            if let strResponse = String(data: data, encoding: .utf8) {
                print("✅ [NETWORK] Payload: \(strResponse)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let wrapper = try? decoder.decode(ApiResponse<T>.self, from: data), let unwrappedData = wrapper.data {
                return unwrappedData
            }
            
            return try decoder.decode(T.self, from: data)
            
            
        } catch let urlError as URLError {
            print("❌ [NETWORK] URLError: \(urlError.localizedDescription) (Code: \(urlError.errorCode))")
            throw urlError
        } catch {
            print("❌ [NETWORK] Generic Error: \(error.localizedDescription)")
            throw error
        }
    }
}
