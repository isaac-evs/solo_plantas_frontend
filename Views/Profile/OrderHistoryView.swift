import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var service = OrderService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F0E8").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {

                
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(service.myOrders) { order in
                            OrderCardView(order: order)
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
    }
}

struct OrderCardView: View {
    let order: OrderModel
    
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(order.id)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#1A2E1A"))
                Spacer()
                Text(formatter.string(from: order.date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text(order.items.joined(separator: ", "))
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            OrderTimelineView(currentStatus: order.status)
                .padding(.vertical, 8)
                
            HStack {
                Text("Total: $\(String(format: "%.2f", order.totalAmount)) MXN")
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
