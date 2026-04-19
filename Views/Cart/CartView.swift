import SwiftUI

struct CartView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cart: CartManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F5F0E8").ignoresSafeArea()

                if cart.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 64))
                            .foregroundColor(Color(hex: "#A0998F"))
                        
                        Text("Your Cart is Empty")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "#1A2E1A"))
                        
                        Text("Explore the Field Guide to discover native plants.")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1A2E1A").opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(cart.items) { item in
                                    CartItemRow(item: item)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }

                        // Bottom Total Panel
                        VStack(spacing: 20) {
                            HStack {
                                Text("Subtotal")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(hex: "#1A2E1A").opacity(0.7))
                                Spacer()
                                Text(formatMXN(cart.subtotal))
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color(hex: "#1A2E1A"))
                            }

                            Button {
                                let total = cart.subtotal
                                dismiss() // Dismiss Cart Sheet
                                // Delay slightly to allow sheet drop before pushing new screen
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    appState.currentScreen = .checkout(subtotal: total)
                                }
                            } label: {
                                Text("Proceed to Checkout")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color(hex: "#4A7C59"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color(hex: "#4A7C59").opacity(0.3), radius: 8, y: 4)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 20, y: -10)
                        )
                        .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "#A0998F"))
                            .font(.system(size: 24))
                    }
                }
            }
        }
    }

    private func formatMXN(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value) MXN"
    }
}

// Subview
struct CartItemRow: View {
    @EnvironmentObject var cart: CartManager
    let item: CartItem

    var body: some View {
        HStack(spacing: 16) {
            
            // Image
            ZStack {
                Circle()
                    .fill(Color(hex: "#EAE6DF"))
                    .frame(width: 80, height: 80)
                
                Image(item.plant.illustrationName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.plant.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#1A2E1A"))
                
                if let price = item.plant.price {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencyCode = "MXN"
                    if let str = formatter.string(from: NSNumber(value: price)) {
                        Text(str)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#4A7C59"))
                    }
                }
            }

            Spacer()

            // Quantity Editor
            HStack(spacing: 14) {
                Button(action: { cart.decreaseQuantity(plant: item.plant) }) {
                    Image(systemName: item.quantity == 1 ? "trash" : "minus")
                        .foregroundColor(item.quantity == 1 ? .red : .primary)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#EAE6DF"), in: Circle())
                }

                Text("\(item.quantity)")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 20, alignment: .center)

                Button(action: { cart.addToCart(plant: item.plant) }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#EAE6DF"), in: Circle())
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}
