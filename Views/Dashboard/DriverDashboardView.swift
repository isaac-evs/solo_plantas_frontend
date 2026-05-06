import SwiftUI

struct DriverDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DriverViewModel()
    @State private var appeared = false
    
    private let raceRed = Color(hex: "#FF2A00")
    private let darkGrey = Color(hex: "#1A1A1A")
    private let neonYellow = Color(hex: "#CCFF00")
    
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    var body: some View {
        ZStack {
            darkGrey.ignoresSafeArea()
            
            // F1 Grid pattern background
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 40
                    for x in stride(from: 0, to: geo.size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, to: geo.size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
            }
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GIG ECONOMY // RACE MODE")
                            .font(.system(size: 11, weight: .black))
                            .tracking(4)
                            .foregroundColor(neonYellow)
                        
                        Text("Driver Hub")
                            .font(.system(size: isIpad ? 48 : 38, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .italic()
                    }
                    
                    Spacer()
                    
                    Button {
                        KeychainHelper.shared.deleteToken()
                        UserDefaults.standard.removeObject(forKey: "currentUserId")
                        UserDefaults.standard.set(false, forKey: "isDriverMode")
                        appState.routeAfterSplash()
                    } label: {
                        Image(systemName: "power")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Circle().fill(raceRed))
                    }
                }
                .padding(.horizontal, isIpad ? 40 : 20)
                .padding(.top, isIpad ? 40 : 20)
                .padding(.bottom, 20)
                
                // Wild West Banner
                HStack {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 24))
                    Text("THE WILD WEST POOL")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .italic()
                    Spacer()
                    Text("\(viewModel.orders.count) JOBS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(darkGrey)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(6)
                }
                .foregroundColor(.white)
                .padding(20)
                .background(raceRed)
                .padding(.bottom, 10)
                
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView().colorInvert().padding(40)
                    } else if viewModel.orders.isEmpty {
                        Text("NO ACTIVE JOBS")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 100)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(viewModel.orders) { order in
                                DriverOrderCard(order: order, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, isIpad ? 40 : 20)
                        .padding(.top, 10)
                        .padding(.bottom, 60)
                    }
                }
                .refreshable {
                    await viewModel.fetchOrders()
                }
            }
        }
        .onAppear {
            Task { await viewModel.fetchOrders() }
            withAnimation { appeared = true }
        }
    }
}

struct DriverOrderCard: View {
    let order: BackendOrder
    @ObservedObject var viewModel: DriverViewModel
    
    private let raceRed = Color(hex: "#FF2A00")
    private let neonYellow = Color(hex: "#CCFF00")
    private let statuses = ["pending", "confirmed", "out_for_delivery", "delivered", "cancelled"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(order.id.prefix(8).uppercased())
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(neonYellow)
                
                Spacer()
                
                Text("$\(String(format: "%.2f", Double(order.totalAmountCents) / 100.0))")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            
            // Info
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.plant?.name.uppercased() ?? "UNKNOWN CARGO")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("TIME: \(order.createdAt.prefix(10))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
            }
            .padding()
            
            // Status update
            HStack {
                Text("STATUS:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Menu {
                    ForEach(statuses, id: \.self) { status in
                        Button(status.replacingOccurrences(of: "_", with: " ").uppercased()) {
                            Task { await viewModel.updateStatus(orderId: order.id, status: status) }
                        }
                    }
                } label: {
                    HStack {
                        Text(order.status.replacingOccurrences(of: "_", with: " ").uppercased())
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(neonYellow)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(order.status == "delivered" ? Color.green.opacity(0.3) : raceRed.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6).stroke(order.status == "delivered" ? Color.green : raceRed, lineWidth: 2)
                    )
                    .cornerRadius(6)
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
        }
        .background(Color(hex: "#222222"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

@MainActor
class DriverViewModel: ObservableObject {
    @Published var orders: [BackendOrder] = []
    @Published var isLoading = false
    
    func fetchOrders() async {
        isLoading = true
        do {
            let response: [BackendOrder]? = try await NetworkManager.shared.request(
                endpoint: "/orders/all",
                method: "GET"
            )
            self.orders = response ?? []
        } catch {
            print("Failed to fetch all orders: \(error)")
        }
        isLoading = false
    }
    
    func updateStatus(orderId: String, status: String) async {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["status": status])
            let updatedOrder: BackendOrder = try await NetworkManager.shared.request(
                endpoint: "/orders/\(orderId)/status",
                method: "PATCH",
                body: body
            )
            
            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = updatedOrder
            }
        } catch {
            print("Failed to update status: \(error)")
        }
    }
}
