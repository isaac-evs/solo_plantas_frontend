import Foundation

enum OrderStatus: String, CaseIterable, Equatable {
    case preparing = "Preparing"
    case shipped = "Shipped"
    case outForDelivery = "Out for Delivery"
    case delivered = "Delivered"
    
    var stepIndex: Int {
        switch self {
        case .preparing: return 0
        case .shipped: return 1
        case .outForDelivery: return 2
        case .delivered: return 3
        }
    }
}

struct OrderModel: Identifiable, Equatable {
    let id: String
    let date: Date
    let totalAmount: Double
    let items: [String] // Plant names
    let status: OrderStatus
}

// Mock Data
@MainActor
final class OrderService: ObservableObject {
    static let shared = OrderService()
    
    @Published var myOrders: [OrderModel] = [
        OrderModel(id: "ORD-9821A", date: Date().addingTimeInterval(-86400 * 2), totalAmount: 1450.00, items: ["Monstera Deliciosa", "Ceramic Pot"], status: .shipped),
        OrderModel(id: "ORD-3329B", date: Date().addingTimeInterval(-86400 * 10), totalAmount: 800.00, items: ["Ficus Lyrata"], status: .delivered)
    ]
}
