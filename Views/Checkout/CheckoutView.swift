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
    @State private var appeared: Bool = false

    let subtotal: Double
    var shipping: Double { shippingType == "delivery" ? 99.00 : 0.0 }
    var total: Double { subtotal + shipping }

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    // Derive theme from the current plant so the whole screen breathes its palette
    private var theme: SeedPacketTheme {
        guard let id = cart.items.first?.plant.id else {
            return SeedPacketTheme(
                background:   Color(hex: "#F5F0E8"),
                accent:       Color(hex: "#4A7C59"),
                textColor:    Color(hex: "#1A2E1A"),
                patternColor: Color(hex: "#7AAF8E")
            )
        }
        return seedTheme(for: id)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // ── Layered background: theme tint + subtle noise texture feel ──
                theme.background.ignoresSafeArea()

                // Decorative large blurred circle – feels like a botanical print wash
                GeometryReader { geo in
                    Circle()
                        .fill(theme.patternColor.opacity(0.18))
                        .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                        .offset(x: geo.size.width * 0.3, y: -geo.size.width * 0.25)
                        .blur(radius: 80)
                        .allowsHitTesting(false)

                    Circle()
                        .fill(theme.accent.opacity(0.08))
                        .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                        .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.55)
                        .blur(radius: 60)
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)

                if isIpad {
                    ipadLayout
                } else {
                    phoneLayout
                }
                
                // ── Success Overlay Animation ──
                if viewModel.checkoutSuccess {
                    Color.black.opacity(0.4).ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(10)
                    
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: "#4A7C59"))
                        
                        Text("Order Confirmed!")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                            
                        Text("Your botanical companion is being prepared.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .background(Color(hex: "#1A2E1A"))
                    .cornerRadius(32)
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(11)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task { await viewModel.fetchNurseries() }
                if let plantId = cart.items.first?.plant.id {
                    Task { await viewModel.fetchStock(plantId: plantId) }
                }
                withAnimation(.easeOut(duration: 0.55).delay(0.1)) { appeared = true }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: iPad – side-by-side, dramatic proportions
    // ─────────────────────────────────────────────────────────────
    @ViewBuilder
    private var ipadLayout: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {

                // LEFT PANEL – dark accent strip with card
                ZStack {
                    theme.accent
                        .ignoresSafeArea()

                    // Subtle dot pattern on dark panel
                    Canvas { ctx, size in
                        let spacing: CGFloat = 28
                        let dotR: CGFloat = 1.8
                        for row in stride(from: spacing / 2, through: size.height, by: spacing) {
                            for col in stride(from: spacing / 2, through: size.width, by: spacing) {
                                var path = Path()
                                path.addEllipse(in: CGRect(x: col - dotR, y: row - dotR, width: dotR * 2, height: dotR * 2))
                                ctx.fill(path, with: .color(.white.opacity(0.12)))
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                    VStack(spacing: 0) {
                        Spacer()

                        if let plant = cart.items.first?.plant {
                            // Oversized card – the hero
                            SeedPacketCard(
                                plant: plant,
                                theme: seedTheme(for: plant.id),
                                screenSize: geo.size
                            )
                            .frame(width: min(geo.size.width * 0.42, 460),
                                   height: min(geo.size.height * 0.72, 640))
                            .shadow(color: .black.opacity(0.28), radius: 48, x: 0, y: 24)
                            .scaleEffect(appeared ? 1.0 : 0.88)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.65, dampingFraction: 0.78), value: appeared)

                            // Small tagline under card
                            Text("One of a kind · Native species")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(3)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 24)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 28)
                }
                .frame(width: geo.size.width * 0.46)

                // RIGHT PANEL – checkout form
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        checkoutHeader
                            .padding(.top, 52)

                        stockBadge
                            .padding(.top, 20)

                        methodPicker
                            .padding(.top, 28)

                        deliveryOrPickupForm
                            .padding(.top, 20)

                        totalsCard
                            .padding(.top, 28)

                        errorLabel
                            .padding(.top, 12)

                        payButton
                            .padding(.top, 32)
                            .padding(.bottom, 52)
                    }
                    .padding(.horizontal, 40)
                }
                .frame(width: geo.size.width * 0.54)
                .background(theme.background)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: iPhone – vertical scroll
    // ─────────────────────────────────────────────────────────────
    @ViewBuilder
    private var phoneLayout: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    checkoutHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // Card hero – full-bleed with accent backdrop
                    if let plant = cart.items.first?.plant {
                        ZStack {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(theme.accent)
                                .padding(.horizontal, 16)
                                .frame(height: geo.size.height * 0.44)

                            SeedPacketCard(
                                plant: plant,
                                theme: seedTheme(for: plant.id),
                                screenSize: geo.size
                            )
                            .frame(
                                width: geo.size.width * 0.74,
                                height: geo.size.height * 0.42
                            )
                            .shadow(color: .black.opacity(0.2), radius: 28, x: 0, y: 14)
                            .scaleEffect(appeared ? 1.0 : 0.9)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)
                        }
                        .padding(.top, 20)
                    }

                    stockBadge
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    methodPicker
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    deliveryOrPickupForm
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    totalsCard
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    errorLabel
                        .padding(.horizontal, 24)
                        .padding(.top, 10)

                    payButton
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Shared sub-views
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var checkoutHeader: some View {
        HStack(alignment: .top) {
            Button {
                appState.switchTab(appState.activeTab)
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("Order Summary")
                    .font(.system(size: isIpad ? 34 : 28, weight: .heavy))
                    .foregroundColor(theme.textColor)

                Text("Complete your botanical purchase")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(theme.textColor.opacity(0.5))
            }

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    @ViewBuilder
    private var stockBadge: some View {
        if let stock = viewModel.availableStock {
            HStack(spacing: 8) {
                Circle()
                    .fill(stock > 0 ? Color(hex: "#4A7C59") : .red)
                    .frame(width: 8, height: 8)

                Text(stock > 0 ? "\(stock) specimens available" : "Currently out of stock")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(stock > 0 ? Color(hex: "#4A7C59") : .red)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill((stock > 0 ? Color(hex: "#4A7C59") : Color.red).opacity(0.1))
            )
        }
    }

    @ViewBuilder
    private var methodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fulfillment".uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.5)
                .foregroundColor(theme.textColor.opacity(0.45))

            HStack(spacing: 10) {
                methodTab(label: "Delivery", icon: "shippingbox.fill", tag: "delivery")
                methodTab(label: "Store Pickup", icon: "storefront.fill", tag: "pickup")
            }
        }
    }

    @ViewBuilder
    private func methodTab(label: String, icon: String, tag: String) -> some View {
        let selected = shippingType == tag
        Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { shippingType = tag } } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(selected ? theme.background : theme.textColor.opacity(0.55))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? theme.accent : theme.accent.opacity(0.07))
            )
        }
    }

    @ViewBuilder
    private var deliveryOrPickupForm: some View {
        if shippingType == "delivery" {
            VStack(alignment: .leading, spacing: 12) {
                formLabel("Delivery Address")

                styledField("Street Address", text: $streetAddress)

                HStack(spacing: 10) {
                    styledField("City", text: $city)
                    styledField("ZIP", text: $zipCode, keyboard: .numberPad)
                        .frame(maxWidth: 110)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .leading)))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                formLabel("Select Nursery")

                Menu {
                    ForEach(viewModel.nurseries) { nursery in
                        Button(nursery.name) { selectedNurseryId = nursery.id }
                    }
                } label: {
                    HStack {
                        Text(viewModel.nurseries.first(where: { $0.id == selectedNurseryId })?.name ?? "Choose a location…")
                            .font(.system(size: 15))
                            .foregroundColor(selectedNurseryId.isEmpty ? theme.textColor.opacity(0.4) : theme.textColor)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    @ViewBuilder
    private var totalsCard: some View {
        VStack(spacing: 0) {
            totalsRow(label: "Subtotal", value: formatMXN(subtotal), secondary: true)
            Divider().padding(.vertical, 12).opacity(0.3)
            totalsRow(
                label: shippingType == "delivery" ? "Shipping" : "Pickup",
                value: shippingType == "delivery" ? formatMXN(shipping) : "FREE",
                secondary: true,
                valueColor: shippingType == "pickup" ? Color(hex: "#4A7C59") : nil
            )
            Divider().padding(.vertical, 12).opacity(0.3)
            totalsRow(label: "Total", value: formatMXN(total), secondary: false)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(theme.accent.opacity(0.12), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func totalsRow(label: String, value: String, secondary: Bool, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: secondary ? 15 : 17, weight: secondary ? .regular : .bold))
                .foregroundColor(secondary ? theme.textColor.opacity(0.6) : theme.textColor)
            Spacer()
            Text(value)
                .font(.system(size: secondary ? 15 : 17, weight: secondary ? .medium : .bold))
                .foregroundColor(valueColor ?? (secondary ? theme.textColor.opacity(0.7) : theme.textColor))
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if let err = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(err)
                    .foregroundColor(.red)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
    }

    @ViewBuilder
    private var payButton: some View {
        let disabled = viewModel.isProcessing
            || viewModel.checkoutSuccess
            || cart.items.isEmpty
            || (shippingType == "delivery" && (streetAddress.trimmingCharacters(in: .whitespaces).isEmpty || city.trimmingCharacters(in: .whitespaces).isEmpty || zipCode.trimmingCharacters(in: .whitespaces).isEmpty))
            || (shippingType == "pickup" && selectedNurseryId.isEmpty)

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
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "#635BFF"))
                    // Shimmer stripe on the button
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.0), .white.opacity(0.08), .white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    )

                HStack(spacing: 12) {
                    if viewModel.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        // Stripe "S" wordmark feel – lock icon
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))

                        Text("Pay with Stripe")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Text(formatMXN(total))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: disabled)
        .fullScreenCover(isPresented: $viewModel.showSafari, onDismiss: {
            if let pendingId = viewModel.pendingOrderId {
                Task {
                    await viewModel.pollForConfirmation(orderId: pendingId)
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    cart.items.removeAll()
                    appState.switchTab(.profile)
                }
            }
        }) {
            if let url = viewModel.checkoutUrl {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private func formLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(2.5)
            .foregroundColor(theme.textColor.opacity(0.45))
    }

    @ViewBuilder
    private func styledField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .font(.system(size: 15))
            .foregroundColor(theme.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
    }

    private func formatMXN(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value) MXN"
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Safari + ViewModel (unchanged from original)
// ─────────────────────────────────────────────────────────────

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
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
    @Published var nurseries: [RemoteNursery] = []
    @Published var isVerifying: Bool = false

    var pendingOrderId: String?

    struct RemoteNursery: Decodable, Identifiable { let id: String; let name: String }
    struct PaymentBody: Encodable { let plantId: String; let shippingType: String; let nurseryId: String?; let address: [String: String]? }
    struct PaymentResponse: Decodable { let url: String; let orderId: String? }
    struct ReserveBody: Encodable { let plantId: String; let quantity: Int }
    struct ReserveResponse: Decodable {}
    struct StockResponse: Decodable { let quantity: Int }

    func fetchNurseries() async {
        do {
            let res: [RemoteNursery] = try await NetworkManager.shared.request(endpoint: "/nurseries", method: "GET", requiresAuth: false)
            self.nurseries = res
        } catch { print("Could not fetch nurseries: \(error)") }
    }

    func fetchStock(plantId: String) async {
        do {
            let response: StockResponse? = try await NetworkManager.shared.request(endpoint: "/inventory/\(plantId)", method: "GET")
            if let qty = response?.quantity { self.availableStock = qty }
        } catch { print("Could not fetch stock: \(error)") }
    }

    func prepareCheckoutSession(plantId: String, shippingType: String, nurseryId: String?, street: String, city: String, zipCode: String) async {
        isProcessing = true
        errorMessage = nil

        let addressDict: [String: String]? = shippingType == "delivery" ? ["street": street, "city": city, "zipCode": zipCode] : nil
        let body = PaymentBody(plantId: plantId, shippingType: shippingType, nurseryId: nurseryId, address: addressDict)
        let bodyData = try? JSONEncoder().encode(body)
        let reserveBody = ReserveBody(plantId: plantId, quantity: 1)
        let reserveData = try? JSONEncoder().encode(reserveBody)

        do {
            let _: ReserveResponse? = try await NetworkManager.shared.request(endpoint: "/cart/reserve", method: "POST", body: reserveData)
            let response: PaymentResponse? = try await NetworkManager.shared.request(endpoint: "/payments/checkout-session", method: "POST", body: bodyData)
            if let urlString = response?.url, let url = URL(string: urlString) {
                self.checkoutUrl = url
                self.pendingOrderId = response?.orderId
                self.showSafari = true
            }
        } catch NetworkError.serverError(let msg) {
            self.errorMessage = msg
        } catch {
            self.errorMessage = "Out of stock or server error."
        }

        isProcessing = false
    }

    /// Polls GET /orders every 2s for up to 30s waiting for the Stripe webhook
    /// to confirm the order. Falls back to showing success after timeout.
    func pollForConfirmation(orderId: String) async {
        isVerifying = true
        for _ in 0..<15 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            do {
                let orders: [BackendOrder]? = try await NetworkManager.shared.request(
                    endpoint: "/orders", method: "GET"
                )
                let paid = (orders ?? []).first {
                    $0.id == orderId &&
                    ["confirmed", "out_for_delivery", "delivered"].contains($0.status)
                }
                if paid != nil {
                    isVerifying = false
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { checkoutSuccess = true }
                    return
                }
            } catch { break }
        }
        // Webhook didn't arrive in 30s — Order History will reflect truth once Stripe fires
        isVerifying = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { checkoutSuccess = true }
    }
}

struct EmptyResponse: Decodable {}