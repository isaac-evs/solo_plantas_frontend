import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F0E8").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {

                
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.isLoading {
                            ProgressView("Loading Orders...")
                                .padding(.top, 40)
                        } else if viewModel.orders.isEmpty {
                            Text("No orders yet.")
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.orders) { order in
                                OrderCardView(order: order)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task { await viewModel.fetchOrders() }
        }
    }
}

// Backend Model
struct BackendOrder: Decodable, Identifiable {
    let id: String
    let status: String
    let totalAmountCents: Int
    let createdAt: String
    let plant: PlantBrief?
}

struct PlantBrief: Decodable {
    let name: String
}

@MainActor
class OrderHistoryViewModel: ObservableObject {
    @Published var orders: [BackendOrder] = []
    @Published var isLoading: Bool = false
    
    func fetchOrders() async {
        isLoading = true
        do {
            let response: [BackendOrder]? = try await NetworkManager.shared.request(
                endpoint: "/orders",
                method: "GET"
            )
            self.orders = response ?? []
        } catch {
            print("Failed to fetch orders: \(error)")
        }
        isLoading = false
    }
}

struct OrderCardView: View {
    let order: BackendOrder
    
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return df
    }()
    
    private let displayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    private var formattedDate: String {
        if let date = formatter.date(from: order.createdAt) {
            return displayFormatter.string(from: date)
        }
        return "Unknown Date"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(order.id.prefix(8).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#1A2E1A"))
                Spacer()
                Text(formattedDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text(order.plant?.name ?? "Unknown Plant")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            // Map backend status to UI status
            let uiStatus: OrderStatus = {
                switch order.status {
                case "pending": return .preparing
                case "confirmed": return .shipped
                case "cancelled": return .preparing // Or add a cancelled state
                default: return .delivered
                }
            }()
            
            OrderTimelineView(currentStatus: uiStatus)
                .padding(.vertical, 8)
                
            HStack {
                Text("Total: $\(String(format: "%.2f", Double(order.totalAmountCents) / 100.0)) MXN")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#4A7C59"))
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

struct OrderTimelineView: View {
    let currentStatus: OrderStatus
    let statuses: [OrderStatus] = [.preparing, .shipped, .outForDelivery, .delivered]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<statuses.count, id: \.self) { index in
                let status = statuses[index]
                let isCompleted = index <= currentStatus.stepIndex
                let isLast = index == statuses.count - 1
                
                VStack {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color(hex: "#4A7C59") : Color(hex: "#EAE6DF"))
                            .frame(width: 24, height: 24)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(status.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isCompleted ? Color(hex: "#1A2E1A") : .secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(index < currentStatus.stepIndex ? Color(hex: "#4A7C59") : Color(hex: "#EAE6DF"))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .offset(y: -14)
                }
            }
        }
    }
}
