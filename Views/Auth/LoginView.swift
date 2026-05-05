import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Welcome Back")
                .font(.system(size: isIpad ? 48 : 34, weight: .bold))
                .foregroundColor(Color(hex: "#1A2E1A"))
            
            VStack(spacing: 20) {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .font(.system(size: isIpad ? 22 : 16))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                
                SecureField("Password", text: $viewModel.password)
                    .font(.system(size: isIpad ? 22 : 16))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
            }
            .padding(.horizontal, isIpad ? 64 : 32)
            .frame(maxWidth: isIpad ? 600 : .infinity)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: isIpad ? 18 : 14))
            }
            
            Button(action: {
                Task {
                    await viewModel.login(appState: appState)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                        .font(.system(size: isIpad ? 22 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#4A7C59"))
                        .cornerRadius(12)
                        .shadow(color: Color(hex: "#4A7C59").opacity(0.4), radius: 8, y: 4)
                }
            }
            .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
            .padding(.horizontal, isIpad ? 64 : 32)
            .frame(maxWidth: isIpad ? 600 : .infinity)
            
            Button("Don't have an account? Sign Up") {
                appState.currentScreen = .signUp
            }
            .font(.system(size: isIpad ? 20 : 16, weight: .medium))
            .foregroundColor(Color(hex: "#4A7C59"))
            
            Spacer()
        }
        .background(Color(hex: "#F5F0E8").ignoresSafeArea())
    }
}
