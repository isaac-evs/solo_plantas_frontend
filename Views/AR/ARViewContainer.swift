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
        
    func updateUIView(_ uiView: ARView, context: Context){
        if viewModel.isPlanted {
            context.coordinator.updateGrowth(iterations: viewModel.currentStageInt)
        }
    }
        
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
        
    // --- Coordinator ---
    @MainActor
    class Coordinator: NSObject {
        var arView: ARView?
        let viewModel: ARGardenViewModel
            
        var plantAnchor: AnchorEntity?
        var lastRenderedIterations: Int = -1
            
        init(viewModel: ARGardenViewModel){
            self.viewModel = viewModel
        }
            
        @objc func handleTap(_ sender: UITapGestureRecognizer){
            guard let arView = arView else { return }
            let tapLocation = sender.location(in: arView)
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
                
            if let firstResult = results.first {
                print("Handle Tap: Valid Surface Found.")
                    
                if let oldAnchor = plantAnchor {
                    arView.scene.removeAnchor(oldAnchor)
                }
                    
                let newAnchor = AnchorEntity(raycastResult: firstResult)
                arView.scene.addAnchor(newAnchor)
                self.plantAnchor = newAnchor
                    
                DispatchQueue.main.async {
                    self.viewModel.markAsPlanted()
                }
                    
                self.lastRenderedIterations = -1
                updateGrowth(iterations: viewModel.currentStageInt)
            }
        }
            
        func updateGrowth(iterations: Int) {
            let safeIterations = max(1, iterations)
            guard let anchor = plantAnchor else { return }
            if safeIterations == lastRenderedIterations { return }
                
            anchor.children.removeAll()
            let plantModel = LSystemGenerator.generateModel(species: viewModel.plant, iterations: safeIterations)
            anchor.addChild(plantModel)
                
            self.lastRenderedIterations = safeIterations
        }
    }
}
