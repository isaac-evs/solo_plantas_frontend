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
    @ObservedObject var viewModel: ARGardenViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(config)
        }
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        return arView
    }
        
    func updateUIView(_ uiView: ARView, context: Context) {
        Task {
            await context.coordinator.syncPlantMesh(iteration: viewModel.currentIteration)
        }
    }
        
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
        
    @MainActor
    class Coordinator: NSObject {
        var arView: ARView?
        let viewModel: ARGardenViewModel
            
        var baseAnchor: AnchorEntity?
        var potEntity: ModelEntity?
        var currentPlantEntity: Entity?
        
        var lastRenderedIteration: Int = -1
        private var growthTask: Task<Void, Never>?
            
        init(viewModel: ARGardenViewModel){
            self.viewModel = viewModel
        }
            
        // --- Tap Logic ---
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            if viewModel.state == .scanning {
                // Raycast and Place Pot
                let tapLocation = sender.location(in: arView)
                let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
                
                if let result = results.first {
                    let anchor = AnchorEntity(raycastResult: result)
                    arView.scene.addAnchor(anchor)
                    self.baseAnchor = anchor
                    
                    loadPot()
                    viewModel.markPotPlaced()
                }
            } else if viewModel.state == .placed {
                // Plant Seed
                viewModel.plantSeed()
            }
        }
        
        // --- Mesh  ---
        
                private func loadPot() {
                    guard let anchor = baseAnchor else { return }
                    
                    if let url = Bundle.main.url(forResource: "pot1", withExtension: "usdz"),
                       let pot = try? ModelEntity.loadModel(contentsOf: url) {
                        
                        let targetHeightMeters: Float = 0.20
                        let originalHeight: Float     = 1.9902356
                        let uniformScale              = targetHeightMeters / originalHeight
                        pot.scale                     = SIMD3<Float>(repeating: uniformScale)
                        
                        let bounds = pot.visualBounds(relativeTo: nil)
                        pot.position.y = -bounds.min.y
                        
                        anchor.addChild(pot)
                        self.potEntity = pot
                    }
                }
                
                func syncPlantMesh(iteration: Int) async {
                    guard let anchor = baseAnchor, iteration > 0 else { return }
                    if iteration == lastRenderedIteration { return }
                    lastRenderedIteration = iteration
                    
                    growthTask?.cancel()
                    growthTask = Task {
                        let newPlant = await LSystemGenerator.generateModel(species: viewModel.plant, iterations: iteration)
                        guard !Task.isCancelled else { return }
                        
                        if let oldPlant = currentPlantEntity {
                            anchor.removeChild(oldPlant)
                        }

                        if let pot = potEntity {
                            let potBoundsInWorld = pot.visualBounds(relativeTo: anchor)
                            
                            newPlant.position.y = potBoundsInWorld.max.y - 0.01
                        }
                        
                        anchor.addChild(newPlant)
                        currentPlantEntity = newPlant
                    }
                }
    }
}
