//
//  PlantSelectionView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 20/02/26.
//

import SwiftUI

struct PlantSelectionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    @State private var isTransitioning: Bool = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var uiOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 0.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let feedbackLight  = UIImpactFeedbackGenerator(style: .light)
    private let feedbackHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let feedbackMedium = UIImpactFeedbackGenerator(style: .medium)
    private let feedbackSoft   = UIImpactFeedbackGenerator(style: .soft)

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        GeometryReader { geo in
            let plants = viewModel.starterPlants
            guard !plants.isEmpty else { return AnyView(EmptyView()) }
            let current = plants[currentIndex]
            let t = seedTheme(for: current.id)

            let cardWidth  = isIpad ? geo.size.width * 0.68 : geo.size.width * 0.82
            let cardHeight = isIpad ? geo.size.height * 0.65 : geo.size.height * 0.56

            return AnyView(
                ZStack {
                    // Background
                    (reduceTransparency ? t.background : t.background)
                        .ignoresSafeArea()
                        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: currentIndex)
                        .opacity(backgroundOpacity)

                    t.accent
                        .ignoresSafeArea()
                        .opacity(overlayOpacity)

                    VStack(spacing: 0) {

                        Spacer(minLength: isIpad ? 40 : 20)

                        // --- Header ---
                        VStack(spacing: isIpad ? 14 : 10) {
                            Text("CHOOSE YOUR SEED")
                                .font(.system(
                                    size: isIpad ? 32 : 24,
                                    weight: .heavy,
                                    design: .monospaced
                                ))
                                .tracking(isIpad ? 6 : 4)
                                .foregroundColor(t.accent.opacity(0.8))
                                .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: currentIndex)
                                .accessibilityAddTraits(.isHeader)

                            Text("\(currentIndex + 1) of \(plants.count)")
                                .font(.system(
                                    size: isIpad ? 22 : 18,
                                    weight: .semibold,
                                    design: .monospaced
                                ))
                                .tracking(2)
                                .foregroundColor(t.textColor.opacity(0.6))
                                .accessibilityLabel("Plant \(currentIndex + 1) of \(plants.count)")
                        }
                        .padding(.bottom, isIpad ? 48 : 24)
                        .opacity(uiOpacity)

                        // --- Card ---
                        ZStack {
                            ForEach(Array(plants.enumerated()), id: \.element.id) { index, plant in
                                if abs(index - currentIndex) <= 1 {
                                    SeedPacketCard(
                                        plant: plant,
                                        theme: seedTheme(for: plant.id),
                                        screenSize: geo.size
                                    )
                                    .frame(width: cardWidth, height: cardHeight)
                                    .scaleEffect(cardScaleFor(index: index))
                                    .offset(x: offsetFor(index: index, geo: geo, cardWidth: cardWidth))
                                    .opacity(index == currentIndex ? cardOpacity : (0.35 * uiOpacity))
                                    .zIndex(index == currentIndex ? 1 : 0)
                                    .animation(
                                        (isTransitioning || reduceMotion) ? .none :
                                            .interactiveSpring(response: 0.4, dampingFraction: 0.82),
                                        value: currentIndex
                                    )
                                    .animation(
                                        (isTransitioning || reduceMotion) ? .none :
                                            .interactiveSpring(response: 0.4, dampingFraction: 0.82),
                                        value: dragOffset
                                    )
                                    .accessibilityHidden(index != currentIndex)
                                }
                            }
                        }
                        .frame(width: geo.size.width, height: cardHeight)
                        .gesture(swipeGesture(plants: plants, geo: geo))
                        .accessibilityElement(children: .contain)
                        .accessibilityAction(named: "Previous plant") {
                            guard currentIndex > 0 else { return }
                            feedbackHeavy.impactOccurred()
                            withAnimation { currentIndex -= 1 }
                        }
                        .accessibilityAction(named: "Next plant") {
                            guard currentIndex < plants.count - 1 else { return }
                            feedbackHeavy.impactOccurred()
                            withAnimation { currentIndex += 1 }
                        }

                        Spacer(minLength: isIpad ? 40 : 20)

                        // --- Dots ---
                        HStack(spacing: isIpad ? 12 : 8) {
                            ForEach(0..<plants.count, id: \.self) { i in
                                Capsule()
                                    .fill(i == currentIndex ? t.accent : t.accent.opacity(0.25))
                                    .frame(
                                        width:  i == currentIndex ? (isIpad ? 36 : 28) : (isIpad ? 10 : 8),
                                        height: isIpad ? 8 : 7
                                    )
                                    .animation(reduceMotion ? .none : .spring(response: 0.3), value: currentIndex)
                            }
                        }
                        .padding(.bottom, isIpad ? 24 : 16)
                        .opacity(uiOpacity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Page \(currentIndex + 1) of \(plants.count)")

                        // --- Button ---
                        Button {
                            guard !isTransitioning else { return }
                            triggerPlantTransition(plant: current, theme: t, geo: geo) {
                                #if targetEnvironment(simulator)
                                appState.plantSeed(for: current.id)
                                appState.currentScreen = .bridge(current)
                                #else
                                appState.currentScreen = .arGrowth(current)
                                #endif
                            }
                        } label: {
                            HStack(spacing: isIpad ? 16 : 14) {
                                Text("Plant this seed")
                                    .font(.system(size: isIpad ? 26 : 22, weight: .semibold, design: .serif))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: isIpad ? 20 : 18, weight: .semibold))
                                    .accessibilityHidden(true)
                            }
                            .foregroundColor(t.background)
                            .frame(width: cardWidth)
                            .frame(height: isIpad ? 80 : 64)
                            .background(t.accent)
                            .clipShape(RoundedRectangle(cornerRadius: isIpad ? 24 : 20, style: .continuous))
                        }
                        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: currentIndex)
                        .padding(.bottom, geo.safeAreaInsets.bottom + (isIpad ? 64 : 64))
                        .opacity(uiOpacity)
                        .accessibilityLabel("Plant \(current.name)")
                        .accessibilityHint("Starts augmented reality planting experience")
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    // --- Transition ---
    private func triggerPlantTransition(
        plant: PlantSpecies,
        theme: SeedPacketTheme,
        geo: GeometryProxy,
        completion: @escaping () -> Void
    ) {
        isTransitioning = true
        feedbackHeavy.impactOccurred()

        if reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { completion() }
            return
        }

        withAnimation(.easeOut(duration: 0.25)) { uiOpacity = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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

    // --- Helper Functions ---
    private func cardScaleFor(index: Int) -> CGFloat {
        index == currentIndex ? (isTransitioning ? cardScale : 1.0) : 0.88
    }

    private func offsetFor(index: Int, geo: GeometryProxy, cardWidth: CGFloat) -> CGFloat {
        CGFloat(index - currentIndex) * cardWidth * 1.08 + dragOffset
    }

    private func swipeGesture(plants: [PlantSpecies], geo: GeometryProxy) -> some Gesture {
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
                let threshold: CGFloat = geo.size.width * 0.2
                let velocity = value.predictedEndTranslation.width

                if value.translation.width < -threshold || velocity < -500 {
                    if currentIndex < plants.count - 1 {
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
