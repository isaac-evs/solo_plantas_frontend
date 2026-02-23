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

    // States
    @State private var headerVisible    = false
    @State private var instructionVisible = false
    @State private var pulseRings       = false
    @State private var growthBadgeScale: CGFloat = 0.1
    @State private var showGrowthBadge  = false
    @State private var lastIteration    = 0

    private let t: SeedPacketTheme

    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: ARGardenViewModel(plant: plant, isFullyGrown: false))
        t = seedTheme(for: plant.id)
    }

    var body: some View {
        ZStack {

            ARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            t.accent
                .ignoresSafeArea()
                .opacity(viewModel.showPlantingFlash ? 0.35 : 0)
                .animation(.easeOut(duration: 0.5), value: viewModel.showPlantingFlash)
                .allowsHitTesting(false)

            if showGrowthBadge {
                growthBadgeView
            }

            VStack(spacing: 0) {

                // --- Header ---
                
                if viewModel.state != .scanning {
                    VStack(spacing: 6) {
                        Text(viewModel.plant.name)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(.white)

                        Text(viewModel.plant.scientificName)
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 56)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.55), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .top)
                    )
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : -12)
                    .transition(.opacity)
                }

                Spacer()

                // --- Instruction and Status ---
                
                VStack(spacing: 16) {
                    switch viewModel.state {

                    case .scanning:
                        scanningInstruction

                    case .placed:
                        placedInstruction

                    case .seeded:
                        statusPill(
                            icon: "leaf.fill",
                            text: "Seed planted — nurturing…",
                            color: t.accent
                        )

                    case .growing(let day):
                        VStack(spacing: 10) {
                            growthProgressBar(day: day)
                            statusPill(
                                icon: "arrow.up.leaf.fill",
                                text: "Day \(day) of 30",
                                color: t.accent
                            )
                        }

                    case .blooming:
                        bloomingCTA
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
                .opacity(instructionVisible ? 1 : 0)
                .offset(y: instructionVisible ? 0 : 16)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) { instructionVisible = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) { headerVisible = true }
        }
        .onChange(of: viewModel.currentIteration) { newIteration in
            guard newIteration > lastIteration, newIteration > 1 else {
                lastIteration = newIteration
                return
            }
            lastIteration = newIteration
            triggerGrowthBadge(iteration: newIteration)
        }
        .onDisappear { viewModel.cleanUp() }
    }

    // --- Scanning instruction ---

    private var scanningInstruction: some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .strokeBorder(.white.opacity(0.25 - Double(i) * 0.06), lineWidth: 1.5)
                        .frame(width: CGFloat(56 + i * 22), height: CGFloat(56 + i * 22))
                        .scaleEffect(pulseRings ? 1.08 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: pulseRings
                        )
                }
                Image(systemName: "scope")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.white)
            }
            .onAppear { pulseRings = true }

            Text("Point at a flat surface")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundColor(.white)

            Text("Move your phone slowly until the surface is detected, then tap to place your pot.")
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // --- Planting instruction ---

    private var placedInstruction: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(t.accent)
                .modifier(BouncingSymbolModifier(accent: t.accent))

            Text("Tap the pot to plant your seed")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundColor(.white)

            Text("Your \(viewModel.plant.name) is ready to begin its journey.")
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(t.accent.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(t.accent.opacity(0.4), lineWidth: 1)
                )
        )
    }

    // --- Progress Bar ---

    private func growthProgressBar(day: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("GROWTH")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("\(Int((Double(day) / 30.0) * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(t.accent)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .frame(height: 4)
                    Capsule()
                        .fill(t.accent)
                        .frame(width: g.size.width * CGFloat(day) / 30.0, height: 4)
                        .animation(.spring(response: 0.6), value: day)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 4)
    }

    // --- Status ---

    private func statusPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
    }

    // --- Blooming ---

    private var bloomingCTA: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Fully grown")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(t.accent.opacity(0.8))
                Text(viewModel.plant.name)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            }

            Button {
                appState.unlockedPlantIDs.insert(viewModel.plant.id)
                appState.currentScreen = .bridge(viewModel.plant)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Capture & Add to Garden")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                }
                .foregroundColor(t.textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(t.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // --- Growth Badge --- 

    private var growthBadgeView: some View {
        VStack(spacing: 4) {
            Text("STAGE \(viewModel.currentIteration)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(4)
                .foregroundColor(t.accent)
            Text("New growth")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.white)
            Image(systemName: "leaf.fill")
                .font(.system(size: 22))
                .foregroundColor(t.accent)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(t.accent.opacity(0.4), lineWidth: 1)
        )
        .scaleEffect(growthBadgeScale)
        .opacity(showGrowthBadge ? 1 : 0)
    }

    private func triggerGrowthBadge(iteration: Int) {
        showGrowthBadge = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            growthBadgeScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                growthBadgeScale = 0.1
                showGrowthBadge = false
            }
        }
    }
}

struct BouncingSymbolModifier: ViewModifier {
    let accent: Color

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.pulse, options: .repeating)
        } else {
            content
        }
    }
}
