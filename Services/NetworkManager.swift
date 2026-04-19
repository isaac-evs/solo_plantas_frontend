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

final class NetworkManager: Sendable {
    static let shared = NetworkManager()
    private let baseURL = "https://sour-tigers-boil.loca.lt/api/v1"
    
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
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
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
                
                if let errorMsg = try? JSONDecoder().decode([String: String].self, from: data), let msg = errorMsg["message"] {
                    throw NetworkError.serverError(msg)
                }
                throw NetworkError.serverError("Received status code \(httpResponse.statusCode)")
            }
            
            if let strResponse = String(data: data, encoding: .utf8) {
                print("✅ [NETWORK] Payload: \(strResponse)")
            }
            
            return try JSONDecoder().decode(T.self, from: data)
            
        } catch let urlError as URLError {
            print("❌ [NETWORK] URLError: \(urlError.localizedDescription) (Code: \(urlError.errorCode))")
            throw urlError
        } catch {
            print("❌ [NETWORK] Generic Error: \(error.localizedDescription)")
            throw error
        }
    }
}
