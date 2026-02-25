//
//  ARGardenView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import SwiftUI

struct ARGardenView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ARGardenViewModel

    @State private var showDetail = false
    @State private var hasOpenedDetail = false
    @State private var chevronPulse = false

    private var t: SeedPacketTheme { seedTheme(for: viewModel.plant.id) }

    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: ARGardenViewModel(plant: plant, isFullyGrown: false))
    }

    var body: some View {
        ZStack {
            // AR Canvas
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()

            VStack {
                // --- Top bar ---
                HStack {
                    Button {
                        appState.currentScreen = .plantHome
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    if viewModel.state != .scanning {
                        Text(stageLabel())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()

                    // Balance spacer
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                // Scanning instruction
                if viewModel.state == .scanning {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "scope")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white)
                        Text("Point at a flat surface and tap to place your plant")
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 28)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 40)
                }

                Spacer()

                // --- Bottom row: chevron hint (left) + detail button (right) ---
                if viewModel.state != .scanning {
                    HStack(alignment: .bottom) {

                        // One-time chevron hint — disappears after first open
                        if !hasOpenedDetail {
                            VStack(spacing: 3) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .offset(y: chevronPulse ? -3 : 0)
                                    .animation(
                                        .easeInOut(duration: 0.9)
                                        .repeatForever(autoreverses: true),
                                        value: chevronPulse
                                    )
                                Text("Details")
                                    .font(.system(size: 11, weight: .medium, design: .serif))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .transition(.opacity)
                            .onAppear { chevronPulse = true }
                        } else {
                            Color.clear.frame(width: 40)
                        }

                        Spacer()

                        // Detail button — bottom right
                        Button {
                            hasOpenedDetail = true
                            showDetail = true
                        } label: {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(t.accent.opacity(0.5), lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
                    .animation(.easeInOut(duration: 0.4), value: hasOpenedDetail)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        }
        .onChange(of: viewModel.state) { newState in
            if newState == .placed { syncToRealWorldData() }
        }
        .sheet(isPresented: $showDetail) {
            PlantDetailView(plant: viewModel.plant)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sync

    private func syncToRealWorldData() {
        guard let plantedDate = appState.plantedDates[viewModel.plant.id] else { return }
        let elapsedDays = Calendar.current.dateComponents([.day], from: plantedDate, to: Date()).day ?? 0
        let milestones = viewModel.plant.growthMilestones
        guard milestones.count >= 4 else { return }

        let iteration: Int
        if      elapsedDays >= milestones[3] { iteration = 4 }
        else if elapsedDays >= milestones[2] { iteration = 3 }
        else if elapsedDays >= milestones[1] { iteration = 2 }
        else if elapsedDays >= milestones[0] { iteration = 1 }
        else                                 { iteration = 0 }

        viewModel.currentIteration = iteration
        viewModel.state = iteration == 4 ? .blooming : .growing(day: elapsedDays)
    }

    private func stageLabel() -> String {
        switch viewModel.state {
        case .blooming:         return "FULLY MATURED"
        case .growing(let day): return "DAY \(day)"
        default:                return ""
        }
    }
}
