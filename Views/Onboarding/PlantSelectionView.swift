//
//  PlantSelectionView.swift
//  VirtualGarden
//

import SwiftUI

struct PlantSelectionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    // --- States ---
    @State private var isTransitioning: Bool = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var uiOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 0.0

    private let feedbackLight  = UIImpactFeedbackGenerator(style: .light)
    private let feedbackHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let feedbackMedium = UIImpactFeedbackGenerator(style: .medium)
    private let feedbackSoft   = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        GeometryReader { geo in
            let plants = viewModel.starterPlants
            guard !plants.isEmpty else { return AnyView(EmptyView()) }
            let current = plants[currentIndex]
            let t = seedTheme(for: current.id)

            return AnyView(
                ZStack {

                    // Background
                    t.background
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.4), value: currentIndex)
                        .opacity(backgroundOpacity)

                    // Accent
                    t.accent
                        .ignoresSafeArea()
                        .opacity(overlayOpacity)

                    VStack(spacing: 0) {

                        // Header
                        VStack(spacing: 6) {
                            Text("CHOOSE YOUR SEED")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .tracking(4)
                                .foregroundColor(t.accent.opacity(0.7))
                                .animation(.easeInOut(duration: 0.3), value: currentIndex)

                            Text("\(currentIndex + 1) of \(plants.count)")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(t.textColor.opacity(0.4))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .opacity(uiOpacity)

                        // Card stack
                        ZStack {
                            ForEach(Array(plants.enumerated()), id: \.element.id) { index, plant in
                                if abs(index - currentIndex) <= 1 {
                                    SeedPacketCard(
                                        plant: plant,
                                        theme: seedTheme(for: plant.id),
                                        screenSize: geo.size
                                    )
                                    .scaleEffect(cardScaleFor(index: index))
                                    .offset(x: offsetFor(index: index, geo: geo))
                                    .opacity(index == currentIndex ? cardOpacity : 0.4)
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
                                }
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height * 0.65)
                        .gesture(swipeGesture(plants: plants, geo: geo))

                        Spacer()

                        // Dot indicators
                        HStack(spacing: 8) {
                            ForEach(0..<plants.count, id: \.self) { i in
                                Capsule()
                                    .fill(i == currentIndex
                                          ? t.accent
                                          : t.accent.opacity(0.25))
                                    .frame(width: i == currentIndex ? 24 : 6, height: 6)
                                    .animation(.spring(response: 0.3), value: currentIndex)
                            }
                        }
                        .padding(.bottom, 20)
                        .opacity(uiOpacity)

                        // CTA
                        Button {
                            guard !isTransitioning else { return }
                            triggerPlantTransition(plant: current, theme: t, geo: geo) {
                                appState.currentScreen = .arGrowth(current)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text("Plant this seed")
                                    .font(.system(size: 17, weight: .semibold, design: .serif))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(t.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(t.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 32)
                        }
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                        .opacity(uiOpacity)
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

        // Fade out
        feedbackHeavy.impactOccurred()

        withAnimation(.easeOut(duration: 0.25)) {
            uiOpacity = 0
        }

        // Card pulses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            feedbackMedium.impactOccurred()
            withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) {
                cardScale = 0.93
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            feedbackSoft.impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                cardScale = 1.0
            }
        }

        // Background fade
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

        // Navigate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            completion()
        }
    }

    // -- Functions Helpers --- 

    private func cardScaleFor(index: Int) -> CGFloat {
        if index == currentIndex {
            return isTransitioning ? cardScale : (index == currentIndex ? 1.0 : 0.88)
        }
        return 0.88
    }

    private func offsetFor(index: Int, geo: GeometryProxy) -> CGFloat {
        let spacing = geo.size.width * 0.92
        return CGFloat(index - currentIndex) * spacing + dragOffset
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
                let threshold: CGFloat = geo.size.width * 0.25
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
