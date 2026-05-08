import SwiftUI
import SafariServices

// ─────────────────────────────────────────────────────────────
// MARK: Holographic Card Effect
// ─────────────────────────────────────────────────────────────

struct HoloCardModifier: ViewModifier {
    @State private var dragOffset: CGSize = .zero
    @State private var isHovered: Bool = false

    private var rotateX: Double { Double(-dragOffset.height / 20).clamped(to: -12...12) }
    private var rotateY: Double { Double(dragOffset.width / 20).clamped(to: -12...12) }
    private var shimmerX: Double { (dragOffset.width + 80) / 160 }
    private var shimmerY: Double { (dragOffset.height + 120) / 240 }

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(rotateX), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(rotateY), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .overlay(
                // Rainbow holographic sheen
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#FF006E").opacity(0.0), location: 0),
                        .init(color: Color(hex: "#8338EC").opacity(0.18), location: shimmerX * 0.3),
                        .init(color: Color(hex: "#3A86FF").opacity(0.22), location: shimmerX * 0.5),
                        .init(color: Color(hex: "#06D6A0").opacity(0.18), location: shimmerX * 0.75),
                        .init(color: Color(hex: "#FFD166").opacity(0.0), location: 1),
                    ],
                    startPoint: UnitPoint(x: shimmerX - 0.4, y: shimmerY - 0.4),
                    endPoint:   UnitPoint(x: shimmerX + 0.4, y: shimmerY + 0.4)
                )
                .blendMode(.screen)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)
            )
            .overlay(
                // Fine diagonal glitter lines
                LinearGradient(
                    colors: [
                        .white.opacity(0.0),
                        .white.opacity(0.07),
                        .white.opacity(0.0),
                        .white.opacity(0.05),
                        .white.opacity(0.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)
            )
            .shadow(color: Color(hex: "#8338EC").opacity(isHovered ? 0.45 : 0.2), radius: isHovered ? 32 : 18, x: rotateY * 2, y: 12)
            .shadow(color: Color(hex: "#3A86FF").opacity(isHovered ? 0.3 : 0.1), radius: 8, x: -rotateY, y: 4)
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: dragOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        dragOffset = v.translation
                        isHovered = true
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            dragOffset = .zero
                            isHovered = false
                        }
                    }
            )
    }
}

extension View {
    func holoCard() -> some View { modifier(HoloCardModifier()) }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Pokémon-Style Plant Card
// ─────────────────────────────────────────────────────────────

struct PokeCardView: View {
    let plant: PlantSpecies
    let theme: SeedPacketTheme

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        ZStack {
            // Card base – rich dark gradient like a holographic Pokémon card
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.95),
                            theme.textColor,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Gold border ring
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FFD700"),
                            Color(hex: "#FFA500"),
                            Color(hex: "#FFD700"),
                            Color(hex: "#B8860B"),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )

            // Inner border
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .padding(5)

            // Card content
            VStack(spacing: 0) {

                // ── TOP BAR ──────────────────────────────────
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(plant.name.uppercased())
                            .font(.system(size: isIpad ? 15 : 11, weight: .black))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "#FFD700"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text("Native Species · \(plant.season)")
                            .font(.system(size: isIpad ? 9 : 7, weight: .semibold))
                            .tracking(1.2)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    // HP badge
                    HStack(spacing: 2) {
                        Text("HP")
                            .font(.system(size: isIpad ? 8 : 6, weight: .black))
                            .foregroundColor(.white.opacity(0.5))
                        Text("100")
                            .font(.system(size: isIpad ? 18 : 13, weight: .black))
                            .foregroundColor(Color(hex: "#FFD700"))
                    }
                }
                .padding(.horizontal, isIpad ? 16 : 12)
                .padding(.top, isIpad ? 14 : 10)
                .padding(.bottom, 8)

                // ── ILLUSTRATION PANEL ───────────────────────
                ZStack {
                    // Panel BG
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.patternColor.opacity(0.35),
                                    theme.accent.opacity(0.2),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(hex: "#FFD700").opacity(0.3), lineWidth: 1)
                        )

                    // Dot texture
                    Canvas { ctx, size in
                        let sp: CGFloat = 12; let r: CGFloat = 1.0
                        var row: CGFloat = sp / 2
                        while row < size.height {
                            var col: CGFloat = sp / 2
                            while col < size.width {
                                var p = Path()
                                p.addEllipse(in: CGRect(x: col-r, y: row-r, width: r*2, height: r*2))
                                ctx.fill(p, with: .color(.white.opacity(0.08)))
                                col += sp
                            }
                            row += sp
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)

                    // Plant image
                    Image(plant.illustrationName)
                        .resizable()
                        .scaledToFit()
                        .padding(isIpad ? 14 : 10)
                        .shadow(color: theme.accent.opacity(0.6), radius: 12, x: 0, y: 6)
                }
                .frame(height: isIpad ? 180 : 130)
                .padding(.horizontal, isIpad ? 16 : 12)

                // ── TYPE BAR ─────────────────────────────────
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: isIpad ? 9 : 7, weight: .bold))
                        .foregroundColor(Color(hex: "#06D6A0"))

                    Text("PLANT")
                        .font(.system(size: isIpad ? 8 : 6, weight: .black))
                        .tracking(2)
                        .foregroundColor(Color(hex: "#06D6A0"))

                    Spacer()

                    Text("NO. \(String(format: "%03d", abs(plant.id.hashValue) % 1000))")
                        .font(.system(size: isIpad ? 8 : 6, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, isIpad ? 16 : 12)
                .padding(.vertical, 6)

                // ── DESCRIPTION BOX ───────────────────────────
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(hex: "#FFD700").opacity(0.2), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: isIpad ? 8 : 5) {
                        // "Ability"
                        HStack(spacing: 6) {
                            Text("🌿")
                                .font(.system(size: isIpad ? 11 : 8))
                            Text("Native Resilience")
                                .font(.system(size: isIpad ? 10 : 7, weight: .black))
                                .tracking(0.5)
                                .foregroundColor(Color(hex: "#FFD700"))
                        }

                        Text(plant.scientificName)
                            .font(.system(size: isIpad ? 9 : 6.5, weight: .regular))
                            .italic()
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // "Attack"
                        HStack(alignment: .top, spacing: isIpad ? 8 : 6) {
                            // Cost dots
                            HStack(spacing: 2) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#06D6A0"), Color(hex: "#3A86FF")],
                                                startPoint: .top, endPoint: .bottom
                                            )
                                        )
                                        .frame(width: isIpad ? 10 : 7, height: isIpad ? 10 : 7)
                                }
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Ecological Growth")
                                    .font(.system(size: isIpad ? 10 : 7, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Thrives in native soil conditions")
                                    .font(.system(size: isIpad ? 8 : 5.5, weight: .regular))
                                    .foregroundColor(.white.opacity(0.45))
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text("60")
                                .font(.system(size: isIpad ? 16 : 11, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(isIpad ? 10 : 8)
                }
                .padding(.horizontal, isIpad ? 16 : 12)

                // ── BOTTOM STRIP ──────────────────────────────
                HStack {
                    Text("Illustrated · Native Series")
                        .font(.system(size: isIpad ? 7 : 5.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))

                    Spacer()

                    // Rarity stars
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < 4 ? "star.fill" : "star")
                                .font(.system(size: isIpad ? 7 : 5))
                                .foregroundColor(Color(hex: "#FFD700").opacity(i < 4 ? 1 : 0.3))
                        }
                    }
                }
                .padding(.horizontal, isIpad ? 16 : 12)
                .padding(.top, 6)
                .padding(.bottom, isIpad ? 14 : 10)
            }
        }
        .holoCard()
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: CheckoutView
// ─────────────────────────────────────────────────────────────

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
                theme.background.ignoresSafeArea()

                GeometryReader { geo in
                    Circle()
                        .fill(theme.patternColor.opacity(0.18))
                        .frame(width: geo.size.width * 1.2)
                        .offset(x: geo.size.width * 0.3, y: -geo.size.width * 0.25)
                        .blur(radius: 80)
                        .allowsHitTesting(false)

                    Circle()
                        .fill(theme.accent.opacity(0.08))
                        .frame(width: geo.size.width * 0.8)
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

                // ── Loading Overlay ──
                if viewModel.isVerifying {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 20) {
                            ProgressView().tint(.white).scaleEffect(1.5)
                            Text("Confirming Payment...")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("Please don't close the app")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .transition(.opacity)
                    .zIndex(20)
                }

                // ── Success Overlay ──
                if viewModel.checkoutSuccess {
                    ZStack {
                        Color.black.opacity(0.7).ignoresSafeArea()
                        VStack(spacing: 32) {
                            ZStack {
                                Circle().fill(theme.accent).frame(width: 100, height: 100)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(spacing: 12) {
                                Text("Order Confirmed!")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("Your botanical companion is being prepared.\nRedirecting you to your garden...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(theme.textColor)
                                .shadow(color: .black.opacity(0.4), radius: 30, y: 15)
                        )
                        .padding(.horizontal, 24)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(21)
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
    // MARK: iPad layout
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var ipadLayout: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {

                // LEFT – dark panel with Pokémon card
                ZStack {
                    theme.accent.ignoresSafeArea()

                    Canvas { ctx, size in
                        let spacing: CGFloat = 28; let dotR: CGFloat = 1.8
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
                            // Collector label
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "#FFD700").opacity(0.7))
                                Text("RARE BOTANICAL CARD".uppercased())
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(3)
                                    .foregroundColor(Color(hex: "#FFD700").opacity(0.7))
                            }
                            .padding(.bottom, 16)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

                            PokeCardView(plant: plant, theme: seedTheme(for: plant.id))
                                .frame(
                                    width: min(geo.size.width * 0.38, 380),
                                    height: min(geo.size.height * 0.72, 580)
                                )
                                .scaleEffect(appeared ? 1.0 : 0.85)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.65, dampingFraction: 0.78), value: appeared)

                            Text("Drag to tilt · Touch to shimmer")
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.top, 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 28)
                }
                .frame(width: geo.size.width * 0.46)

                // RIGHT – checkout form
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        checkoutHeader.padding(.top, 52)
                        stockBadge.padding(.top, 20)
                        methodPicker.padding(.top, 28)
                        deliveryOrPickupForm.padding(.top, 20)
                        totalsCard.padding(.top, 28)
                        errorLabel.padding(.top, 12)
                        payButton.padding(.top, 32).padding(.bottom, 52)
                    }
                    .padding(.horizontal, 40)
                }
                .frame(width: geo.size.width * 0.54)
                .background(theme.background)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: iPhone layout — card flows in scroll, no overlap
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var phoneLayout: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                checkoutHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // ── Pokémon Card Hero ─────────────────────────
                if let plant = cart.items.first?.plant {
                    VStack(spacing: 10) {
                        // Collector label
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#FFD700").opacity(0.8))
                            Text("RARE BOTANICAL CARD")
                                .font(.system(size: 9, weight: .black))
                                .tracking(2.5)
                                .foregroundColor(Color(hex: "#FFD700").opacity(0.8))
                        }
                        .padding(.top, 28)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.35).delay(0.15), value: appeared)

                        // Card — fixed width, flows naturally in VStack
                        PokeCardView(plant: plant, theme: seedTheme(for: plant.id))
                            .frame(width: 240, height: 340)
                            .scaleEffect(appeared ? 1.0 : 0.88)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: appeared)

                        Text("Drag to tilt")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(theme.textColor.opacity(0.3))
                            .padding(.bottom, 8)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.45), value: appeared)
                    }
                    .frame(maxWidth: .infinity)
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
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { shippingType = tag }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(label).font(.system(size: 15, weight: .semibold))
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
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                Text(err).foregroundColor(.red).font(.system(size: 13, weight: .semibold))
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
// MARK: Safari + ViewModel
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

    func pollForConfirmation(orderId: String) async {
        isVerifying = true
        for _ in 0..<15 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            do {
                let orders: [BackendOrder]? = try await NetworkManager.shared.request(endpoint: "/orders", method: "GET")
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
        isVerifying = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { checkoutSuccess = true }
    }
}

struct EmptyResponse: Decodable {}