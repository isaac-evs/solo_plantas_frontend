import Foundation
import SwiftUI

struct AuthResponse: Decodable {
    let token: String
    let user: User
}

struct User: Decodable {
    let id: String
    let email: String
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func login(appState: AppState) async {
        isLoading = true
        errorMessage = nil
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "email": email,
                "password": password
            ])
            let response: AuthResponse = try await NetworkManager.shared.request(
                endpoint: "/auth/login",
                method: "POST",
                requiresAuth: false,
                body: body
            )
            KeychainHelper.shared.saveToken(response.token)
            UserDefaults.standard.set(response.user.id, forKey: "currentUserId")
            let isDriver = UserDefaults.standard.bool(forKey: "isDriverMode")
            if isDriver {
                appState.currentScreen = .driverDashboard
            } else {
                appState.plantedDates = PersistenceService.shared.loadGarden()
                appState.switchTab(.home)
                appState.currentScreen = .plantHome
            }
        } catch NetworkError.serverError(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = "A network error occurred."
        }
        isLoading = false
    }
    
    func register(appState: AppState) async {
        isLoading = true
        errorMessage = nil
        do {
            let isDriver = UserDefaults.standard.bool(forKey: "isDriverMode")
            let body = try JSONSerialization.data(withJSONObject: [
                "email": email,
                "password": password,
                "role": isDriver ? "driver" : "user"
            ])
            let response: AuthResponse = try await NetworkManager.shared.request(
                endpoint: "/auth/register",
                method: "POST",
                requiresAuth: false,
                body: body
            )
            KeychainHelper.shared.saveToken(response.token)
            UserDefaults.standard.set(response.user.id, forKey: "currentUserId")
            let isDriver = UserDefaults.standard.bool(forKey: "isDriverMode")
            if isDriver {
                appState.currentScreen = .driverDashboard
            } else {
                appState.plantedDates = PersistenceService.shared.loadGarden()
                appState.switchTab(.home)
                appState.currentScreen = .onboarding
            }
        } catch NetworkError.serverError(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = "A network error occurred."
        }
        isLoading = false
    }
}
