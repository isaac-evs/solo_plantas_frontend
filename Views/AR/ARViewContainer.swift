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
            context.coordinator.updateGrowth(iterations: growthStage)
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
                    
                    // If we have a pot, move it, if not, create it
                    if let existingAnchor = plantAnchor {
                        existingAnchor.move(to: firstResult.worldTransform, relativeTo: nil)
                    } else {
                        let newAnchor = AnchorEntity(world: firstResult.worldTransform)
                        arView.scene.addAnchor(newAnchor)
                        self.plantAnchor = newAnchor
                        
                        // Tell SwiftUI is on the floor to show slider
                        DispatchQueue.main.async {
                            self.isPlanted.wrappedValue = true
                        }
                    }
                    
                    self.lastRenderedIterations = -1
                    updateGrowth(iterations: 1)
                }
            }
            
            func updateGrowth(iterations: Int) {
                guard let anchor = plantAnchor else { return }
                if iterations == lastRenderedIterations { return }
                
                anchor.children.removeAll()
                
                let plantModel = LSystemGenerator.generateModel(species: species, iterations: iterations)
                
                anchor.addChild(plantModel)
                
                self.lastRenderedIterations = iterations
            }
        }
}
