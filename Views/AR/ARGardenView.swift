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
    
    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: ARGardenViewModel(plant: plant, isFullyGrown: false))
    }
    
    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack {
                // Status
                if viewModel.state == .scanning {
                    Text("Scan the floor and tap to view your plant")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.top, 60)
                } else {
                    Text(stageLabel())
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.top, 60)
                }
                
                Spacer()
                
                PrimaryButton(title: "Back to Garden", icon: "arrow.left", backgroundColor: Color.white.opacity(0.9), textColor: .black) {
                    appState.currentScreen = .plantHome
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .onChange(of: viewModel.state) { newState in
            if newState == .placed {
                syncToRealWorldData()
            }
        }
    }
    
    // --- Sync ---
    
    private func syncToRealWorldData() {
        // Fetch origin date
        guard let plantedDate = appState.plantedDates[viewModel.plant.id] else { return }
        
        let elapsedDays = Calendar.current.dateComponents([.day], from: plantedDate, to: Date()).day ?? 0
        let milestones = viewModel.plant.growthMilestones
        guard milestones.count >= 4 else { return }
        
        let iteration: Int
        if elapsedDays >= milestones[3] {
            iteration = 4
        } else if elapsedDays >= milestones[2] {
            iteration = 3
        } else if elapsedDays >= milestones[1] {
            iteration = 2
        } else if elapsedDays >= milestones[0] {
            iteration = 1
        } else {
            iteration = 0
        }
        
        viewModel.currentIteration = iteration
        if iteration == 4 {
            viewModel.state = .blooming
        } else {
            viewModel.state = .growing(day: elapsedDays)
        }
    }
    
    private func stageLabel() -> String {
        switch viewModel.state {
        case .blooming: return "Stage: Fully Matured"
        case .growing(let day): return "Day \(day) Growth"
        default: return ""
        }
    }
}
