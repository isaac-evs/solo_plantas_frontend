//
//  PlantHomeView.swift
//  VirtualGarden
//
// Created by Isaac Vazquez Sandoval on 21/02/26.
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

    private let homeBackground = Color(hex: "#F5F0E8")
    private let homeTextPrimary = Color(hex: "#1A2E1A")
    private let homeAccent = Color(hex: "#4A7C59")

    var body: some View {
        GeometryReader { geo in
            ZStack {
                homeBackground
                    .ignoresSafeArea()
                    .opacity(backgroundOpacity)

                if !viewModel.userGarden.isEmpty {
                    seedTheme(for: viewModel.userGarden[min(currentIndex, viewModel.userGarden.count - 1)].plant.id).accent
                        .ignoresSafeArea()
                        .opacity(overlayOpacity)
                        .accessibilityHidden(true)
                }

                if viewModel.userGarden.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        
                        topBar
                            .opacity(uiOpacity)
                            
                        Spacer()

                        // Card carousel
                        ZStack {
                            ForEach(Array(viewModel.userGarden.enumerated()), id: \.element.id) { index, status in
                                if abs(index - currentIndex) <= 1 {
                                    plantCard(for: status, at: index, geo: geo)
                                }
                            }
                        }
                        .frame(width: geo.size.width, height: isIpad ? geo.size.height * 0.64 : geo.size.height * 0.60)
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

                        Spacer()

                        // Dot indicators
                        if viewModel.userGarden.count > 1 {
                            HStack(spacing: isIpad ? 12 : 8) {
                                ForEach(0..<viewModel.userGarden.count, id: \.self) { i in
                                    Capsule()
                                        .fill(i == currentIndex
                                              ? homeAccent
                                              : homeAccent.opacity(0.25))
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
                            .opacity(uiOpacity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Plant \(currentIndex + 1) of \(viewModel.userGarden.count)")
                        }
                        
                        Spacer().frame(height: isIpad ? 100 : 80)
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

    // Top Bar
    private var topBar: some View {
        HStack(alignment: .center) {
            Text("My Garden")
                .font(.system(size: isIpad ? 44 : 34, weight: .bold))
                .foregroundColor(homeTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            ZStack {
                Circle()
                    .fill(homeAccent.opacity(0.12))
                    .frame(width: isIpad ? 54 : 44, height: isIpad ? 54 : 44)
                Text("\(viewModel.userGarden.count)")
                    .font(.system(size: isIpad ? 22 : 18, weight: .bold))
                    .foregroundColor(homeAccent)
            }
            .accessibilityLabel("\(viewModel.userGarden.count) plants in your garden")
        }
        .padding(.horizontal, isIpad ? 40 : 28)
        .padding(.top, isIpad ? 50 : 62)
    }

    // Transition
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

    // Edge Case
    private var emptyState: some View {
        VStack(spacing: isIpad ? 22 : 16) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: isIpad ? 72 : 52, weight: .thin))
                .foregroundColor(homeAccent.opacity(0.35))
                .accessibilityHidden(true)
            Text("Your garden is empty")
                .font(.system(size: isIpad ? 32 : 22, weight: .bold))
                .foregroundColor(homeTextPrimary.opacity(0.6))
                .accessibilityAddTraits(.isHeader)
            Text("Plant your first seed to begin.")
                .font(.system(size: isIpad ? 20 : 16))
                .foregroundColor(homeTextPrimary.opacity(0.45))
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // Helper Functions
    private var cardAnimation: Animation? {
        (isTransitioning || reduceMotion) ? .none : .interactiveSpring(response: 0.4, dampingFraction: 0.82)
    }

    private func cardScaleFor(index: Int) -> CGFloat {
        index == currentIndex ? (isTransitioning ? cardScale : 1.0) : 0.88
    }

    private func offsetFor(index: Int, geo: GeometryProxy) -> CGFloat {
        CGFloat(index - currentIndex) * geo.size.width * 0.82 + dragOffset
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
        .padding(.horizontal, isIpad ? 60 : 24)
        .frame(maxWidth: isIpad ? 700 : 390)
        
        .scaleEffect(cardScaleFor(index: index))
        .offset(x: offsetFor(index: index, geo: geo))
        .opacity(index == currentIndex ? cardOpacity : 0.35 * uiOpacity)
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
