import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cart: CartManager
    @State private var showOrderHistory = false
    @State private var randomUsername = ["HappyRadish", "AngryTomato", "SleepyCactus", "BraveAgave", "MysticFern", "ZenBonsai", "CosmicMonstera", "WildOrchid", "ChubbySucculent", "NeonPothos"].randomElement() ?? "HappyRadish"
    @State private var activeOrdersCount: Int = 0
    
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
                    HStack(spacing: 20) {
                        Image("cempasuchil")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(randomUsername)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Text("Seeds Planted")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("\(appState.plantedDates.count)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Active Orders")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("\(activeOrdersCount)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
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
                        NavigationLink(destination: OrderHistoryView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#4A7C59"))
                                    .frame(width: 24)
                                
                                Text("Order History")
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
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button {
                KeychainHelper.shared.deleteToken()
                cart.items.removeAll()
                appState.plantedDates.removeAll()
                appState.routeAfterSplash()
            } label: {
                Text("Log Out")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(20)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Task { await fetchActiveOrders() }
        }
    }
    
    private func fetchActiveOrders() async {
        do {
            struct BriefOrder: Decodable { let status: String }
            let response: [BriefOrder]? = try await NetworkManager.shared.request(endpoint: "/orders", method: "GET")
            if let orders = response {
                activeOrdersCount = orders.filter { $0.status == "pending" }.count
            }
        } catch {
            print("Failed to fetch active orders count: \(error)")
        }
    }
}
