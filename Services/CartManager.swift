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
        if let index = items.firstIndex(where: { $0.id == plant.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(plant: plant, quantity: 1))
        }
    }
    
    func decreaseQuantity(plant: PlantSpecies) {
        if let index = items.firstIndex(where: { $0.id == plant.id }) {
            if items[index].quantity > 1 {
                items[index].quantity -= 1
            } else {
                items.remove(at: index)
            }
        }
    }
    
    func removeFromCart(plant: PlantSpecies) {
        items.removeAll(where: { $0.id == plant.id })
    }
    
    func clearCart() {
        items.removeAll()
    }
}
