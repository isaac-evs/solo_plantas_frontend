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
                        .foregroundStyle(.white)
                    
                    Slider(value : $growthStage, in: 1...4, step: 1)
                        .accentColor(plant.swiftUIColor)
                        .padding(.horizontal)
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
        
        // Add Coaching Overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Handle Taps
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    
        context.coordinator.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
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
                self.lastRenderedIterations = 1
                placePlant(at: firstResult.worldTransform, iterations: 1)
            }
        }
        
        func placePlant(at transform: simd_float4x4, iterations: Int) {
            guard let arView = arView else { return }
            
            if let oldAnchor = plantAnchor {
                arView.scene.removeAnchor(oldAnchor)
            }
            
            let anchor = AnchorEntity(world: transform)
            
            // Create Plant Model
            let plantModel = LSystemGenerator.generateModel(dna: plant, iterations: iterations)
            
            anchor.addChild(plantModel)
            arView.scene.addAnchor(anchor)
            
            self.plantAnchor = anchor
        }
        
        func updateGrowth(iterations: Int){
            guard let currentAnchor = plantAnchor else { return }
            if iterations == lastRenderedIterations { return }
            
            lastRenderedIterations = iterations
            
            // Keep position but replace model
            placePlant(at: currentAnchor.transform.matrix, iterations: iterations )
        }
    }
}
