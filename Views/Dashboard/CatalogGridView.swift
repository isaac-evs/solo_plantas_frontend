//
//  CatalogGridView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//


import SwiftUI

struct CatalogGridView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cart: CartManager
    @StateObject private var viewModel = CatalogViewModel()
    @State private var showingCart = false
    @State private var selectedPlant: PlantSpecies?

    @Environment(\.accessibilityReduceMotion)       private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private let homeBackground = Color(hex: "#F5F0E8")
    private let homeTextPrimary = Color(hex: "#1A2E1A")
    private let homeAccent = Color(hex: "#4A7C59")
    
    private let feedbackBlocked = UIImpactFeedbackGenerator(style: .heavy)

    var columns: [GridItem] {
        isIpad
            ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)]
            : [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    }

    var body: some View {
        ZStack {
            homeBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack(alignment: .firstTextBaseline) {
                        Text("Field Guide")
                            .font(.system(size: isIpad ? 44 : 34, weight: .bold))
                            .foregroundColor(homeTextPrimary)
                            .accessibilityAddTraits(.isHeader)
                        
                        Spacer()
                        
                        Text("\(viewModel.totalCatalogSize) SPECIES")
                            .font(.system(size: isIpad ? 20 : 16, weight: .bold))
                            .foregroundColor(homeAccent)
                            .padding(.horizontal, isIpad ? 16 : 14)
                            .padding(.vertical, isIpad ? 8 : 6)
                            .background(Capsule().fill(homeAccent.opacity(0.12)))
                            .accessibilityLabel("\(viewModel.totalCatalogSize) total species")
                            
                        Button {
                            showingCart = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: isIpad ? 26 : 22))
                                    .foregroundColor(homeTextPrimary)
                                
                                if cart.itemCount > 0 {
                                    Text("\(cart.itemCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Circle().fill(Color.red))
                                        .offset(x: 8, y: -6)
                                }
                            }
                        }
                        .padding(.leading, 12)
                        .accessibilityLabel("Shopping Cart. \(cart.itemCount) items.")
                    }
                    .padding(.horizontal, isIpad ? 40 : 24)
                    .padding(.top, isIpad ? 50 : 62)
                    .padding(.bottom, isIpad ? 36 : 24)

                    // Banner
                    Text("New Arrivals")
                        .font(.system(size: isIpad ? 20 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#1B4332"))
                        .cornerRadius(12)
                        .padding(.horizontal, isIpad ? 40 : 24)
                        .padding(.bottom, 24)

                    // Recommended Carousel
                    if !viewModel.recommendedPlants.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Plants")
                                .font(.system(size: isIpad ? 24 : 18, weight: .bold))
                                .foregroundColor(homeTextPrimary)
                                .padding(.horizontal, isIpad ? 40 : 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: isIpad ? 24 : 16) {
                                    ForEach(viewModel.recommendedPlants.prefix(3)) { plant in
                                        CatalogCell(plant: plant) {
                                            selectedPlant = plant
                                        }
                                        .frame(width: isIpad ? 300 : 220)
                                    }
                                }
                                .padding(.horizontal, isIpad ? 40 : 24)
                                .padding(.bottom, 12)
                            }
                        }
                    }

                    // Season filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: isIpad ? 12 : 8) {
                            ForEach(CatalogViewModel.SeasonFilter.allCases, id: \.self) { filter in
                                filterChip(filter)
                            }
                        }
                        .padding(.horizontal, isIpad ? 40 : 24)
                    }
                    .padding(.bottom, isIpad ? 32 : 24)

                    // Grid
                    LazyVGrid(columns: columns, spacing: isIpad ? 24 : 14) {
                        ForEach(viewModel.filteredPlants) { plant in
                            CatalogCell(plant: plant) {
                                selectedPlant = plant
                            }
                        }
                    }
                    .padding(.horizontal, isIpad ? 40 : 24)
                    
                    Spacer().frame(height: isIpad ? 120 : 100)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .sheet(isPresented: $showingCart) {
            CartView()
        }
        .sheet(item: $selectedPlant) { plant in
            PlantDetailView(plant: plant)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .accessibilityLabel("Field Guide. Browse and discover native plants.")
    }

    // Filters

    private func filterChip(_ filter: CatalogViewModel.SeasonFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            withAnimation(reduceMotion ? .none : .spring(response: 0.3)) {
                viewModel.selectedFilter = filter
            }
        } label: {
            HStack(spacing: isIpad ? 8 : 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: isIpad ? 17 : 14, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.system(size: isIpad ? 18 : 15, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .white : homeTextPrimary.opacity(0.7))
            .padding(.horizontal, isIpad ? 24 : 18)
            .padding(.vertical, isIpad ? 14 : 12)
            .background(
                Capsule()
                    .fill(isSelected ? homeAccent : Color.white.opacity(0.7))
                    .overlay(Capsule().strokeBorder(isSelected ? .clear : homeAccent.opacity(0.15), lineWidth: 1))
            )
        }
        .accessibilityLabel("\(filter.rawValue) filter")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// Cells
struct CatalogCell: View {
    let plant: PlantSpecies
    let action: () -> Void
    @EnvironmentObject var cart: CartManager

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "MXN"
        return f
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: isIpad ? 24 : 18, style: .continuous)
                    .fill(t.background)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)

                GeometryReader { _ in
                    let xs: [CGFloat] = [10, 60, 120, 30, 90, 150]
                    let ys: [CGFloat] = [15, 40, 20, 90, 70, 100]
                    let ds: [CGFloat] = [5,   9,   6,  12,  7,  8]
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(t.patternColor.opacity(0.13))
                            .frame(width: ds[i], height: ds[i])
                            .offset(x: xs[i], y: ys[i])
                    }
                }
                .clipped()
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    ZStack {
                        let circleSize = isIpad ? 120.0 : 85.0
                        
                        Circle()
                            .fill(t.patternColor.opacity(0.15))
                            .frame(width: circleSize + 14, height: circleSize + 14)
                            .accessibilityHidden(true)
                            
                        Image(plant.illustrationName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: circleSize, height: circleSize)
                            .clipShape(Circle())
                            .shadow(color: t.accent.opacity(0.15), radius: 6, x: 0, y: 3)
                            .accessibilityLabel("\(plant.name) illustration")
                    }
                    .frame(height: isIpad ? 160 : 120)

                    Rectangle()
                        .fill(t.accent.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                        .accessibilityHidden(true)

                    VStack(spacing: isIpad ? 6 : 4) {
                        Text(plant.name)
                            .font(.system(size: isIpad ? 26 : 19, weight: .bold))
                            .foregroundColor(t.textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        if let price = plant.price,
                           let str = currencyFormatter.string(from: NSNumber(value: price)) {
                            Text(str)
                                .font(.system(size: isIpad ? 16 : 14, weight: .semibold))
                                .foregroundColor(t.textColor.opacity(0.8))
                        }
                        
                        HStack(spacing: 4) {
                            Circle().fill(t.accent).frame(width: isIpad ? 8 : 6, height: isIpad ? 8 : 6)
                                .accessibilityHidden(true)
                            Text("NATIVE SPECIES")
                                .font(.system(size: isIpad ? 12 : 9, weight: .bold))
                                .tracking(2)
                                .foregroundColor(t.accent)
                        }
                    }
                    .padding(.vertical, isIpad ? 18 : 14)
                    .padding(.horizontal, 10)
                }
                
                // Add to Cart Overlay
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            cart.addToCart(plant: plant)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: isIpad ? 36 : 28))
                                .foregroundColor(t.accent)
                                .background(Circle().fill(Color.white))
                        }
                        .padding(isIpad ? 16 : 12)
                    }
                    Spacer()
                }
            }
            .frame(height: isIpad ? 260 : 190)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(plant.name). Native Species.")
        .accessibilityHint("Read field notes and ecological role")
    }
}
