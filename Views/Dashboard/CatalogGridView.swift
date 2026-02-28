//
//  CatalogGridView.swift
//  VirtualGarden
//

import SwiftUI

struct CatalogGridView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CatalogViewModel()

    @State private var riddlePlant: PlantSpecies? = nil
    @State private var showRiddle = false

    @Environment(\.accessibilityReduceMotion)       private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var s: CGFloat { isIpad ? 1.4 : 1.0 }

    private let green = Color(hex: "#4A7C59")
    private let text  = Color(hex: "#1A2E1A")
    private let bg    = Color(hex: "#F5F0E8")

    var columns: [GridItem] {
        isIpad
            ? [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
            : [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FIELD GUIDE")
                            .font(.system(size: isIpad ? 14 : 10, weight: .bold, design: .monospaced))
                            .tracking(5)
                            .foregroundColor(green.opacity(0.7))
                            .accessibilityAddTraits(.isHeader)

                        HStack(alignment: .firstTextBaseline) {
                            Text("Native Plants")
                                .font(.system(size: isIpad ? 48 : 34, weight: .bold, design: .serif))
                                .foregroundColor(text)
                            Spacer()
                            Text("\(appState.plantedDates.count)/\(viewModel.totalCatalogSize)")
                                .font(.system(size: isIpad ? 18 : 13, weight: .bold, design: .monospaced))
                                .foregroundColor(green)
                                .padding(.horizontal, isIpad ? 16 : 12)
                                .padding(.vertical, isIpad ? 8 : 6)
                                .background(Capsule().fill(green.opacity(0.10)))
                                .accessibilityLabel("\(appState.plantedDates.count) of \(viewModel.totalCatalogSize) plants discovered")
                        }
                    }
                    .padding(.horizontal, isIpad ? 36 : 24)
                    .padding(.top, isIpad ? 64 : 56)
                    .padding(.bottom, isIpad ? 28 : 20)

                    // Scan banner
                    scanBanner
                        .padding(.horizontal, isIpad ? 36 : 24)
                        .padding(.bottom, isIpad ? 28 : 20)

                    // Season banner
                    if !viewModel.availableThisSeason.isEmpty {
                        seasonBanner
                            .padding(.horizontal, isIpad ? 36 : 24)
                            .padding(.bottom, isIpad ? 28 : 20)
                    }

                    // Season filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: isIpad ? 12 : 8) {
                            ForEach(CatalogViewModel.SeasonFilter.allCases, id: \.self) { filter in
                                filterChip(filter)
                            }
                        }
                        .padding(.horizontal, isIpad ? 36 : 24)
                    }
                    .padding(.bottom, isIpad ? 28 : 20)

                    // Grid
                    LazyVGrid(columns: columns, spacing: isIpad ? 20 : 14) {
                        ForEach(viewModel.filteredPlants) { plant in
                            let unlocked = appState.plantedDates[plant.id] != nil
                            CatalogCell(plant: plant, isUnlocked: unlocked) {
                                if unlocked {
                                    appState.navigateToPlanHomeCard(plantID: plant.id)
                                } else {
                                    riddlePlant = plant
                                    showRiddle  = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, isIpad ? 36 : 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showRiddle) {
            if let plant = riddlePlant {
                RiddleSheet(plant: plant)
                    .presentationDetents([.height(isIpad ? 420 : 340)])
                    .presentationDragIndicator(.visible)
            }
        }
        .accessibilityLabel("Field Guide. Browse and discover native plants.")
    }

    // MARK: - Scan Banner

    private var scanBanner: some View {
        Button { appState.switchTab(.scan) } label: {
            HStack(spacing: isIpad ? 18 : 14) {
                ZStack {
                    Circle().fill(green).frame(width: isIpad ? 52 : 40, height: isIpad ? 52 : 40)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: isIpad ? 22 : 17, weight: .medium))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Already growing a native plant?")
                        .font(.system(size: isIpad ? 19 : 14, weight: .semibold, design: .serif))
                        .foregroundColor(text)
                    Text("Scan it to add it to your garden")
                        .font(.system(size: isIpad ? 15 : 12, design: .serif))
                        .foregroundColor(text.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: isIpad ? 16 : 12, weight: .semibold))
                    .foregroundColor(green.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, isIpad ? 22 : 18)
            .padding(.vertical, isIpad ? 18 : 14)
            .background(
                RoundedRectangle(cornerRadius: isIpad ? 20 : 16, style: .continuous)
                    .fill(reduceTransparency ? Color.white : Color.white.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: isIpad ? 20 : 16, style: .continuous)
                            .strokeBorder(green.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .accessibilityLabel("Already growing a native plant? Scan it to add it to your garden.")
        .accessibilityHint("Opens the camera scanner")
    }

    // MARK: - Season Banner

    private var seasonBanner: some View {
        VStack(alignment: .leading, spacing: isIpad ? 14 : 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.system(size: isIpad ? 13 : 10, weight: .bold)).foregroundColor(green)
                    .accessibilityHidden(true)
                Text("AVAILABLE THIS SEASON")
                    .font(.system(size: isIpad ? 12 : 9, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(green.opacity(0.8))
            }
            .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isIpad ? 14 : 10) {
                    ForEach(viewModel.availableThisSeason) { plant in
                        let unlocked = appState.plantedDates[plant.id] != nil
                        Button {
                            if unlocked { appState.navigateToPlanHomeCard(plantID: plant.id) }
                            else { riddlePlant = plant; showRiddle = true }
                        } label: {
                            let t = seedTheme(for: plant.id)
                            HStack(spacing: isIpad ? 14 : 10) {
                                Image(plant.illustrationName)
                                    .resizable().scaledToFit()
                                    .frame(width: isIpad ? 44 : 32, height: isIpad ? 44 : 32)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(unlocked ? plant.name : "???")
                                        .font(.system(size: isIpad ? 17 : 13, weight: .bold, design: .serif))
                                        .foregroundColor(t.textColor)
                                    Text(plant.season)
                                        .font(.system(size: isIpad ? 12 : 9, design: .monospaced))
                                        .foregroundColor(t.textColor.opacity(0.5))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.horizontal, isIpad ? 18 : 14)
                            .padding(.vertical, isIpad ? 14 : 10)
                            .background(
                                RoundedRectangle(cornerRadius: isIpad ? 16 : 12, style: .continuous)
                                    .fill(t.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: isIpad ? 16 : 12, style: .continuous)
                                            .strokeBorder(t.accent.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .accessibilityLabel(unlocked ? "\(plant.name), blooms in \(plant.season)" : "Undiscovered plant, blooms in \(plant.season)")
                        .accessibilityHint(unlocked ? "Go to this plant in your garden" : "Tap to see a clue")
                    }
                }
            }
        }
        .padding(.horizontal, isIpad ? 22 : 18)
        .padding(.vertical, isIpad ? 18 : 14)
        .background(
            RoundedRectangle(cornerRadius: isIpad ? 20 : 16, style: .continuous)
                .fill(green.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: isIpad ? 20 : 16, style: .continuous)
                        .strokeBorder(green.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Filter Chip

    private func filterChip(_ filter: CatalogViewModel.SeasonFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            withAnimation(reduceMotion ? .none : .spring(response: 0.3)) {
                viewModel.selectedFilter = filter
            }
        } label: {
            HStack(spacing: isIpad ? 7 : 5) {
                Image(systemName: filter.icon)
                    .font(.system(size: isIpad ? 14 : 11, weight: .medium))
                Text(filter.rawValue)
                    .font(.system(size: isIpad ? 15 : 12, weight: isSelected ? .bold : .medium, design: .serif))
            }
            .foregroundColor(isSelected ? .white : text.opacity(0.6))
            .padding(.horizontal, isIpad ? 20 : 14)
            .padding(.vertical, isIpad ? 12 : 8)
            .background(
                Capsule()
                    .fill(isSelected ? green : Color.white.opacity(0.7))
                    .overlay(Capsule().strokeBorder(isSelected ? .clear : green.opacity(0.15), lineWidth: 1))
            )
        }
        .accessibilityLabel("\(filter.rawValue) filter")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Catalog Cell

struct CatalogCell: View {
    let plant: PlantSpecies
    let isUnlocked: Bool
    let action: () -> Void

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var s: CGFloat { isIpad ? 1.4 : 1.0 }

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
                        let ds: [CGFloat] = [5,   9,   6,  12,  7,   8]
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
                            Ellipse()
                                .fill(t.patternColor.opacity(0.15))
                                .frame(width: isIpad ? 120 : 90, height: isIpad ? 120 : 90)
                                .accessibilityHidden(true)
                            Image(plant.illustrationName)
                                .resizable().scaledToFit()
                                .frame(height: isIpad ? 96 : 72)
                                .shadow(color: t.accent.opacity(0.15), radius: 6, x: 0, y: 3)
                                .accessibilityLabel("\(plant.name) illustration")
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#D8D4CC").opacity(0.5))
                                    .frame(width: isIpad ? 80 : 60, height: isIpad ? 80 : 60)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: isIpad ? 30 : 22, weight: .medium))
                                    .foregroundColor(Color(hex: "#A0998F"))
                            }
                            .accessibilityHidden(true)
                        }
                    }
                    .frame(height: isIpad ? 140 : 110)

                    Rectangle()
                        .fill(isUnlocked ? t.accent.opacity(0.12) : Color(hex: "#C8C4BC").opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                        .accessibilityHidden(true)

                    VStack(spacing: isIpad ? 5 : 3) {
                        if isUnlocked {
                            Text(plant.name)
                                .font(.system(size: isIpad ? 20 : 15, weight: .bold, design: .serif))
                                .foregroundColor(t.textColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            HStack(spacing: 4) {
                                Circle().fill(t.accent).frame(width: isIpad ? 7 : 5, height: isIpad ? 7 : 5)
                                    .accessibilityHidden(true)
                                Text("GROWING")
                                    .font(.system(size: isIpad ? 11 : 8, weight: .bold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundColor(t.accent)
                            }
                        } else {
                            Text("?")
                                .font(.system(size: isIpad ? 32 : 22, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "#A0998F"))
                            Text("Undiscovered")
                                .font(.system(size: isIpad ? 13 : 10, weight: .medium, design: .monospaced))
                                .tracking(1)
                                .foregroundColor(Color(hex: "#A0998F").opacity(0.7))
                        }
                    }
                    .padding(.vertical, isIpad ? 16 : 12)
                    .padding(.horizontal, 10)
                }
            }
            .frame(height: isIpad ? 240 : 180)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isUnlocked ? "\(plant.name). Growing." : "Undiscovered plant")
        .accessibilityHint(isUnlocked ? "Go to this plant in your garden" : "Tap for a clue to identify this plant")
    }
}

// MARK: - Riddle Sheet

struct RiddleSheet: View {
    let plant: PlantSpecies
    @Environment(\.dismiss) var dismiss

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var s: CGFloat { isIpad ? 1.4 : 1.0 }

    private let green = Color(hex: "#4A7C59")
    private let text  = Color(hex: "#1A2E1A")
    private let bg    = Color(hex: "#F5F0E8")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .accessibilityHidden(true)

                VStack(spacing: isIpad ? 26 : 20) {
                    ZStack {
                        Circle().fill(Color(hex: "#D8D4CC").opacity(0.4))
                            .frame(width: isIpad ? 96 : 72, height: isIpad ? 96 : 72)
                        Circle().strokeBorder(green.opacity(0.2), lineWidth: 1.5)
                            .frame(width: isIpad ? 96 : 72, height: isIpad ? 96 : 72)
                        Image(systemName: "lock.fill")
                            .font(.system(size: isIpad ? 34 : 26, weight: .medium))
                            .foregroundColor(Color(hex: "#A0998F"))
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("UNDISCOVERED PLANT")
                            .font(.system(size: isIpad ? 12 : 9, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(green.opacity(0.6))

                        Text("Here's your clue")
                            .font(.system(size: isIpad ? 32 : 24, weight: .bold, design: .serif))
                            .foregroundColor(text)
                            .accessibilityAddTraits(.isHeader)
                    }

                    Text("\"\(plant.riddle)\"")
                        .font(.system(size: isIpad ? 20 : 16, design: .serif))
                        .italic()
                        .foregroundColor(text.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 28)
                        .padding(.vertical, isIpad ? 26 : 20)
                        .background(
                            RoundedRectangle(cornerRadius: isIpad ? 20 : 16, style: .continuous)
                                .fill(Color.white.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: isIpad ? 20 : 16, style: .continuous)
                                        .strokeBorder(green.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .accessibilityLabel("Clue: \(plant.riddle)")

                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: isIpad ? 15 : 11))
                            .foregroundColor(green)
                            .accessibilityHidden(true)
                        Text("Scan a matching plant to unlock it")
                            .font(.system(size: isIpad ? 16 : 12, design: .serif))
                            .foregroundColor(text.opacity(0.5))
                    }
                    .padding(.top, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Scan a matching plant to unlock it")
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
    }
}
