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
    @State private var showNurseryMap = false
    @State private var captureSnapshot = false

    private var t: SeedPacketTheme { seedTheme(for: viewModel.plant.id) }

    private var t: SeedPacketTheme { seedTheme(for: viewModel.plant.id) }

    init(plant: PlantSpecies, overrideIteration: Int? = nil) {
        _viewModel = StateObject(wrappedValue: ARGardenViewModel(plant: plant, isFullyGrown: false, overrideIteration: overrideIteration))
    }

    var body: some View {
        ZStack {
            // AR Canvas
            ARViewContainer(viewModel: viewModel, captureSnapshot: $captureSnapshot)
                .ignoresSafeArea()

            VStack {
                // --- Top bar ---
                HStack {
                    Button {
                        appState.switchTab(appState.activeTab)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Go back")

                    Spacer()

                    if viewModel.state != .scanning {
                        Text(stageLabel())
                            .font(.system(size: 19, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()
                    Color.clear.frame(width: 60, height: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()

                // --- Instructions ---
                VStack(spacing: 24) {
                    
                    if viewModel.state == .scanning {
                        VStack(spacing: 16) {
                            Image(systemName: "scope")
                                .font(.system(size: 42, weight: .light))
                                .foregroundColor(.white)
                                .accessibilityHidden(true)
                            
                            Text("Point at a flat surface and tap to place your plant")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                        .padding(.horizontal, 34)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .padding(.horizontal, 24)
                    }

                    // Buttons
                    if viewModel.state != .scanning {
                        HStack(alignment: .bottom) {
                            Spacer()
                            
                            VStack(spacing: 20) {
                                // Map Button
                                Button {
                                    showNurseryMap = true
                                } label: {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 76, height: 76)
                                        .background(.ultraThinMaterial, in: Circle())
                                        .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))
                                }
                                .accessibilityLabel("Find nearby nurseries")

                                // Detail Button
                                Button {
                                    showDetail = true
                                } label: {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 76, height: 76)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .accessibilityLabel("Plant information")
                                
                                // Snapshot Button
                                Button {
                                    captureSnapshot = true
                                } label: {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 76, height: 76)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .accessibilityLabel("Take a photo of your garden")
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        // Sheet for Plant Details
        .sheet(isPresented: $showDetail) {
            PlantDetailView(plant: viewModel.plant)
                .presentationDetents([.medium, .large])
        }
        // Sheet for the Nursery Map
        .sheet(isPresented: $showNurseryMap) {
            NurseryMapView()
        }
        .onChange(of: viewModel.state) { newState in
            if newState == .placed { syncToRealWorldData() }
        }
    }

    private func stageLabel() -> String {
        switch viewModel.state {
        case .blooming:         return "MATURED"
        case .growing(let day): return "DAY \(day)"
        default:                return ""
        }
    }

    private func syncToRealWorldData() {
        if let override = viewModel.overrideIteration {
            viewModel.currentIteration = override
            viewModel.state = override == 4 ? .blooming : .growing(day: 1)
            return
        }
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
}
