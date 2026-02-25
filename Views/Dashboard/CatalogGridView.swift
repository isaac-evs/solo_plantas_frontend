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

    @State private var riddlePlant: PlantSpecies? = nil
    @State private var showRiddle = false

    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private let green = Color(hex: "#4A7C59")
    private let text  = Color(hex: "#1A2E1A")
    private let bg    = Color(hex: "#F5F0E8")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // --- Header ---
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FIELD GUIDE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(5)
                            .foregroundColor(green.opacity(0.7))

                        HStack(alignment: .firstTextBaseline) {
                            Text("Native Plants")
                                .font(.system(size: 34, weight: .bold, design: .serif))
                                .foregroundColor(text)
                            Spacer()
                            Text("\(appState.plantedDates.count)/\(viewModel.totalCatalogSize)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(green.opacity(0.10)))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 20)

                    // --- Scan banner ---
                    scanBanner
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    // --- Available this season ---
                    if !viewModel.availableThisSeason.isEmpty {
                        seasonBanner
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                    }

                    // --- Season filter chips ---
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CatalogViewModel.SeasonFilter.allCases, id: \.self) { filter in
                                filterChip(filter)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)

                    // --- Grid ---
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.filteredPlants) { plant in
                            let unlocked = appState.plantedDates[plant.id] != nil
                            CatalogCell(plant: plant, isUnlocked: unlocked) {
                                if unlocked {
                                    appState.navigateToPlanHomeCard(plantID: plant.id)
                                } else {
                                    riddlePlant = plant
                                    showRiddle = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showRiddle) {
            if let plant = riddlePlant {
                RiddleSheet(plant: plant)
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Scan Banner

    private var scanBanner: some View {
        Button { appState.currentScreen = .scan } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(green).frame(width: 40, height: 40)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Already growing a native plant?")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(text)
                    Text("Scan it to add it to your garden")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(text.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(green.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(green.opacity(0.18), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Season Banner

    private var seasonBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(green)
                Text("AVAILABLE THIS SEASON")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(green.opacity(0.8))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.availableThisSeason) { plant in
                        let unlocked = appState.plantedDates[plant.id] != nil
                        Button {
                            if unlocked {
                                appState.navigateToPlanHomeCard(plantID: plant.id)
                            } else {
                                riddlePlant = plant
                                showRiddle = true
                            }
                        } label: {
                            let t = seedTheme(for: plant.id)
                            HStack(spacing: 10) {
                                Image(plant.illustrationName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(unlocked ? plant.name : "???")
                                        .font(.system(size: 13, weight: .bold, design: .serif))
                                        .foregroundColor(t.textColor)
                                    Text(plant.season)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(t.textColor.opacity(0.5))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(t.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(t.accent.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(green.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(green.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Filter Chip

    private func filterChip(_ filter: CatalogViewModel.SeasonFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectedFilter = filter
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(filter.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .serif))
            }
            .foregroundColor(isSelected ? .white : text.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? green : Color.white.opacity(0.7))
                    .overlay(
                        Capsule()
                            .strokeBorder(isSelected ? .clear : green.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Catalog Cell

struct CatalogCell: View {
    let plant: PlantSpecies
    let isUnlocked: Bool
    let action: () -> Void

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isUnlocked ? t.background : Color(hex: "#EEEBE4"))
                    .shadow(
                        color: .black.opacity(isUnlocked ? 0.08 : 0.03),
                        radius: isUnlocked ? 10 : 4,
                        x: 0, y: 4
                    )

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
                }

                VStack(spacing: 0) {
                    ZStack {
                        if isUnlocked {
                            Ellipse()
                                .fill(t.patternColor.opacity(0.15))
                                .frame(width: 90, height: 90)
                            Image(plant.illustrationName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 72)
                                .shadow(color: t.accent.opacity(0.15), radius: 6, x: 0, y: 3)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#D8D4CC").opacity(0.5))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(Color(hex: "#A0998F"))
                            }
                        }
                    }
                    .frame(height: 110)

                    Rectangle()
                        .fill(isUnlocked ? t.accent.opacity(0.12) : Color(hex: "#C8C4BC").opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 14)

                    VStack(spacing: 3) {
                        if isUnlocked {
                            Text(plant.name)
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundColor(t.textColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            HStack(spacing: 4) {
                                Circle().fill(t.accent).frame(width: 5, height: 5)
                                Text("GROWING")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundColor(t.accent)
                            }
                        } else {
                            Text("?")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "#A0998F"))
                            Text("Undiscovered")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .tracking(1)
                                .foregroundColor(Color(hex: "#A0998F").opacity(0.7))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                }
            }
            .frame(height: 180)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Riddle Sheet

struct RiddleSheet: View {
    let plant: PlantSpecies
    @Environment(\.dismiss) var dismiss

    private let green = Color(hex: "#4A7C59")
    private let text  = Color(hex: "#1A2E1A")
    private let bg    = Color(hex: "#F5F0E8")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                VStack(spacing: 20) {
                    // Lock icon with accent ring
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#D8D4CC").opacity(0.4))
                            .frame(width: 72, height: 72)
                        Circle()
                            .strokeBorder(green.opacity(0.2), lineWidth: 1.5)
                            .frame(width: 72, height: 72)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(Color(hex: "#A0998F"))
                    }

                    VStack(spacing: 8) {
                        Text("UNDISCOVERED PLANT")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(green.opacity(0.6))

                        Text("Here's your clue")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(text)
                    }

                    // Riddle card
                    Text("\"\(plant.riddle)\"")
                        .font(.system(size: 16, design: .serif))
                        .italic()
                        .foregroundColor(text.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(green.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)

                    // Hint about scanning
                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 11))
                            .foregroundColor(green)
                        Text("Scan a matching plant to unlock it")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(text.opacity(0.5))
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
        }
    }
}
