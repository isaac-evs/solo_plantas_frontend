//
//  ARGrowthView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 20/02/26.
//

import SwiftUI

struct ARGrowthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ARGardenViewModel

    @State private var headerVisible      = false
    @State private var instructionVisible = false
    @State private var pulseRings         = false
    @State private var lastIteration      = 0
    @State private var captureSnapshot    = false

    @Environment(\.accessibilityReduceMotion)     private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    private var textScale: CGFloat { isIpad ? 2 : 1.5 }

    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: ARGardenViewModel(plant: plant, isFullyGrown: false))
    }

    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel, captureSnapshot: $captureSnapshot)
                .edgesIgnoringSafeArea(.all)
                .accessibilityLabel("Augmented reality camera view")

            Color.white
                .ignoresSafeArea()
                .opacity(viewModel.showPlantingFlash ? 0.2 : 0)
                .animation(reduceMotion ? .none : .easeOut(duration: 0.5), value: viewModel.showPlantingFlash)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(spacing: 0) {

                // Top bar
                if viewModel.state != .scanning {
                    VStack(spacing: 5) {
                        Text(viewModel.plant.name)
                            .font(.system(size: 28 * textScale, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)

                        Text(viewModel.plant.scientificName)
                            .font(.system(size: 15 * textScale, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(.white.opacity(0.8))
                            .accessibilityLabel("Scientific name: \(viewModel.plant.scientificName)")
                    }
                    .padding(.top, 56)
                    .padding(.bottom, 14)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(reduceTransparency ? 0.8 : 0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .top)
                    )
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : -10)
                    .transition(.opacity)
                    .accessibilityElement(children: .combine)
                }

                Spacer()

                // Status area
                VStack(spacing: 16) {
                    switch viewModel.state {
                    case .scanning:      scanningInstruction
                    case .placed:        placedInstruction
                    
                    // THE FIX: Removed the .seeded case entirely so it doesn't flash.
                    // It will now just stay on 'placed' until the first 'growing' frame hits.
                    case .seeded:        EmptyView()
                    
                    case .growing(let day): growingSection(day: day)
                    case .blooming:      bloomingPanel
                    }
                }
                .frame(maxWidth: isIpad ? 450 : .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(instructionVisible ? 1 : 0)
                .offset(y: instructionVisible ? 0 : 12)
            }
        }
        .onAppear {
            let delay = reduceMotion ? 0.1 : 0.3
            withAnimation(.easeOut(duration: 0.5).delay(delay)) { instructionVisible = true }
            withAnimation(.easeOut(duration: 0.4).delay(delay + 0.1)) { headerVisible = true }
        }
        .onChange(of: viewModel.currentIteration) { newIteration in
            guard newIteration > lastIteration, newIteration > 1 else {
                lastIteration = newIteration; return
            }
            lastIteration = newIteration

            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
        }
        .onDisappear { viewModel.cleanUp() }
    }

    // Scan
    private var scanningInstruction: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .strokeBorder(.white.opacity(0.3 - Double(i) * 0.08), lineWidth: 1.5)
                        .frame(width: CGFloat(52 + i * 22), height: CGFloat(52 + i * 22))
                        .scaleEffect(pulseRings ? 1.06 : 1.0)
                        .animation(
                            reduceMotion ? .none :
                                .easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                            value: pulseRings
                        )
                }
                Image(systemName: "scope")
                    .font(.system(size: 22 * (textScale * 0.8), weight: .light))
                    .foregroundColor(.white)
            }
            .onAppear { pulseRings = true }
            .accessibilityHidden(true)

            Text("Find a flat surface")
                .font(.system(size: 19 * textScale, weight: .semibold, design: .serif))
                .foregroundColor(.white)

            Text("Then tap to place a pot.")
                .font(.system(size: 15 * textScale, design: .serif))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 30)
        .background(
            reduceTransparency
                ? AnyView(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.black.opacity(0.85)))
                : AnyView(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning for surface. Move your device slowly until a flat surface is detected, then tap to place your pot.")
    }

    // Pot Placement
    private var placedInstruction: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 30 * textScale, weight: .light))
                .foregroundColor(.white)
                .modifier(BouncingSymbolModifier())
                .accessibilityHidden(true)

            Text("Tap the pot to plant your \(viewModel.plant.name) seed")
                .font(.system(size: 19 * textScale, weight: .semibold, design: .serif))
                .foregroundColor(.white)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(reduceTransparency ? 0.35 : 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pot placed. Double-tap the pot in AR to plant your \(viewModel.plant.name).")
    }

    // Growing
    private func growingSection(day: Int) -> some View {
        let total    = viewModel.plant.growthMilestones.last ?? 30
        let progress = Double(day) / Double(total)
        let percent  = Int(progress * 100)

        return VStack(spacing: 10) {
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("GROWTH")
                        .font(.system(size: 11 * textScale, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(percent)%")
                        .font(.system(size: 11 * textScale, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.2)).frame(height: 5)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: g.size.width * CGFloat(progress), height: 5)
                            .animation(reduceMotion ? .none : .spring(response: 0.6), value: day)
                    }
                }
                .frame(height: 5)
            }
            .padding(.horizontal, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Growth progress")
            .accessibilityValue("\(percent) percent")

            statusPill(
                icon: "forward.fill",
                text: "Fast-forwarding to Day \(day)"
            )
            .accessibilityLabel("Fast-forwarding to Day \(day)")
        }
    }

    // Blooming
    private var bloomingPanel: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("VISION COMPLETE")
                    .font(.system(size: 11 * textScale, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.8))
            }

            Button {
                appState.plantSeed(for: viewModel.plant.id)
                appState.currentScreen = .bridge(viewModel.plant)
            } label: {
                HStack(spacing: 10) {
                    Text("Begin real journey")
                        .font(.system(size: 17 * textScale, weight: .semibold, design: .serif))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14 * textScale, weight: .semibold))
                        .accessibilityHidden(true)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: isIpad ? 72 : 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .accessibilityHint("Saves this plant to your garden and continues to the real-time tracker")
        }
        .padding(22)
        .background(
            reduceTransparency
                ? AnyView(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.black.opacity(0.9)))
                : AnyView(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial))
        )
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
    }

    // Status
    private func statusPill(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15 * textScale, weight: .medium))
                .foregroundColor(.white)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 16 * textScale, weight: .medium, design: .serif))
                .foregroundColor(.white)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 22)
        .background(
            reduceTransparency
                ? AnyView(Capsule().fill(Color.black.opacity(0.85)))
                : AnyView(Capsule().fill(.ultraThinMaterial))
        )
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
    }
}

struct BouncingSymbolModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.pulse, options: .repeating)
        } else {
            content
        }
    }
}
