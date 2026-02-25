//
//  PlantHomeView.swift
//  VirtualGarden
//

import SwiftUI

struct PlantHomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PlantHomeViewModel()

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var appeared = false

    // --- Transition states ---
    @State private var isTransitioning = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var uiOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 0.0

    private let feedbackLight  = UIImpactFeedbackGenerator(style: .light)
    private let feedbackHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let feedbackMedium = UIImpactFeedbackGenerator(style: .medium)
    private let feedbackSoft   = UIImpactFeedbackGenerator(style: .soft)

    private var currentTheme: SeedPacketTheme {
        guard !viewModel.userGarden.isEmpty else { return seedTheme(for: "") }
        let plant = viewModel.userGarden[min(currentIndex, viewModel.userGarden.count - 1)].plant
        return seedTheme(for: plant.id)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dynamic background
                currentTheme.background
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: currentIndex)
                    .opacity(backgroundOpacity)

                // Transition overlay
                currentTheme.accent
                    .ignoresSafeArea()
                    .opacity(overlayOpacity)

                if viewModel.userGarden.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {

                        topBar
                            .opacity(uiOpacity)

                        // Card stack
                        ZStack {
                            ForEach(Array(viewModel.userGarden.enumerated()), id: \.element.id) { index, status in
                                if abs(index - currentIndex) <= 1 {
                                    GardenPlantCard(
                                        status: status,
                                        screenSize: geo.size,
                                        onARTap: {
                                            guard !isTransitioning else { return }
                                            let t = seedTheme(for: status.plant.id)
                                            triggerTransition(theme: t) {
                                                appState.currentScreen = .arGarden(status.plant)
                                            }
                                        }
                                    )
                                    .scaleEffect(index == currentIndex
                                                 ? (isTransitioning ? cardScale : 1.0)
                                                 : 0.88)
                                    .offset(x: offsetFor(index: index, geo: geo))
                                    .opacity(index == currentIndex ? cardOpacity : 0.35)
                                    .zIndex(index == currentIndex ? 1 : 0)
                                    .animation(
                                        isTransitioning ? .none :
                                            .interactiveSpring(response: 0.4, dampingFraction: 0.82),
                                        value: currentIndex
                                    )
                                    .animation(
                                        isTransitioning ? .none :
                                            .interactiveSpring(response: 0.4, dampingFraction: 0.82),
                                        value: dragOffset
                                    )
                                    .opacity(appeared ? 1 : 0)
                                    .scaleEffect(appeared ? 1 : 0.94)
                                }
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height * 0.74)
                        .gesture(swipeGesture(geo: geo))

                        // Dot indicators
                        HStack(spacing: 8) {
                            ForEach(0..<viewModel.userGarden.count, id: \.self) { i in
                                Capsule()
                                    .fill(i == currentIndex
                                          ? currentTheme.accent
                                          : currentTheme.accent.opacity(0.25))
                                    .frame(width: i == currentIndex ? 24 : 6, height: 6)
                                    .animation(.spring(response: 0.3), value: currentIndex)
                            }
                        }
                        .padding(.top, 12)
                        .opacity(uiOpacity)

                        Spacer()
                    }

                    // Floating Field Guide pill
                    VStack {
                        Spacer()
                        Button {
                            feedbackMedium.impactOccurred()
                            appState.currentScreen = .catalog
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Field Guide")
                                    .font(.system(size: 15, weight: .semibold, design: .serif))
                            }
                            .foregroundColor(currentTheme.textColor.opacity(0.75))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(currentTheme.background.opacity(0.92))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(currentTheme.accent.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 5)
                            )
                        }
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                        .opacity(uiOpacity)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadGarden(from: appState.plantedDates)

              if let focusedID = appState.focusedPlantID,
                 let index = viewModel.userGarden.firstIndex(where: { $0.plant.id == focusedID }) {
                  currentIndex = index
                  appState.focusedPlantID = nil
              }

              withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.15)) {
                  appeared = true
              }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("MY GARDEN")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(currentTheme.accent.opacity(0.7))
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
                Text("Growing with you")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(currentTheme.textColor)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(currentTheme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text("\(viewModel.userGarden.count)")
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundColor(currentTheme.accent)
            }
            .animation(.easeInOut(duration: 0.3), value: currentIndex)
        }
        .padding(.horizontal, 28)
        .padding(.top, 48)        // reduced from 56
        .padding(.bottom, 12)     // reduced from 16
    }

    // MARK: - Transition (mirrors PlantSelectionView)

    private func triggerTransition(theme: SeedPacketTheme, completion: @escaping () -> Void) {
        isTransitioning = true
        feedbackHeavy.impactOccurred()

        withAnimation(.easeOut(duration: 0.25)) { uiOpacity = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            feedbackMedium.impactOccurred()
            withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) { cardScale = 0.93 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            feedbackSoft.impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { cardScale = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            feedbackLight.impactOccurred()
            withAnimation(.easeIn(duration: 0.15)) {
                overlayOpacity = 0.85
                backgroundOpacity = 0
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                cardScale = 3.5
                cardOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { completion() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: 52, weight: .thin))
                .foregroundColor(currentTheme.accent.opacity(0.35))
            Text("Your garden is empty")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(currentTheme.textColor.opacity(0.6))
            Text("Plant your first seed to begin.")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(currentTheme.textColor.opacity(0.35))
            Spacer()
        }
    }

    // MARK: - Helpers

    private func offsetFor(index: Int, geo: GeometryProxy) -> CGFloat {
        CGFloat(index - currentIndex) * geo.size.width * 0.88 + dragOffset
    }

    private func swipeGesture(geo: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isTransitioning else { return }
                dragOffset = value.translation.width
                if abs(dragOffset).truncatingRemainder(dividingBy: 60) < 3 {
                    feedbackLight.impactOccurred()
                }
            }
            .onEnded { value in
                guard !isTransitioning else { return }
                let threshold = geo.size.width * 0.25
                let velocity  = value.predictedEndTranslation.width

                if value.translation.width < -threshold || velocity < -500 {
                    if currentIndex < viewModel.userGarden.count - 1 {
                        feedbackHeavy.impactOccurred()
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.82)) {
                            currentIndex += 1; dragOffset = 0
                        }
                    } else {
                        feedbackMedium.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { dragOffset = 0 }
                    }
                } else if value.translation.width > threshold || velocity > 500 {
                    if currentIndex > 0 {
                        feedbackHeavy.impactOccurred()
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.82)) {
                            currentIndex -= 1; dragOffset = 0
                        }
                    } else {
                        feedbackMedium.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { dragOffset = 0 }
                    }
                } else {
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.82)) { dragOffset = 0 }
                }
            }
    }
}

// MARK: - Unified Garden Plant Card

struct GardenPlantCard: View {
    let status: PlantGrowthStatus
    let screenSize: CGSize
    let onARTap: () -> Void

    private var t: SeedPacketTheme { seedTheme(for: status.plant.id) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(t.background)
                .shadow(color: .black.opacity(0.11), radius: 22, x: 0, y: 10)

            // Dot scatter
            GeometryReader { _ in
                let xs: [CGFloat] = [30,110,200,60,150,250,40,130,220,80,170,290,20,100,190,70,160,240]
                let ys: [CGFloat] = [40,80,30,140,100,60,200,160,120,300,250,90,350,310,270,400,370,330]
                let ds: [CGFloat] = [8,14,6,20,10,16,7,12,18,9,15,11,5,22,8,13,17,6]
                ForEach(0..<18, id: \.self) { i in
                    Circle()
                        .fill(t.patternColor.opacity(0.10))
                        .frame(width: ds[i], height: ds[i])
                        .offset(x: xs[i], y: ys[i])
                }
            }
            .clipped()

            VStack(alignment: .leading, spacing: 0) {

                // Top band
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NATIVE SPECIES")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(t.accent.opacity(0.6))
                        Text(status.plant.season.uppercased())
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(t.textColor.opacity(0.4))
                    }
                    Spacer()
                    Text(status.stageName.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(t.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(t.accent))
                }
                .padding(.horizontal, 26)
                .padding(.top, 26)
                .padding(.bottom, 18)

                Rectangle()
                    .fill(t.accent.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 26)

                // Illustration
                ZStack {
                    Ellipse()
                        .fill(t.patternColor.opacity(0.14))
                        .frame(width: screenSize.width * 0.48, height: screenSize.width * 0.48)
                    Image(status.plant.illustrationName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenSize.height * 0.17)
                        .shadow(color: t.accent.opacity(0.18), radius: 10, x: 0, y: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)

                Rectangle()
                    .fill(t.accent.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 26)

                // Name — bigger
                VStack(alignment: .leading, spacing: 5) {
                    Text(status.plant.name)
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(t.textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(status.plant.scientificName)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(t.textColor.opacity(0.45))
                }
                .padding(.horizontal, 26)
                .padding(.top, 18)
                .padding(.bottom, 20)

                // Growth progress
                VStack(spacing: 10) {
                    HStack {
                        Text("DAY \(status.daysElapsed)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(t.accent)
                        Spacer()
                        if let daysLeft = status.daysUntilNextStage {
                            Text("\(daysLeft)d to next stage")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(t.textColor.opacity(0.4))
                        } else {
                            Text("FULLY MATURED")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(t.accent)
                        }
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(t.patternColor.opacity(0.22))
                                .frame(height: 6)
                            Capsule()
                                .fill(t.accent)
                                .frame(width: g.size.width * progressFraction, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 22)   // breathing room between bar and button

                // AR Button
                Button(action: onARTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "arkit")
                            .font(.system(size: 15, weight: .semibold))
                        Text("View in AR")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                    }
                    .foregroundColor(t.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(t.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 26)

                Spacer() // naturally absorbs any remaining space

                // Bottom bar
                HStack(spacing: 8) {
                    Circle().fill(t.accent).frame(width: 6, height: 6)
                    Text(status.plant.dominantColor.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(t.textColor.opacity(0.35))
                    Spacer()
                    Text("JALISCO, MX")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(t.textColor.opacity(0.25))
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 24)
            }
        }
        .frame(width: screenSize.width * 0.84, height: screenSize.height * 0.74)
    }

    private var progressFraction: CGFloat {
        guard status.daysUntilNextStage != nil else { return 1.0 }
        return min(CGFloat(status.daysElapsed) / 30.0, 1.0)
    }
}
