import SwiftUI
import SafariServices

struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cart: CartManager
    @StateObject private var viewModel = CheckoutViewModel()
    
    @State private var streetAddress: String = ""
    @State private var city: String = ""
    @State private var zipCode: String = ""
    @State private var shippingType: String = "delivery"
    @State private var selectedNurseryId: String = ""
    
    let subtotal: Double
    var shipping: Double { 99.00 }
    var total: Double { subtotal + shipping }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F5F0E8").ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    HStack {
                        Button {
                            appState.switchTab(appState.activeTab)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(hex: "#1A2E1A"))
                        }
                        .padding(.trailing, 8)
                        
                        Text("Order Summary")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(Color(hex: "#1A2E1A"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    if let plant = cart.items.first?.plant {
                        HStack(alignment: .top, spacing: 32) {
                            
                            // LEFT SIDE: SeedPacketCard
                            ZStack {
                                SeedPacketCard(
                                    plant: plant,
                                    theme: seedTheme(for: plant.id),
                                    screenSize: UIScreen.main.bounds.size
                                )
                                .scaleEffect(0.5)
                            }
                            .frame(width: 180, height: 260)
                            
                            // RIGHT SIDE: Forms & Totals
                            VStack(alignment: .leading, spacing: 20) {
                                // Stock Indicator
                                if let stock = viewModel.availableStock {
                                    HStack {
                                        Image(systemName: stock > 0 ? "checkmark.seal.fill" : "xmark.octagon.fill")
                                        Text(stock > 0 ? "\(stock) in stock" : "Out of stock")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(stock > 0 ? Color(hex: "#4A7C59") : .red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background((stock > 0 ? Color(hex: "#4A7C59") : Color.red).opacity(0.1))
                                    .cornerRadius(8)
                                }
                                // Toggle for Shipping Type
                                Picker("Delivery Method", selection: $shippingType) {
                                    Text("Delivery").tag("delivery")
                                    Text("Store Pickup").tag("pickup")
                                }
                                .pickerStyle(SegmentedPickerStyle())

                                if shippingType == "delivery" {
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
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Select Nursery")
                                            .font(.headline)
                                        
                                        Picker("Nursery", selection: $selectedNurseryId) {
                                            Text("Select a nursery").tag("")
                                            ForEach(DataService.shared.localNurseries) { nursery in
                                                Text(nursery.name).tag(nursery.id.uuidString)
                                            }
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.05))
                                        .cornerRadius(10)
                                    }
                                }
                                
                                // Totals
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
                                        Text(formatMXN(shipping))
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
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    if let err = viewModel.errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 24)
                    }
                    
                    Button {
                        guard let plantId = cart.items.first?.plant.id else { return }
                        
                        Task { 
                            await viewModel.prepareCheckoutSession(
                                plantId: plantId,
                                shippingType: shippingType,
                                nurseryId: shippingType == "pickup" ? selectedNurseryId : nil,
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
                    .disabled(
                        viewModel.isProcessing || 
                        viewModel.checkoutSuccess || 
                        cart.items.isEmpty || 
                        (shippingType == "delivery" && (streetAddress.trimmingCharacters(in: .whitespaces).isEmpty || city.trimmingCharacters(in: .whitespaces).isEmpty || zipCode.trimmingCharacters(in: .whitespaces).isEmpty)) ||
                        (shippingType == "pickup" && selectedNurseryId.isEmpty)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .sheet(isPresented: $viewModel.showSafari, onDismiss: {
                        cart.items.removeAll()
                        dismiss()
                    }) {
                        if let url = viewModel.checkoutUrl {
                            SafariView(url: url)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let plantId = cart.items.first?.plant.id {
                    Task { await viewModel.fetchStock(plantId: plantId) }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func formatMXN(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value) MXN"
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

@MainActor
class CheckoutViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var checkoutSuccess: Bool = false
    @Published var checkoutUrl: URL?
    @Published var showSafari: Bool = false
    @Published var errorMessage: String?
    @Published var availableStock: Int?
    
    struct PaymentBody: Encodable {
        let plantId: String
        let shippingType: String
        let nurseryId: String?
        let address: [String: String]?
    }
    
    struct PaymentResponse: Decodable {
        let url: String
    }
    
    struct ReserveBody: Encodable {
        let plantId: String
        let quantity: Int
    }
    
    struct ReserveResponse: Decodable {}
    
    struct StockResponse: Decodable {
        let quantity: Int
    }
    
    func fetchStock(plantId: String) async {
        do {
            let response: StockResponse? = try await NetworkManager.shared.request(
                endpoint: "/inventory/\(plantId)",
                method: "GET"
            )
            if let qty = response?.quantity {
                self.availableStock = qty
            }
        } catch {
            print("Could not fetch stock: \(error)")
        }
    }
    
    func prepareCheckoutSession(plantId: String, shippingType: String, nurseryId: String?, street: String, city: String, zipCode: String) async {
        isProcessing = true
        errorMessage = nil
        
        let addressDict: [String: String]? = shippingType == "delivery" ? [
            "street": street, "city": city, "zipCode": zipCode
        ] : nil
        
        let body = PaymentBody(plantId: plantId, shippingType: shippingType, nurseryId: nurseryId, address: addressDict)
        let bodyData = try? JSONEncoder().encode(body)
        
        let reserveBody = ReserveBody(plantId: plantId, quantity: 1)
        let reserveData = try? JSONEncoder().encode(reserveBody)
        
        do {
            // 1. Automatically reserve inventory to satisfy Stripe Backend validation
            let _: ReserveResponse? = try await NetworkManager.shared.request(
                endpoint: "/cart/reserve",
                method: "POST",
                body: reserveData
            )
            
            // 2. Generate Stripe Session
            let response: PaymentResponse? = try await NetworkManager.shared.request(
                endpoint: "/payments/checkout-session",
                method: "POST",
                body: bodyData
            )
            
            if let urlString = response?.url, let url = URL(string: urlString) {
                self.checkoutUrl = url
                self.showSafari = true
            }
        } catch NetworkError.serverError(let msg) {
            self.errorMessage = msg
        } catch {
            self.errorMessage = "Out of stock or server error."
        }
        
        isProcessing = false
    }
}
