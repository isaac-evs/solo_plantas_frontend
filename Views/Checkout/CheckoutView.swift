import SwiftUI
import StripePaymentSheet

struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cart: CartManager
    @StateObject private var viewModel = CheckoutViewModel()
    
    @State private var streetAddress: String = ""
    @State private var city: String = ""
    @State private var zipCode: String = ""
    
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
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Delivery Address")
                                .font(.headline)
                            
                            TextField("Street Address", text: $streetAddress)
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(10)
                                
                            HStack {
                                TextField("City", text: $city)
                                    .padding()
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(10)
                                    
                                TextField("Zip Code", text: $zipCode)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    Button {
                        guard let plantId = cart.items.first?.plant.id else { return }
                        let shippingType = appState.selectedNurseryForPickup == nil ? "delivery" : "pickup"
                        
                        Task { 
                            await viewModel.preparePaymentSheet(
                                plantId: plantId,
                                shippingType: shippingType,
                                nurseryId: appState.selectedNurseryForPickup,
                                street: streetAddress,
                                city: city,
                                zipCode: zipCode
                            ) 
                        }
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
                    .disabled(viewModel.isProcessing || viewModel.checkoutSuccess || cart.items.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .alert("Payment Successful", isPresented: $viewModel.checkoutSuccess) {
                        Button("OK") { 
                            cart.items.removeAll()
                            dismiss() 
                        }
                    }
                    .background(
                        Group {
                            if let ps = viewModel.paymentSheet {
                                Color.clear
                                    .paymentSheet(
                                        isPresented: $viewModel.showPaymentSheet,
                                        paymentSheet: ps,
                                        onCompletion: viewModel.onPaymentCompletion
                                    )
                            }
                        }
                    )
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
    @Published var paymentSheet: PaymentSheet?
    @Published var showPaymentSheet: Bool = false
    
    struct PaymentBody: Encodable {
        let plantId: String
        let shippingType: String
        let nurseryId: String?
        let address: [String: String]?
    }
    
    struct PaymentResponse: Decodable {
        let clientSecret: String
    }
    
    func preparePaymentSheet(plantId: String, shippingType: String, nurseryId: String?, street: String, city: String, zipCode: String) async {
        isProcessing = true
        
        let addressDict: [String: String]? = shippingType == "delivery" ? [
            "street": street, "city": city, "zipCode": zipCode
        ] : nil
        
        let body = PaymentBody(plantId: plantId, shippingType: shippingType, nurseryId: nurseryId, address: addressDict)
        let bodyData = try? JSONEncoder().encode(body)
        
        do {
            let response: PaymentResponse? = try await NetworkManager.shared.request(
                endpoint: "/payments/intent",
                method: "POST",
                body: bodyData
            )
            
            if let secret = response?.clientSecret {
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Solo Plantas"
                config.allowsDelayedPaymentMethods = true
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
                self.showPaymentSheet = true
            }
        } catch {
            print("Checkout intent failed: \(error)")
        }
        
        isProcessing = false
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        switch result {
        case .completed:
            self.checkoutSuccess = true
        case .canceled:
            print("Payment canceled by user")
        case .failed(let error):
            print("Payment failed: \(error.localizedDescription)")
        }
    }
}
