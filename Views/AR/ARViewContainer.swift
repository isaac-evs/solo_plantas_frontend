//
//  ARViewContainer.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 20/02/26.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    let species: PlantSpecies
    let growthStage: Int
    
    @Binding var isPlanted: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Horizontal plane detection
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(config)
        }
        
        // Coaching Overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Taps
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        return arView
        
        }
        
        func updateUIView(_ uiView: ARView, context: Context){
            if isPlanted {
                context.coordinator.updateGrowth(iterations: growthStage)
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(species: species, isPlanted: $isPlanted)
        }
        
        // --- Coordinator ---
        @MainActor
        class Coordinator: NSObject {
            var arView: ARView?
            let species: PlantSpecies
            var isPlanted: Binding<Bool>
            
            var plantAnchor: AnchorEntity?
            var lastRenderedIterations: Int = -1
            
            init(species: PlantSpecies, isPlanted: Binding<Bool>){
                self.species = species
                self.isPlanted = isPlanted
            }
            
            @objc func handleTap(_ sender: UITapGestureRecognizer){
                guard let arView = arView else { return }
                let tapLocation = sender.location(in: arView)
                let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
                
                if let firstResult = results.first {
                    print("Handle Tap: Valid Surface Found.")
                    
                    // If we have a pot, move it, if not, create it
                    if let oldAnchor = plantAnchor {
                        arView.scene.removeAnchor(oldAnchor)
                    }
                    
                    let newAnchor = AnchorEntity(raycastResult: firstResult)
                    arView.scene.addAnchor(newAnchor)
                    self.plantAnchor = newAnchor
                    
                    // Plant is in the floor
                    DispatchQueue.main.async {
                        self.isPlanted.wrappedValue = true
                    }
                    
                    self.lastRenderedIterations = -1
                    updateGrowth(iterations: 1)
                }
            }
            
            func updateGrowth(iterations: Int) {
                
                // Dont accept values below 0
                let safeIterations = max(1, iterations)
                
                guard let anchor = plantAnchor else { return }
                
                // Prevent duplicate
                if iterations == lastRenderedIterations { return }
                
                // Remove old branches
                anchor.children.removeAll()
                
                // Generate new plant
                let plantModel = LSystemGenerator.generateModel(species: species, iterations: safeIterations)
                
                anchor.addChild(plantModel)
                
                self.lastRenderedIterations = iterations
            }
        }
}
