import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: OrderHistoryView
// ─────────────────────────────────────────────────────────────

struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false

    private let bg     = Color(hex: "#F5F0E8")
    private let dark   = Color(hex: "#1A2E1A")
    private let accent = Color(hex: "#4A7C59")

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            // Atmospheric blobs
            GeometryReader { geo in
                Circle()
                    .fill(accent.opacity(0.09))
                    .frame(width: geo.size.width * 0.85)
                    .offset(x: geo.size.width * 0.45, y: -100)
                    .blur(radius: 70)
                Circle()
                    .fill(Color(hex: "#C8A800").opacity(0.06))
                    .frame(width: geo.size.width * 0.65)
                    .offset(x: -60, y: geo.size.height * 0.6)
                    .blur(radius: 55)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // ── Custom nav header ──────────────────────────
                header

                // ── Content ────────────────────────────────────
                if viewModel.isLoading {
                    Spacer()
                    loadingState
                    Spacer()
                } else if viewModel.orders.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: isIpad ? 20 : 16) {
                            ForEach(viewModel.orders.filter { 
                                let s = $0.status.lowercased()
                                return s != "cancelled" && s != "canceled" 
                            }) { order in
                                OrderCardView(order: order, viewModel: viewModel)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity.combined(with: .scale(scale: 0.9))
                                    ))
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 18)
                            }
                        }
                        .padding(.horizontal, isIpad ? 40 : 20)
                        .padding(.top, 8)
                        .padding(.bottom, 48)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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
        HStack(alignment: .bottom, spacing: 0) {
            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(accent)
                }
            }
            .padding(.trailing, 14)

            VStack(alignment: .leading, spacing: 3) {
                Text("Your Orders".uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .tracking(3)
                    .foregroundColor(accent.opacity(0.65))

                Text("Order History")
                    .font(.system(size: isIpad ? 34 : 28, weight: .heavy))
                    .foregroundColor(dark)
            }

            Spacer()

            // Order count badge
            if !viewModel.orders.isEmpty {
                Text("\(viewModel.orders.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(dark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.7))
                            .overlay(Capsule().stroke(dark.opacity(0.08), lineWidth: 1))
                    )
            }
        }
        .padding(.horizontal, isIpad ? 40 : 20)
        .padding(.top, isIpad ? 40 : 16)
        .padding(.bottom, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -6)
        .animation(.easeOut(duration: 0.4), value: appeared)
    }

    // ─────────────────────────────────────────────────────────
    // MARK: States
    // ─────────────────────────────────────────────────────────

    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(accent.opacity(0.1)).frame(width: 72, height: 72)
                ProgressView().tint(accent).scaleEffect(1.2)
            }
            Text("Fetching your specimens…")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(dark.opacity(0.45))
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(accent.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: "shippingbox")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(accent.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text("No orders yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(dark)
                Text("Your botanical purchases will appear here.")
                    .font(.system(size: 14))
                    .foregroundColor(dark.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: OrderCardView
// ─────────────────────────────────────────────────────────────

struct OrderCardView: View {
    let order: BackendOrder
    @ObservedObject var viewModel: OrderHistoryViewModel

    @State private var showCancelAlert = false
    @State private var cancelAlertTitle = ""
    @State private var cancelAlertMessage = ""
    @State private var cancelIsDestructive = false

    private let dark   = Color(hex: "#1A2E1A")
    private let accent = Color(hex: "#4A7C59")
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    // Pull a consistent per-plant theme so each card has its own color
    private var theme: SeedPacketTheme {
        // Derive a deterministic theme from the order id's first character
        let themes = Array(seedPacketThemes.values)
        let index  = abs(order.id.hashValue) % max(themes.count, 1)
        return themes[index]
    }

    private var uiStatus: OrderStatus {
        switch order.status {
        case "pending":           return .preparing
        case "confirmed":         return .confirmed
        case "out_for_delivery":  return .outForDelivery
        default:                  return .delivered
        }
    }

    private var formattedDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let display = DateFormatter()
        display.dateStyle = .medium
        if let d = parser.date(from: order.createdAt) { return display.string(from: d) }
        return "Unknown date"
    }

    private var formattedTotal: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "MXN"
        return f.string(from: NSNumber(value: Double(order.totalAmountCents) / 100.0)) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Colored top band ──────────────────────────────
            ZStack(alignment: .leading) {
                theme.accent

                // Dot texture
                Canvas { ctx, size in
                    let sp: CGFloat = 18; let r: CGFloat = 1.4
                    var row: CGFloat = r + 4
                    while row < size.height {
                        var col: CGFloat = r + 4
                        while col < size.width {
                            var p = Path()
                            p.addEllipse(in: CGRect(x: col-r, y: row-r, width: r*2, height: r*2))
                            ctx.fill(p, with: .color(.white.opacity(0.12)))
                            col += sp
                        }
                        row += sp
                    }
                }
                .accessibilityHidden(true)

                HStack(alignment: .center, spacing: 14) {
                    // Order number capsule
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Order".uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.55))

                        Text("#\(order.id.prefix(8).uppercased())")
                            .font(.system(size: isIpad ? 18 : 15, weight: .heavy))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Status pill
                    statusPill(for: uiStatus)

                    // Date
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedDate)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
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
            VStack(alignment: .leading, spacing: 16) {

                // Plant name row
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(theme.accent.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.plant?.name ?? "Unknown Specimen")
                            .font(.system(size: isIpad ? 18 : 16, weight: .bold))
                            .foregroundColor(dark)
                        Text("Native species · Single specimen")
                            .font(.system(size: 12))
                            .foregroundColor(dark.opacity(0.4))
                    }

                    Spacer()

                    Text(formattedTotal)
                        .font(.system(size: isIpad ? 17 : 15, weight: .heavy))
                        .foregroundColor(theme.accent)
                }

                // Divider
                Rectangle()
                    .fill(dark.opacity(0.06))
                    .frame(height: 1)

                // Timeline
                OrderTimelineView(currentStatus: uiStatus, theme: theme)

                // Cancel button (status-conditional)
                cancelButton
            }
            .padding(20)
            .background(Color.white.opacity(0.85))
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 20,
                bottomTrailingRadius: 20, topTrailingRadius: 0
            ))
        }
        .shadow(color: theme.accent.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    // MARK: Cancel

    @ViewBuilder
    private var cancelButton: some View {
        switch uiStatus {
        case .delivered, .preparing where order.status == "cancelled":
            EmptyView()
        case .outForDelivery:
            Button {
                cancelAlertTitle   = "Can't Cancel"
                cancelAlertMessage = "Your order is already on its way. Please contact us once it arrives if there\'s an issue."
                cancelIsDestructive = false
                showCancelAlert = true
            } label: {
                Label("Cannot Cancel", systemImage: "xmark.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.gray.opacity(0.1)))
            }
            .alert(cancelAlertTitle, isPresented: $showCancelAlert) {
                Button("OK", role: .cancel) {}
            } message: { Text(cancelAlertMessage) }

        case .confirmed:
            Button {
                cancelAlertTitle    = "Cancel & Refund"
                cancelAlertMessage  = "Your payment will be refunded within 5–10 business days to your original payment method. Proceed?"
                cancelIsDestructive = true
                showCancelAlert = true
            } label: {
                Label("Cancel Order", systemImage: "arrow.uturn.backward.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#C0392B"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: "#C0392B").opacity(0.10)))
            }
            .alert(cancelAlertTitle, isPresented: $showCancelAlert) {
                Button("Cancel Order", role: .destructive) {
                    Task { await viewModel.cancelOrder(id: order.id) }
                }
                Button("Keep Order", role: .cancel) {}
            } message: { Text(cancelAlertMessage) }

        case .preparing:
            Button {
                cancelAlertTitle    = "Cancel Order"
                cancelAlertMessage  = "Are you sure you want to cancel this order?"
                cancelIsDestructive = true
                showCancelAlert = true
            } label: {
                Label("Cancel Order", systemImage: "xmark.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#C0392B"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: "#C0392B").opacity(0.10)))
            }
            .alert(cancelAlertTitle, isPresented: $showCancelAlert) {
                Button("Cancel Order", role: .destructive) {
                    Task { await viewModel.cancelOrder(id: order.id) }
                }
                Button("Keep Order", role: .cancel) {}
            } message: { Text(cancelAlertMessage) }
        }
    }

    @ViewBuilder
    private func statusPill(for status: OrderStatus) -> some View {
        let (label, color) = statusMeta(status)
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.15)))
    }

    private func statusMeta(_ status: OrderStatus) -> (String, Color) {
        switch status {
        case .preparing:       return ("Preparing",       Color(hex: "#C8A800"))
        case .confirmed:         return ("Confirmed",          Color(hex: "#4A7C59"))
        case .outForDelivery:  return ("Out for Delivery", Color(hex: "#E05C00"))
        case .delivered:       return ("Delivered",        Color(hex: "#4A7C59"))
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: OrderTimelineView
// ─────────────────────────────────────────────────────────────

struct OrderTimelineView: View {
    let currentStatus: OrderStatus
    let theme: SeedPacketTheme

    private let statuses: [OrderStatus] = [.preparing, .confirmed, .outForDelivery, .delivered]

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<statuses.count, id: \.self) { index in
                let status   = statuses[index]
                let isDone   = index <= currentStatus.stepIndex
                let isCurrent = index == currentStatus.stepIndex
                let isLast   = index == statuses.count - 1

                VStack(spacing: 6) {
                    // Node
                    ZStack {
                        Circle()
                            .fill(isDone ? theme.accent : Color(hex: "#EAE6DF"))
                            .frame(width: isIpad ? 28 : 22, height: isIpad ? 28 : 22)

                        if isCurrent {
                            Circle()
                                .stroke(theme.accent.opacity(0.3), lineWidth: 3)
                                .frame(width: isIpad ? 36 : 30, height: isIpad ? 36 : 30)
                        }

                        if isDone {
                            Image(systemName: isCurrent ? "circle.fill" : "checkmark")
                                .font(.system(size: isCurrent ? 8 : (isIpad ? 12 : 10), weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: isIpad ? 38 : 32, height: isIpad ? 38 : 32)

                    // Label
                    Text(status.rawValue)
                        .font(.system(size: isIpad ? 14 : 12, weight: isCurrent ? .bold : .medium))
                        .foregroundColor(isDone ? theme.accent : Color(hex: "#1A2E1A").opacity(0.35))
                        .multilineTextAlignment(.center)
                        .frame(width: isIpad ? 72 : 58)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Connector line
                if !isLast {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "#EAE6DF"))
                            .frame(height: 3)

                        // Filled portion
                        if index < currentStatus.stepIndex {
                            Capsule()
                                .fill(theme.accent)
                                .frame(height: 3)
                        } else if index == currentStatus.stepIndex {
                            // Half-filled for current
                            GeometryReader { geo in
                                Capsule()
                                    .fill(theme.accent)
                                    .frame(width: geo.size.width * 0.5, height: 3)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: -(isIpad ? 19 : 15))
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: UnevenRoundedRectangle helper (iOS 16 backport)
// ─────────────────────────────────────────────────────────────

struct UnevenRoundedRectangle: Shape {
    var topLeadingRadius: CGFloat = 0
    var bottomLeadingRadius: CGFloat = 0
    var bottomTrailingRadius: CGFloat = 0
    var topTrailingRadius: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = topLeadingRadius, tr = topTrailingRadius
        let bl = bottomLeadingRadius, br = bottomTrailingRadius

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                    radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                    radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                    radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                    radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Backend models + ViewModel (unchanged logic)
// ─────────────────────────────────────────────────────────────

struct BackendOrder: Decodable, Identifiable {
    let id: String
    let status: String
    let totalAmountCents: Int
    let shippingFeeCents: Int?
    let shippingType: String?
    let shippingAddress: String?
    let createdAt: String
    let plant: PlantBrief?
}

struct ShippingAddress: Decodable {
    let street: String
    let city: String
    let zipCode: String
}

extension BackendOrder {
    var parsedAddress: ShippingAddress? {
        guard let json = shippingAddress?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ShippingAddress.self, from: json)
    }
}

struct PlantBrief: Decodable {
    let name: String
}

@MainActor
class OrderHistoryViewModel: ObservableObject {
    @Published var orders: [BackendOrder] = []
    @Published var isLoading: Bool = false

    func fetchOrders() async {
        isLoading = true
        do {
            let response: [BackendOrder]? = try await NetworkManager.shared.request(
                endpoint: "/orders", method: "GET"
            )
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.orders = response ?? []
            }
        } catch {
            print("Failed to fetch orders: \(error)")
        }
        withAnimation { isLoading = false }
    }

    func cancelOrder(id: String) async {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["status": "cancelled"])
            let _: BackendOrder? = try await NetworkManager.shared.request(
                endpoint: "/orders/\(id)/status",
                method: "PATCH",
                body: body
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Refresh the list so the cancelled status is reflected
            await fetchOrders()
        } catch {
            print("Failed to cancel order: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}