import SwiftUI

struct DriverDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DriverViewModel()
    @State private var appeared = false
    
    @State private var showVerification = false
    @State private var enteredCode = ""
    @State private var pendingCompletionOrder: BackendOrder? = nil
    @State private var showError = false
    
    private let dark = Color(hex: "#1A2E1A")
    private let accent = Color(hex: "#4A7C59")
    private let bg = Color(hex: "#F5F0E8")
    private let paperBg = Color(hex: "#E8DEC5")
    
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            
            // Atmospheric botanical background
            GeometryReader { geo in
                Circle()
                    .fill(accent.opacity(0.1))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.1)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Botanical Courier".uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .tracking(3)
                            .foregroundColor(accent)
                        
                        Text(viewModel.activeDeliveryId.isEmpty ? "Field Requests" : "Active Mission")
                            .font(.system(size: isIpad ? 48 : 36, weight: .heavy))
                            .foregroundColor(dark)
                    }
                    
                    Spacer()
                    
                    Button {
                        KeychainHelper.shared.deleteToken()
                        UserDefaults.standard.removeObject(forKey: "currentUserId")
                        UserDefaults.standard.set(false, forKey: "isDriverMode")
                        appState.routeAfterSplash()
                    } label: {
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(dark)
                            .padding(14)
                            .background(Circle().fill(Color.white))
                            .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                }
                .padding(.horizontal, isIpad ? 40 : 20)
                .padding(.top, isIpad ? 40 : 20)
                .padding(.bottom, 20)
                
                // Status Strip
                HStack {
                    Image(systemName: viewModel.activeDeliveryId.isEmpty ? "magnifyingglass" : "leaf.fill")
                        .font(.system(size: 20))
                    Text(viewModel.activeDeliveryId.isEmpty ? "AWAITING COURIER" : "IN TRANSIT")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1.5)
                    Spacer()
                    Text("\(viewModel.displayOrders.count) \(viewModel.displayOrders.count == 1 ? "PLANT" : "PLANTS")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(dark)
                        .cornerRadius(6)
                }
                .foregroundColor(dark)
                .padding(20)
                .background(paperBg)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                
                ScrollView {
                    if viewModel.isLoading && viewModel.orders.isEmpty {
                        ProgressView().padding(40)
                    } else if viewModel.displayOrders.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "leaf.arrow.triangle.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(accent.opacity(0.3))
                            Text("NO FIELD REQUESTS")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(dark.opacity(0.4))
                        }
                        .padding(.top, 100)
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 24) {
                            ForEach(viewModel.displayOrders) { order in
                                CourierOrderCard(
                                    order: order,
                                    isActive: !viewModel.activeDeliveryId.isEmpty,
                                    onAccept: {
                                        Task { await viewModel.acceptDelivery(orderId: order.id) }
                                    },
                                    onComplete: {
                                        pendingCompletionOrder = order
                                        enteredCode = ""
                                        showVerification = true
                                    },
                                    onCancel: {
                                        Task { await viewModel.cancelDelivery(orderId: order.id) }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, isIpad ? 40 : 20)
                        .padding(.top, 24)
                        .padding(.bottom, 60)
                    }
                }
                .refreshable {
                    await viewModel.fetchOrders()
                }
            }
        }
        .alert("Verify Handshake", isPresented: $showVerification) {
            TextField("Secret Code (e.g. 7D507340)", text: $enteredCode)
                .textInputAutocapitalization(.characters)
            Button("Verify & Complete", action: {
                if let order = pendingCompletionOrder {
                    if enteredCode.uppercased() == String(order.id.prefix(8)).uppercased() {
                        Task { await viewModel.completeDelivery(orderId: order.id) }
                    } else {
                        showError = true
                    }
                }
            })
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Ask the botanist for the 8-character secret code shown in their Order History to finalize the delivery.")
        }
        .alert("Invalid Code", isPresented: $showError) {
            Button("Try Again", role: .cancel) {
                // Let them try again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showVerification = true
                }
            }
        } message: {
            Text("The secret code did not match. Ensure they are giving you the first 8 characters of their Order ID.")
        }
        .onAppear {
            Task { await viewModel.fetchOrders() }
            withAnimation { appeared = true }
        }
    }
}

struct CourierOrderCard: View {
    let order: BackendOrder
    let isActive: Bool
    let onAccept: () -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    private let dark = Color(hex: "#1A2E1A")
    private let accent = Color(hex: "#4A7C59")
    private let paperBg = Color(hex: "#F9F6F0")
    
    var body: some View {
        VStack(spacing: 0) {
            // "WANTED" Header
            HStack {
                Text(isActive ? "ACTIVE MISSION" : "WANTED")
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .tracking(2)
                    .foregroundColor(dark)
                
                Spacer()
                
                Text("REWARD: $\(String(format: "%.2f", Double(order.totalAmountCents) / 100.0))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accent)
            }
            .padding()
            .background(Color(hex: "#EADDC5"))
            
            // Info
            HStack(spacing: 20) {
                // Stamp/Illustration placeholder
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(accent.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.plant?.name ?? "UNKNOWN SPECIMEN")
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundColor(dark)
                    
                    Text("Requested: \(order.createdAt.prefix(10))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(dark.opacity(0.6))
                        
                    if isActive {
                        Text("Secret Code Required")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.orange)
                            .padding(.top, 4)
                    }
                }
                Spacer()
            }
            .padding(20)
            
            // Action Area
            HStack {
                if isActive {
                    Button(action: onCancel) {
                        Text("ABANDON")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: onComplete) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("VERIFY & COMPLETE")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(accent)
                        .cornerRadius(8)
                        .shadow(color: accent.opacity(0.3), radius: 8, y: 4)
                    }
                } else {
                    Spacer()
                    Button(action: onAccept) {
                        Text("ACCEPT MISSION")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(dark)
                            .cornerRadius(8)
                            .shadow(color: dark.opacity(0.3), radius: 8, y: 4)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .background(paperBg)
        .cornerRadius(16)
        .shadow(color: dark.opacity(0.08), radius: 15, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(dark.opacity(0.05), lineWidth: 1)
        )
    }
}

@MainActor
class DriverViewModel: ObservableObject {
    @Published var orders: [BackendOrder] = []
    @Published var isLoading = false
    @AppStorage("activeDeliveryId") var activeDeliveryId: String = ""
    
    var displayOrders: [BackendOrder] {
        if activeDeliveryId.isEmpty {
            return orders.filter { $0.status == "pending" || $0.status == "confirmed" }
        } else {
            return orders.filter { $0.id == activeDeliveryId }
        }
    }
    
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
    
    func acceptDelivery(orderId: String) async {
        activeDeliveryId = orderId
        await updateStatus(orderId: orderId, status: "out_for_delivery")
    }
    
    func completeDelivery(orderId: String) async {
        await updateStatus(orderId: orderId, status: "delivered")
        activeDeliveryId = ""
    }
    
    func cancelDelivery(orderId: String) async {
        await updateStatus(orderId: orderId, status: "confirmed") // Revert to pool
        activeDeliveryId = ""
    }
    
    private func updateStatus(orderId: String, status: String) async {
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
