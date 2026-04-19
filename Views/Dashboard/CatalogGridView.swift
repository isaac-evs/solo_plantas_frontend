//
//  CatalogGridView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//


import SwiftUI

struct CatalogGridView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CatalogViewModel()

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
                        
                        Text("\(appState.plantedDates.count)/\(viewModel.totalCatalogSize)")
                            .font(.system(size: isIpad ? 20 : 16, weight: .bold))
                            .foregroundColor(homeAccent)
                            .padding(.horizontal, isIpad ? 16 : 14)
                            .padding(.vertical, isIpad ? 8 : 6)
                            .background(Capsule().fill(homeAccent.opacity(0.12)))
                            .accessibilityLabel("\(appState.plantedDates.count) of \(viewModel.totalCatalogSize) plants discovered")
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
                                        let unlocked = appState.plantedDates[plant.id] != nil
                                        CatalogCell(plant: plant, isUnlocked: unlocked) {
                                            if unlocked {
                                                appState.navigateToPlanHomeCard(plantID: plant.id)
                                            } else {
                                                feedbackBlocked.impactOccurred()
                                            }
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
                            let unlocked = appState.plantedDates[plant.id] != nil
                            CatalogCell(plant: plant, isUnlocked: unlocked) {
                                if unlocked {
                                    appState.navigateToPlanHomeCard(plantID: plant.id)
                                } else {
                                    feedbackBlocked.impactOccurred()
                                }
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
    let isUnlocked: Bool
    let action: () -> Void

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: isIpad ? 24 : 18, style: .continuous)
                    .fill(isUnlocked ? t.background : Color(hex: "#EEEBE4"))
                    .shadow(color: .black.opacity(isUnlocked ? 0.08 : 0.03),
                            radius: isUnlocked ? 10 : 4, x: 0, y: 4)

                if isUnlocked {
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
                }

                VStack(spacing: 0) {
                    ZStack {
                        if isUnlocked {
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
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#D8D4CC").opacity(0.5))
                                    .frame(width: isIpad ? 90 : 70, height: isIpad ? 90 : 70)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: isIpad ? 36 : 26, weight: .medium))
                                    .foregroundColor(Color(hex: "#A0998F"))
                            }
                            .accessibilityHidden(true)
                        }
                    }
                    .frame(height: isIpad ? 160 : 120)

                    Rectangle()
                        .fill(isUnlocked ? t.accent.opacity(0.12) : Color(hex: "#C8C4BC").opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                        .accessibilityHidden(true)

                    VStack(spacing: isIpad ? 6 : 4) {
                        if isUnlocked {
                            Text(plant.name)
                                .font(.system(size: isIpad ? 26 : 19, weight: .bold))
                                .foregroundColor(t.textColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            if let price = plant.price {
                                let formatter = NumberFormatter()
                                formatter.numberStyle = .currency
                                formatter.currencyCode = "MXN"
                                if let str = formatter.string(from: NSNumber(value: price)) {
                                    Text(str)
                                        .font(.system(size: isIpad ? 16 : 14, weight: .semibold))
                                        .foregroundColor(t.textColor.opacity(0.8))
                                }
                            }
                            
                            HStack(spacing: 4) {
                                Circle().fill(t.accent).frame(width: isIpad ? 8 : 6, height: isIpad ? 8 : 6)
                                    .accessibilityHidden(true)
                                Text("GROWING")
                                    .font(.system(size: isIpad ? 12 : 9, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(t.accent)
                            }
                        } else {
                            Text(plant.name)
                                .font(.system(size: isIpad ? 26 : 19, weight: .bold))
                                .foregroundColor(Color(hex: "#A0998F"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("Undiscovered")
                                .font(.system(size: isIpad ? 14 : 11, weight: .medium))
                                .tracking(1)
                                .foregroundColor(Color(hex: "#A0998F").opacity(0.7))
                        }
                    }
                    .padding(.vertical, isIpad ? 18 : 14)
                    .padding(.horizontal, 10)
                }
            }
            .frame(height: isIpad ? 260 : 190)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isUnlocked ? "\(plant.name). Growing." : "\(plant.name). Undiscovered plant")
        .accessibilityHint(isUnlocked ? "Go to this plant in your garden" : "Locked. Scan this plant in the real world to unlock it.")
    }
}
