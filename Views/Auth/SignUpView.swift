import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Create Account")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(white: 0.95))
                    .cornerRadius(12)
                
                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(white: 0.95))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            Button(action: {
                Task {
                    await viewModel.register(appState: appState)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
            .padding(.horizontal, 32)
            
            Button("Already have an account? Login") {
                appState.currentScreen = .login
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.green)
            
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
