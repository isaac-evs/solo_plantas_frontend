import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOrderHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F5F0E8").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // Header
                    HStack {
                        Text("Profile")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(Color(hex: "#1A2E1A"))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // User Info Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Solo Plantas Member")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Member since 2026")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: [Color(hex: "#4A7C59"), Color(hex: "#315A3B")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    // Settings Links
                    VStack(spacing: 0) {
                        ProfileRow(icon: "shippingbox.fill", title: "Order History") {
                            showOrderHistory = true
                        }
                        Divider().padding(.leading, 56)
                        ProfileRow(icon: "map.fill", title: "Saved Addresses") {}
                        Divider().padding(.leading, 56)
                        ProfileRow(icon: "creditcard.fill", title: "Payment Methods") {}
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Logout
                    Button {
                        KeychainHelper.shared.deleteToken()
                        appState.routeAfterSplash()
                    } label: {
                        Text("Log Out")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showOrderHistory) {
                OrderHistoryView()
            }
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#4A7C59"))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1A2E1A"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#A0998F"))
            }
            .padding(20)
            .background(Color.white)
        }
    }
}
