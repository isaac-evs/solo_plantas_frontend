import SwiftUI

extension BackendOrder {
    var courierRewardCents: Int {
        let shipping = shippingFeeCents ?? 0
        let plantPrice = max(0, totalAmountCents - shipping)
        return shipping + Int(Double(plantPrice) * 0.15)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: DriverDashboardView
// ─────────────────────────────────────────────────────────────

struct DriverDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DriverViewModel()
    @State private var appeared = false

    @State private var showVerification = false
    @State private var enteredCode = ""
    @State private var pendingCompletionOrder: BackendOrder? = nil
    @State private var showError = false
    @State private var showSuccessToast = false

    private let dark    = Color(hex: "#1A2E1A")
    private let accent  = Color(hex: "#4A7C59")
    private let bg      = Color(hex: "#F5F0E8")
    private let gold    = Color(hex: "#C8A800")

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var isMission: Bool { !viewModel.activeDeliveryId.isEmpty }

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            bg.ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(isMission ? gold.opacity(0.12) : accent.opacity(0.10))
                    .frame(width: geo.size.width * 1.0)
                    .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.1)
                    .blur(radius: 70)
                    .animation(.easeInOut(duration: 0.6), value: isMission)

                Circle()
                    .fill(accent.opacity(0.07))
                    .frame(width: geo.size.width * 0.65)
                    .offset(x: -60, y: geo.size.height * 0.65)
                    .blur(radius: 55)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                header
                missionStatusBar
                content
            }
        }
        // ── Success toast ─────────────────────────────────────
        .overlay(alignment: .top) {
            if showSuccessToast {
                successToast
                    .padding(.top, isIpad ? 60 : 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: showSuccessToast)
        // ── Verification alert ────────────────────────────────
        .alert("Verify Handshake", isPresented: $showVerification) {
            TextField("Secret Code (e.g. 7D507340)", text: $enteredCode)
                .textInputAutocapitalization(.characters)
            Button("Verify & Complete") {
                if let order = pendingCompletionOrder {
                    if enteredCode.uppercased() == String(order.id.prefix(8)).uppercased() {
                        Task {
                            await viewModel.completeDelivery(orderId: order.id)
                            showSuccessToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showSuccessToast = false }
                        }
                    } else { showError = true }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Ask the botanist for the 8-character secret code shown in their Order History.")
        }
        .alert("Invalid Code", isPresented: $showError) {
            Button("Try Again", role: .cancel) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showVerification = true }
            }
        } message: {
            Text("The secret code did not match. Ensure they are giving you the first 8 characters of their Order ID.")
        }
        .onAppear {
            Task { await viewModel.fetchOrders() }
            withAnimation { appeared = true }
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Header
    // ─────────────────────────────────────────────────────────

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Botanical Courier".uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundColor(accent.opacity(0.75))

                Text(isMission ? "Active Mission" : "Field Requests")
                    .font(.system(size: isIpad ? 42 : 32, weight: .heavy))
                    .foregroundColor(dark)
                    .animation(.easeInOut(duration: 0.3), value: isMission)
            }

            Spacer()

            // Earnings card
            VStack(alignment: .trailing, spacing: 3) {
                Text("Earnings".uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundColor(dark.opacity(0.4))
                Text("$\(String(format: "%.2f", viewModel.courierEarnings))")
                    .font(.system(size: isIpad ? 22 : 18, weight: .heavy))
                    .foregroundColor(accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(accent.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(.trailing, 10)

            // Log out
            Button {
                KeychainHelper.shared.deleteToken()
                UserDefaults.standard.removeObject(forKey: "currentUserId")
                UserDefaults.standard.set(false, forKey: "isDriverMode")
                appState.routeAfterSplash()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 42, height: 42)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, isIpad ? 40 : 20)
        .padding(.top, isIpad ? 44 : 20)
        .padding(.bottom, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
        .animation(.easeOut(duration: 0.4), value: appeared)
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Mission status bar
    // ─────────────────────────────────────────────────────────

    @ViewBuilder
    private var missionStatusBar: some View {
        HStack(spacing: 12) {
            // Pulse indicator
            ZStack {
                Circle()
                    .fill(isMission ? gold : accent)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill((isMission ? gold : accent).opacity(0.25))
                    .frame(width: 16, height: 16)
            }

            Text(isMission ? "IN TRANSIT" : "AWAITING PICKUP")
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .foregroundColor(dark)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 11))
                    .foregroundColor(dark.opacity(0.6))
                Text("\(viewModel.displayOrders.count) \(viewModel.displayOrders.count == 1 ? "plant" : "plants")")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(dark)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.65))
                    .overlay(Capsule().stroke(dark.opacity(0.08), lineWidth: 1))
            )
        }
        .padding(.horizontal, isIpad ? 40 : 20)
        .padding(.vertical, 14)
        .background(
            Color(hex: "#E8DEC5").opacity(0.8)
                .shadow(.inner(color: .black.opacity(0.04), radius: 2))
        )
        .animation(.easeInOut(duration: 0.4), value: isMission)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.08), value: appeared)
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Main content
    // ─────────────────────────────────────────────────────────

    @ViewBuilder
    private var content: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.isLoading && viewModel.orders.isEmpty {
                loadingState
            } else if viewModel.displayOrders.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: isIpad ? 24 : 18) {
                    ForEach(Array(viewModel.displayOrders.enumerated()), id: \.element.id) { index, order in
                        CourierOrderCard(
                            order: order,
                            isActive: isMission,
                            onAccept:  { Task { await viewModel.acceptDelivery(orderId: order.id) } },
                            onComplete: {
                                pendingCompletionOrder = order
                                enteredCode = ""
                                showVerification = true
                            },
                            onCancel: { Task { await viewModel.cancelDelivery(orderId: order.id) } }
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(0.15 + Double(index) * 0.08), value: appeared)
                    }
                }
                .padding(.horizontal, isIpad ? 40 : 20)
                .padding(.top, 24)
                .padding(.bottom, 60)
            }
        }
        .refreshable { await viewModel.fetchOrders() }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: States
    // ─────────────────────────────────────────────────────────

    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(accent.opacity(0.1)).frame(width: 80, height: 80)
                ProgressView().tint(accent).scaleEffect(1.3)
            }
            Text("Scanning field requests…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(dark.opacity(0.4))
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(accent.opacity(0.08)).frame(width: 110, height: 110)
                Image(systemName: "leaf.arrow.triangle.circlepath")
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(accent.opacity(0.45))
            }
            VStack(spacing: 6) {
                Text("No Field Requests")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(dark)
                Text("All specimens are accounted for.\nCheck back soon.")
                    .font(.system(size: 14))
                    .foregroundColor(dark.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Success toast
    // ─────────────────────────────────────────────────────────

    @ViewBuilder
    private var successToast: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.white)
            }
            Text("Delivery Complete")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(accent)
                .shadow(color: accent.opacity(0.35), radius: 12, y: 6)
        )
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: CourierOrderCard
// ─────────────────────────────────────────────────────────────

struct CourierOrderCard: View {
    let order: BackendOrder
    let isActive: Bool
    let onAccept: () -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void

    private let dark   = Color(hex: "#1A2E1A")
    private let accent = Color(hex: "#4A7C59")
    private let gold   = Color(hex: "#C8A800")

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    // Derive a per-plant theme for color personality
    private var theme: SeedPacketTheme {
        let themes = Array(seedPacketThemes.values)
        let index  = abs(order.id.hashValue) % max(themes.count, 1)
        return themes[index]
    }

    private var rewardFormatted: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "MXN"
        return f.string(from: NSNumber(value: Double(order.courierRewardCents) / 100.0)) ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Top band ──────────────────────────────────────
            ZStack(alignment: .leading) {
                (isActive ? gold : theme.accent)

                Canvas { ctx, size in
                    let sp: CGFloat = 18; let r: CGFloat = 1.4
                    var row: CGFloat = r + 4
                    while row < size.height {
                        var col: CGFloat = r + 4
                        while col < size.width {
                            var p = Path(); p.addEllipse(in: CGRect(x: col-r, y: row-r, width: r*2, height: r*2))
                            ctx.fill(p, with: .color(.white.opacity(0.12)))
                            col += sp
                        }
                        row += sp
                    }
                }
                .accessibilityHidden(true)

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isActive ? "Active Mission".uppercased() : "Available".uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2.5)
                            .foregroundColor(.white.opacity(0.6))
                        Text(order.plant?.name ?? "Unknown Specimen")
                            .font(.system(size: isIpad ? 20 : 17, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Reward badge
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Reward".uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.6))
                        Text(rewardFormatted)
                            .font(.system(size: isIpad ? 18 : 15, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.18))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(height: isIpad ? 80 : 68)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 20
            ))

            // ── Card body ──────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {

                // Plant + meta row
                HStack(spacing: 14) {
                    // Illustration stand-in with theme color
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(theme.accent.opacity(0.12))
                            .frame(width: 54, height: 54)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("#\(order.id.prefix(8).uppercased())")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1)
                            .foregroundColor(dark.opacity(0.35))

                        Text(String(order.createdAt.prefix(10)))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(dark.opacity(0.5))
                    }

                    Spacer()

                    // Status chip
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isActive ? gold : accent)
                            .frame(width: 6, height: 6)
                        Text(isActive ? "In Transit" : "Confirmed")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isActive ? gold : accent)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill((isActive ? gold : accent).opacity(0.1))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                // Address section (active only)
                if isActive {
                    Rectangle()
                        .fill(dark.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    if let address = order.parsedAddress {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(hex: "#E05C00").opacity(0.1))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "location.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "#E05C00"))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delivery Address".uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(dark.opacity(0.35))
                                Text(address.street)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(dark)
                                Text("\(address.city), \(address.zipCode)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(dark.opacity(0.55))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                    } else if order.shippingType == "pickup" {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(theme.accent.opacity(0.1))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "storefront.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.accent)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delivery Method".uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(dark.opacity(0.35))
                                Text("Store Pickup")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(dark)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                    }

                    // Verification hint
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 11))
                            .foregroundColor(gold)
                        Text("Ask the botanist for their 8-character secret code to complete delivery.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(dark.opacity(0.5))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }

                // ── Action area ───────────────────────────────
                Rectangle()
                    .fill(dark.opacity(0.06))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                HStack(spacing: 12) {
                    if isActive {
                        // Abandon
                        Button(action: onCancel) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Abandon")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.red.opacity(0.08))
                            )
                        }

                        Spacer()

                        // Complete
                        Button(action: onComplete) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Verify & Complete")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(accent)
                                    .shadow(color: accent.opacity(0.3), radius: 8, y: 4)
                            )
                        }
                    } else {
                        Spacer()

                        // Accept
                        Button(action: onAccept) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Accept Mission")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [dark, Color(hex: "#2D5A3D")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: dark.opacity(0.25), radius: 10, y: 5)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
            .background(Color.white.opacity(0.85))
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 20,
                bottomTrailingRadius: 20, topTrailingRadius: 0
            ))
        }
        .shadow(color: (isActive ? gold : theme.accent).opacity(0.14), radius: 18, x: 0, y: 8)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: DriverViewModel (unchanged logic)
// ─────────────────────────────────────────────────────────────

@MainActor
class DriverViewModel: ObservableObject {
    @Published var orders: [BackendOrder] = []
    @Published var isLoading = false
    @AppStorage("activeDeliveryId") var activeDeliveryId: String = ""
    @AppStorage("courierEarnings")  var courierEarnings: Double  = 0.0

    var displayOrders: [BackendOrder] {
        activeDeliveryId.isEmpty
            ? orders.filter { $0.status == "confirmed" }
            : orders.filter { $0.id == activeDeliveryId }
    }

    func fetchOrders() async {
        isLoading = true
        do {
            let response: [BackendOrder]? = try await NetworkManager.shared.request(
                endpoint: "/orders/all", method: "GET"
            )
            self.orders = response ?? []
        } catch { print("Failed to fetch all orders: \(error)") }
        isLoading = false
    }

    func acceptDelivery(orderId: String) async {
        activeDeliveryId = orderId
        await updateStatus(orderId: orderId, status: "out_for_delivery")
    }

    func completeDelivery(orderId: String) async {
        await updateStatus(orderId: orderId, status: "delivered")
        if let order = orders.first(where: { $0.id == orderId }) {
            courierEarnings += Double(order.courierRewardCents) / 100.0
        }
        activeDeliveryId = ""
    }

    func cancelDelivery(orderId: String) async {
        await updateStatus(orderId: orderId, status: "confirmed")
        activeDeliveryId = ""
    }

    private func updateStatus(orderId: String, status: String) async {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["status": status])
            let updated: BackendOrder = try await NetworkManager.shared.request(
                endpoint: "/orders/\(orderId)/status", method: "PATCH", body: body
            )
            if let i = orders.firstIndex(where: { $0.id == orderId }) { orders[i] = updated }
        } catch { print("Failed to update status: \(error)") }
    }
}