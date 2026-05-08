import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: CatalogGridView
// ─────────────────────────────────────────────────────────────

struct CatalogGridView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cart: CartManager
    @StateObject private var viewModel = CatalogViewModel()
    @State private var showingCart = false
    @State private var showLimitAlert = false
    @State private var selectedPlant: PlantSpecies?
    @State private var appeared = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private let bg      = Color(hex: "#F5F0E8")
    private let dark    = Color(hex: "#1A2E1A")
    private let accent  = Color(hex: "#4A7C59")

    private let feedbackLight = UIImpactFeedbackGenerator(style: .light)

    var columns: [GridItem] {
        isIpad
            ? [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            // Atmospheric blobs
            GeometryReader { geo in
                Circle()
                    .fill(accent.opacity(0.08))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.5, y: -120)
                    .blur(radius: 80)
                Circle()
                    .fill(Color(hex: "#D4A017").opacity(0.06))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: -80, y: geo.size.height * 0.65)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ──────────────────────────────────────────────
                    headerBar
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: appeared)

                    // ── Editorial hero strip ─────────────────────────────────
                    heroStrip
                        .padding(.horizontal, isIpad ? 40 : 20)
                        .padding(.bottom, 28)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.45).delay(0.08), value: appeared)

                    // ── Recommended – horizontal specimen cards ──────────────
                    if !viewModel.recommendedPlants.isEmpty {
                        recommendedSection
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.45).delay(0.14), value: appeared)
                    }

                    // ── Season filter chips ──────────────────────────────────
                    filterRow
                        .padding(.bottom, isIpad ? 28 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.18), value: appeared)

                    // ── Section label ────────────────────────────────────────
                    HStack {
                        Text("All Specimens".uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(3)
                            .foregroundColor(dark.opacity(0.35))

                        Spacer()

                        Text("\(viewModel.filteredPlants.count) results")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(dark.opacity(0.35))
                    }
                    .padding(.horizontal, isIpad ? 40 : 20)
                    .padding(.bottom, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

                    // ── Grid ─────────────────────────────────────────────────
                    // KEY FIX: removed .offset(y:) from cells — offset shifts
                    // views visually without affecting layout, so during the
                    // entrance animation cards bleed into neighbouring rows.
                    // Opacity-only fade-in is safe and looks just as good.
                    LazyVGrid(columns: columns, spacing: isIpad ? 20 : 16) {
                        ForEach(Array(viewModel.filteredPlants.enumerated()), id: \.element.id) { index, plant in
                            CatalogCell(
                                plant: plant,
                                specimenIndex: index + 1,
                                action: { selectedPlant = plant },
                                onAddLimitReached: { showLimitAlert = true }
                            )
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.4).delay(0.22 + Double(index) * 0.03),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, isIpad ? 40 : 16)
                    .padding(.bottom, 8)

                    Spacer().frame(height: isIpad ? 120 : 100)
                }
            }
            .refreshable { await viewModel.refresh() }
        }
        .sheet(isPresented: $showingCart) { CartView() }
        .sheet(item: $selectedPlant) { plant in
            PlantDetailView(plant: plant)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Cart Limit Reached", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only buy one native plant species at a time. Please remove your current plant from the cart to add a different one.")
        }
        .onAppear {
            withAnimation { appeared = true }
        }
        .accessibilityLabel("Field Guide. Browse and discover native plants.")
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Header bar
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var headerBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Native Catalog".uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(accent.opacity(0.7))

                Text("Field Guide")
                    .font(.system(size: isIpad ? 54 : 42, weight: .heavy))
                    .foregroundColor(dark)
                    .accessibilityAddTraits(.isHeader)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                    Text("\(viewModel.totalCatalogSize)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(dark)
                    Text("spp.")
                        .font(.system(size: 14, weight: .regular))
                        .italic()
                        .foregroundColor(dark.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.7))
                        .overlay(Capsule().stroke(dark.opacity(0.08), lineWidth: 1))
                )
                .accessibilityLabel("\(viewModel.totalCatalogSize) total species")

                Button { showingCart = true } label: {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(dark.opacity(0.08), lineWidth: 1)
                                )
                                .frame(width: isIpad ? 46 : 40, height: isIpad ? 46 : 40)

                            Image(systemName: "bag.fill")
                                .font(.system(size: isIpad ? 24 : 20))
                                .foregroundColor(dark)
                        }

                        if cart.itemCount > 0 {
                            Text("\(cart.itemCount)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.red))
                                .offset(x: 5, y: -5)
                        }
                    }
                }
                .accessibilityLabel("Shopping Cart. \(cart.itemCount) items.")
            }
        }
        .padding(.horizontal, isIpad ? 40 : 20)
        .padding(.top, isIpad ? 50 : 62)
        .padding(.bottom, isIpad ? 28 : 20)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Hero strip
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var heroStrip: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1B4332"), Color(hex: "#2D5A3D")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Canvas { ctx, size in
                let sp: CGFloat = 18; let r: CGFloat = 1.4
                var row: CGFloat = r + 4
                while row < size.height {
                    var col: CGFloat = r + 4
                    while col < size.width {
                        var p = Path(); p.addEllipse(in: CGRect(x: col-r, y: row-r, width: r*2, height: r*2))
                        ctx.fill(p, with: .color(.white.opacity(0.08)))
                        col += sp
                    }
                    row += sp
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityHidden(true)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#7AAF8E"))
                        Text("New arrivals".uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2.5)
                            .foregroundColor(Color(hex: "#7AAF8E"))
                    }

                    Text("This Season's\nSpecimens")
                        .font(.system(size: isIpad ? 30 : 22, weight: .heavy))
                        .foregroundColor(.white)
                        .lineSpacing(2)

                    Text("Freshly catalogued native flora\nready for your garden.")
                        .font(.system(size: isIpad ? 14 : 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.55))
                        .lineSpacing(3)
                }
                .padding(.leading, isIpad ? 32 : 22)
                .padding(.vertical, isIpad ? 32 : 22)

                Spacer()

                if let first = viewModel.recommendedPlants.first {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: isIpad ? 120 : 90)

                        Image(first.illustrationName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: isIpad ? 100 : 76, height: isIpad ? 100 : 76)
                            .clipShape(Circle())
                            .opacity(0.55)
                    }
                    .padding(.trailing, isIpad ? 32 : 20)
                }
            }
        }
        .frame(height: isIpad ? 160 : 110)
        .shadow(color: Color(hex: "#1B4332").opacity(0.25), radius: 16, x: 0, y: 8)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Recommended horizontal cards
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recommended".uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundColor(dark.opacity(0.35))
                Spacer()
            }
            .padding(.horizontal, isIpad ? 40 : 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(viewModel.recommendedPlants.prefix(4).enumerated()), id: \.element.id) { index, plant in
                        RecommendedCard(plant: plant, action: { selectedPlant = plant })
                            .frame(width: isIpad ? 280 : 220, height: isIpad ? 120 : 100)
                            .opacity(appeared ? 1 : 0)
                            .offset(x: appeared ? 0 : 20)
                            // horizontal offset is safe — only shifts left/right,
                            // cannot bleed into vertical neighbours
                            .animation(.easeOut(duration: 0.4).delay(0.15 + Double(index) * 0.06), value: appeared)
                    }
                }
                .padding(.horizontal, isIpad ? 40 : 20)
                .padding(.bottom, 4)
            }
        }
        .padding(.bottom, isIpad ? 32 : 24)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Filter row
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CatalogViewModel.SeasonFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, isIpad ? 40 : 20)
        }
    }

    @ViewBuilder
    private func filterChip(_ filter: CatalogViewModel.SeasonFilter) -> some View {
        let selected = viewModel.selectedFilter == filter
        Button {
            withAnimation(reduceMotion ? .none : .spring(response: 0.3)) {
                viewModel.selectedFilter = filter
                feedbackLight.impactOccurred()
            }
        } label: {
            HStack(spacing: 6) {
                if selected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                }
                Image(systemName: filter.icon)
                    .font(.system(size: isIpad ? 14 : 12, weight: .medium))
                Text(filter.rawValue)
                    .font(.system(size: isIpad ? 15 : 13, weight: selected ? .bold : .medium))
            }
            .foregroundColor(selected ? .white : dark.opacity(0.65))
            .padding(.horizontal, isIpad ? 20 : 16)
            .padding(.vertical, isIpad ? 12 : 10)
            .background(
                Capsule()
                    .fill(selected ? accent : Color.white.opacity(0.7))
                    .overlay(
                        Capsule().stroke(selected ? .clear : dark.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: selected ? accent.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
        .accessibilityLabel("\(filter.rawValue) filter")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: RecommendedCard – horizontal specimen strip
// ─────────────────────────────────────────────────────────────

struct RecommendedCard: View {
    let plant: PlantSpecies
    let action: () -> Void
    @EnvironmentObject var cart: CartManager
    @EnvironmentObject var appState: AppState

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                ZStack {
                    t.accent
                    Circle()
                        .fill(t.patternColor.opacity(0.2))
                        .frame(width: isIpad ? 90 : 70)
                        .offset(x: -8, y: 8)

                    Image(plant.illustrationName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: isIpad ? 72 : 58, height: isIpad ? 72 : 58)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .frame(width: isIpad ? 110 : 86)
                .clipped()

                VStack(alignment: .leading, spacing: 5) {
                    Text(plant.name)
                        .font(.system(size: isIpad ? 17 : 14, weight: .bold))
                        .foregroundColor(t.textColor)
                        .lineLimit(1)

                    Text(plant.scientificName)
                        .font(.system(size: isIpad ? 12 : 10, weight: .regular))
                        .italic()
                        .foregroundColor(t.textColor.opacity(0.5))
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(t.accent)
                        Text(plant.season)
                            .font(.system(size: isIpad ? 11 : 10, weight: .medium))
                            .foregroundColor(t.accent)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)

                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(t.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(t.accent.opacity(0.12), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: t.accent.opacity(0.12), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Recommended: \(plant.name)")
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: CatalogCell – specimen card
// ─────────────────────────────────────────────────────────────

struct CatalogCell: View {
    let plant: PlantSpecies
    let specimenIndex: Int
    let action: () -> Void
    let onAddLimitReached: () -> Void

    @EnvironmentObject var cart: CartManager
    @EnvironmentObject var appState: AppState
    @State private var pressed = false

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var inCart: Bool { cart.items.first?.plant.id == plant.id }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "MXN"; return f
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: isIpad ? 22 : 18, style: .continuous)
                    .fill(t.background)
                    .shadow(color: t.accent.opacity(0.12), radius: pressed ? 4 : 12, x: 0, y: pressed ? 2 : 6)

                // Background dot texture
                GeometryReader { _ in
                    let xs: [CGFloat] = [8, 55, 110, 25, 80, 140, 15, 68, 125]
                    let ys: [CGFloat] = [12, 35, 18,  80, 60, 90, 130, 110, 140]
                    let ds: [CGFloat] = [4,  8,  5,   10, 6,  7,   5,   9,   4]
                    ForEach(0..<min(9, xs.count), id: \.self) { i in
                        Circle()
                            .fill(t.patternColor.opacity(0.12))
                            .frame(width: ds[i], height: ds[i])
                            .offset(x: xs[i], y: ys[i])
                    }
                }
                .clipped()
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    // ── Illustration area ──────────────────────
                    ZStack {
                        // Specimen number top-left
                        HStack {
                            Text(String(format: "№ %02d", specimenIndex))
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(t.accent.opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(t.accent.opacity(0.08)))
                                .padding(10)
                            Spacer()
                        }
                        .frame(maxHeight: .infinity, alignment: .top)

                        // AR button top-right
                        HStack {
                            Spacer()
                            Button {
                                appState.currentScreen = .arPreview(plant)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.85))
                                        .frame(width: isIpad ? 36 : 28, height: isIpad ? 36 : 28)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    Image(systemName: "arkit")
                                        .font(.system(size: isIpad ? 15 : 12, weight: .semibold))
                                        .foregroundColor(t.accent)
                                }
                            }
                            .padding(10)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)

                        // Plant illustration
                        let circleSize: CGFloat = isIpad ? 110.0 : 76.0
                        ZStack {
                            Circle()
                                .fill(t.patternColor.opacity(0.18))
                                .frame(width: circleSize + 14, height: circleSize + 14)
                                .accessibilityHidden(true)
                            Image(plant.illustrationName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: circleSize, height: circleSize)
                                .clipShape(Circle())
                                .shadow(color: t.accent.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 4)
                        .accessibilityLabel("\(plant.name) illustration")
                    }
                    .frame(height: isIpad ? 170 : 118)

                    // Divider
                    Rectangle()
                        .fill(t.accent.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                        .accessibilityHidden(true)

                    // ── Info area — tight fixed padding, no dynamic Spacer ──
                    VStack(alignment: .leading, spacing: 3) {
                        // Season tag
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundColor(t.accent)
                            Text(plant.season.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.8)
                                .foregroundColor(t.accent.opacity(0.7))
                        }
                        .padding(.top, 9)

                        Text(plant.name)
                            .font(.system(size: isIpad ? 20 : 13, weight: .heavy))
                            .foregroundColor(t.textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(plant.scientificName)
                            .font(.system(size: isIpad ? 11 : 9, weight: .regular))
                            .italic()
                            .foregroundColor(t.textColor.opacity(0.45))
                            .lineLimit(1)

                        // Price + add button — top-padded, no Spacer that can grow
                        HStack(alignment: .center) {
                            if let price = plant.price,
                               let str = currencyFormatter.string(from: NSNumber(value: price)) {
                                Text(str)
                                    .font(.system(size: isIpad ? 15 : 12, weight: .bold))
                                    .foregroundColor(t.textColor)
                            }
                            Spacer()
                            Button {
                                if cart.items.isEmpty || inCart {
                                    cart.addToCart(plant: plant)
                                } else {
                                    onAddLimitReached()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(inCart ? t.accent : t.accent.opacity(0.12))
                                        .frame(width: isIpad ? 34 : 28, height: isIpad ? 34 : 28)
                                    Image(systemName: inCart ? "checkmark" : "plus")
                                        .font(.system(size: isIpad ? 13 : 11, weight: .bold))
                                        .foregroundColor(inCart ? .white : t.accent)
                                }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 12)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            // illustration (118) + divider (1) + info section (~111) = 230
            .frame(height: isIpad ? 290 : 230)
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
        .accessibilityLabel("\(plant.name). \(plant.scientificName). \(plant.season).")
        .accessibilityHint("Read field notes and ecological role")
    }
}