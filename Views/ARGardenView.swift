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
    
    var body: some View {
        ZStack {
            ARViewContainer(plant: plant)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Text("Tap on the floor to plant your garden")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.bottom, 50)
            }
        }
    }
}

// ---- ARViewContainer ---
struct ARViewContainer: UIViewRepresentable {
    let plant: PlantDNA
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // 1. Horizontal Plane Detection
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        // Check if device supports it
        if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(config)
        }
        
        // 2. Add Coaching Overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // 3. Handle Taps
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(plant: plant)
    }
    
    // --- Coordinator ---
    @MainActor
    class Coordinator: NSObject {
        var arView: ARView?
        let plant: PlantDNA
        
        init(plant: PlantDNA) {
            self.plant = plant
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer){
            guard let arView = arView else { return }
            
            // 1. Get tap location
            let tapLocation = sender.location(in: arView)
            
            // 2. Raycast to find a plane
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            // 3. If we founf a surface, place the plant
            if let firstResult = results.first {
                placePlant(at: firstResult.worldTransform)
            }
        }
        
        func placePlant(at transform: simd_float4x4) {
            guard let arView = arView else { return }
            
            let anchor = AnchorEntity(world: transform)
            
            // Create Material
            let color = UIColor(
                red: CGFloat(plant.colorComponents[0]),
                green: CGFloat(plant.colorComponents[1]),
                blue: CGFloat(plant.colorComponents[2]),
                alpha: 1.0
            )
            
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: color, isMetallic: false)
            let model = ModelEntity(mesh: mesh, materials: [material])
            
            // Lift slightly to sits on floor, not inside it
            model.position.y = 0.05
            
            anchor.addChild(model)
            arView.scene.addAnchor(anchor)
                
        }
    }
}
