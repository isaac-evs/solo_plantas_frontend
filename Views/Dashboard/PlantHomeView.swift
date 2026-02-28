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

    @State private var isTransitioning  = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var uiOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 0.0

    @Environment(\.accessibilityReduceMotion)       private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let feedbackLight  = UIImpactFeedbackGenerator(style: .light)
    private let feedbackHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let feedbackMedium = UIImpactFeedbackGenerator(style: .medium)
    private let feedbackSoft   = UIImpactFeedbackGenerator(style: .soft)

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var currentTheme: SeedPacketTheme {
        guard !viewModel.userGarden.isEmpty else { return seedTheme(for: "") }
        return seedTheme(for: viewModel.userGarden[min(currentIndex, viewModel.userGarden.count - 1)].plant.id)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                currentTheme.background
                    .ignoresSafeArea()
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.5), value: currentIndex)
                    .opacity(backgroundOpacity)

                currentTheme.accent
                    .ignoresSafeArea()
                    .opacity(overlayOpacity)
                    .accessibilityHidden(true)

                if viewModel.userGarden.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {

                        topBar
                            .opacity(uiOpacity)

                        // Card carousel — taller now that name/button live below card
                        ZStack {
                            ForEach(Array(viewModel.userGarden.enumerated()), id: \.element.id) { index, status in
                                if abs(index - currentIndex) <= 1 {
                                    plantCard(for: status, at: index, geo: geo)
                                }
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height * 0.82)
                        .gesture(swipeGesture(geo: geo))
                        .accessibilityElement(children: .contain)
                        .accessibilityAction(named: "Previous plant") {
                            guard currentIndex > 0 else { return }
                            feedbackHeavy.impactOccurred()
                            withAnimation { currentIndex -= 1 }
                        }
                        .accessibilityAction(named: "Next plant") {
                            guard currentIndex < viewModel.userGarden.count - 1 else { return }
                            feedbackHeavy.impactOccurred()
                            withAnimation { currentIndex += 1 }
                        }

                        // Dot indicators
                        if viewModel.userGarden.count > 1 {
                            HStack(spacing: isIpad ? 12 : 8) {
                                ForEach(0..<viewModel.userGarden.count, id: \.self) { i in
                                    Capsule()
                                        .fill(i == currentIndex
                                              ? currentTheme.accent
                                              : currentTheme.accent.opacity(0.25))
                                        .frame(
                                            width:  i == currentIndex ? (isIpad ? 28 : 20) : (isIpad ? 8 : 6),
                                            height: isIpad ? 6 : 5
                                        )
                                        .animation(
                                            reduceMotion ? .none : .spring(response: 0.3),
                                            value: currentIndex
                                        )
                                }
                            }
                            .padding(.top, isIpad ? 14 : 10)
                            .opacity(uiOpacity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Plant \(currentIndex + 1) of \(viewModel.userGarden.count)")
                        }

                        Spacer()
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

            withAnimation(
                reduceMotion
                    ? .none
                    : .spring(response: 0.6, dampingFraction: 0.78).delay(0.15)
            ) { appeared = true }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: isIpad ? 5 : 3) {
                Text("MY GARDEN")
                    .font(.system(size: isIpad ? 14 : 10, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(currentTheme.accent.opacity(0.7))
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: currentIndex)
                    .accessibilityAddTraits(.isHeader)

                Text("Growing with you")
                    .font(.system(size: isIpad ? 38 : 26, weight: .bold, design: .serif))
                    .foregroundColor(currentTheme.textColor)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: currentIndex)
            }
            Spacer()

            ZStack {
                Circle()
                    .fill(currentTheme.accent.opacity(0.12))
                    .frame(width: isIpad ? 60 : 44, height: isIpad ? 60 : 44)
                Text("\(viewModel.userGarden.count)")
                    .font(.system(size: isIpad ? 24 : 17, weight: .bold, design: .monospaced))
                    .foregroundColor(currentTheme.accent)
            }
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: currentIndex)
            .accessibilityLabel("\(viewModel.userGarden.count) plants in your garden")
        }
        .padding(.horizontal, isIpad ? 40 : 28)
        .padding(.top, isIpad ? 56 : 52)
        .padding(.bottom, isIpad ? 12 : 8)
    }

    // MARK: - Transition

    private func triggerTransition(theme: SeedPacketTheme, completion: @escaping () -> Void) {
        isTransitioning = true
        feedbackHeavy.impactOccurred()

        if reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { completion() }
            return
        }

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
                overlayOpacity = 0.85; backgroundOpacity = 0
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                cardScale = 3.5; cardOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { completion() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: isIpad ? 22 : 16) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: isIpad ? 72 : 52, weight: .thin))
                .foregroundColor(currentTheme.accent.opacity(0.35))
                .accessibilityHidden(true)
            Text("Your garden is empty")
                .font(.system(size: isIpad ? 32 : 22, weight: .bold, design: .serif))
                .foregroundColor(currentTheme.textColor.opacity(0.6))
                .accessibilityAddTraits(.isHeader)
            Text("Plant your first seed to begin.")
                .font(.system(size: isIpad ? 20 : 14, design: .serif))
                .foregroundColor(currentTheme.textColor.opacity(0.35))
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private var cardAnimation: Animation? {
        (isTransitioning || reduceMotion) ? .none : .interactiveSpring(response: 0.4, dampingFraction: 0.82)
    }

    private func cardScaleFor(index: Int) -> CGFloat {
        index == currentIndex ? (isTransitioning ? cardScale : 1.0) : 0.88
    }

    private func offsetFor(index: Int, geo: GeometryProxy) -> CGFloat {
        CGFloat(index - currentIndex) * geo.size.width * 0.88 + dragOffset
    }

    @ViewBuilder
    private func plantCard(for status: PlantGrowthStatus, at index: Int, geo: GeometryProxy) -> some View {
        WatercolorCard(
            status: status,
            screenSize: geo.size,
            onARTap: {
                guard !isTransitioning else { return }
                triggerTransition(theme: seedTheme(for: status.plant.id)) {
                    appState.currentScreen = .arGarden(status.plant)
                }
            }
        )
        .scaleEffect(cardScaleFor(index: index))
        .offset(x: offsetFor(index: index, geo: geo))
        .opacity(index == currentIndex ? cardOpacity : 0.35)
        .zIndex(index == currentIndex ? 1 : 0)
        .animation(cardAnimation, value: currentIndex)
        .animation(cardAnimation, value: dragOffset)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .accessibilityHidden(index != currentIndex)
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
