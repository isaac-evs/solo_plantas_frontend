import SwiftUI

struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CheckoutViewModel()
    
    let subtotal: Double
    var shipping: Double { appState.selectedNurseryForPickup == nil ? 99.00 : 0.00 }
    var total: Double { subtotal + shipping }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F5F0E8").ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Order Summary")
                        .font(.system(size: 28, weight: .heavy))
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Subtotal")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatMXN(subtotal))
                        }
                        
                        HStack {
                            Text("Shipping")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(shipping == 0 ? "Free (Pickup)" : formatMXN(shipping))
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(formatMXN(total))
                                .font(.headline)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    
                    if let _ = appState.selectedNurseryForPickup {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#4A7C59"))
                            Text("Local Nursery Pickup Applied!")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#4A7C59"))
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task { await viewModel.confirmPayment(amount: total) }
                    } label: {
                        HStack {
                            if viewModel.isProcessing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Pay with Stripe")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(hex: "#635BFF")) // STRIPE BLURPPLE
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isProcessing || viewModel.checkoutSuccess)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .alert("Payment Successful", isPresented: $viewModel.checkoutSuccess) {
                        Button("OK") { dismiss() }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func formatMXN(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value) MXN"
    }
}

@MainActor
class CheckoutViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var checkoutSuccess: Bool = false
    
    func confirmPayment(amount: Double) async {
        isProcessing = true
        do {
            struct PaymentBody: Encodable { let amount: Double; let currency: String }
            let body = PaymentBody(amount: amount, currency: "mxn")
            
            // Mock Express Intent
            let _: [String: String]? = try? await NetworkManager.shared.request(
                endpoint: "/payments/intent",
                method: "POST",
                body: body
            )
            
            try await Task.sleep(nanoseconds: 1_200_000_000)
            checkoutSuccess = true
        } catch {
            print("Checkout failed")
        }
        isProcessing = false
    }
}
