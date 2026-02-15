//
//  ARGardenView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import SwiftUI
import RealityKit
import ARKit

struct ARGardenView: View{
    let plant: PlantDNA
    
    @State private var growthStage: Float = 1.0
    
    var body: some View {
        ZStack {
            ARViewContainer(plant: plant, growthStage: Int(growthStage))
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                VStack {
                    Text("Growth Stage: \(Int(growthStage))")
                        .foregroundColor(.white)
                    
                    Slider(value : $growthStage, in: 1...4, step: 1)
                        .accentColor(plant.swiftUIColor)
                        .padding(.horizontal)
                        .onChange(of: growthStage){ newValue in
                            print("Slider: Snapped to \(Int(newValue))") // DEBUG
                        }
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
                .padding()
            }
        }
    }
}

// ---- ARViewContainer ---
struct ARViewContainer: UIViewRepresentable {
    let plant: PlantDNA
    let growthStage: Int
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Horizontal Plane Detection
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        // Check if device supports it
        if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(config)
        }
        
        // Coaching Overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Handle Gestures
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    
        context.coordinator.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        print("View: updateUIView called with stage \(growthStage)")
        context.coordinator.updateGrowth(iterations: growthStage)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(plant: plant)
    }
    
    // --- Coordinator ---
    @MainActor
    class Coordinator: NSObject {
        var arView: ARView?
        let plant: PlantDNA
        var plantAnchor: AnchorEntity?
        var lastRenderedIterations: Int = -1
        
        init(plant: PlantDNA) {
            self.plant = plant
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer){
            guard let arView = arView else { return }
            let tapLocation = sender.location(in: arView)
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                print("Handle Tap: Valid Surface Found.") // DEBUG
                
                // Manage Anchor
                if let existingAnchor = plantAnchor {
                    // If we already have an anchor just move it
                    existingAnchor.move(to: firstResult.worldTransform, relativeTo: nil)
                } else {
                    // If not, create a new anchor
                    let newAnchor = AnchorEntity(world: firstResult.worldTransform)
                    arView.scene.addAnchor(newAnchor)
                    self.plantAnchor = newAnchor
                }
                
                // Force Redraw
                self.lastRenderedIterations = -1
                updateGrowth(iterations: 1)
            }
        }
        
        func updateGrowth(iterations: Int){
            guard let anchor = plantAnchor else { return }
            
            if iterations == lastRenderedIterations { return }
            
            print("Update Growth: Updating to Stage: \(iterations).") // DEBUG
            
            anchor.children.removeAll()
            
            // Generate Plant
            let plantModel = LSystemGenerator.generateModel(dna: plant, iterations: iterations)
            
            anchor.addChild(plantModel)
                        
            self.lastRenderedIterations = iterations
        }
    }
}
