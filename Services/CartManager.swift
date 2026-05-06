import Foundation
import SwiftUI

struct CartItem: Identifiable, Equatable {
    var id: String { plant.id }
    let plant: PlantSpecies
    var quantity: Int
}

@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager()
    
    @Published var items: [CartItem] = []
    
    var subtotal: Double {
        items.reduce(0) { total, item in
            total + ((item.plant.price ?? 0) * Double(item.quantity))
        }
    }
    
    var itemCount: Int {
        items.reduce(0) { total, item in
            total + item.quantity
        }
    }
    
    private init() {}
    
    func addToCart(plant: PlantSpecies) {
        items = [CartItem(plant: plant, quantity: 1)]
    }
    
    func decreaseQuantity(plant: PlantSpecies) {
        removeFromCart(plant: plant)
    }
    
    func removeFromCart(plant: PlantSpecies) {
        items.removeAll(where: { $0.id == plant.id })
    }
    
    func clearCart() {
        items.removeAll()
    }
}
