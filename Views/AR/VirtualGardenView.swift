import SwiftUI
import RealityKit
import ARKit

struct VirtualGardenView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            VirtualGardenARContainer(plants: assignedPlants())
                .ignoresSafeArea()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 56)
            .padding(.leading, 20)
        }
    }
    
    private func assignedPlants() -> [PlantSpecies] {
        let purchasedIDs = Array(appState.plantedDates.keys)
        return CatalogManager.shared.cachedCatalog.filter { purchasedIDs.contains($0.id) }
    }
}

struct VirtualGardenARContainer: UIViewRepresentable {
    let plants: [PlantSpecies]
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(config)
        }
        
        // Spawn models
        context.coordinator.spawnPlants(arView: arView, plants: plants)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    @MainActor
    class Coordinator: NSObject {
        func spawnPlants(arView: ARView, plants: [PlantSpecies]) {
            let anchor = AnchorEntity(plane: .horizontal)
            arView.scene.addAnchor(anchor)
            
            // Layout plants in a small grid offset matrix to avoid collision
            let spacing: Float = 0.5
            var row: Float = 0
            var col: Float = 0
            
            for (index, plant) in plants.enumerated() {
                // Break limitation to ensure it doesn't cause severe frame drops (max 5 meshes)
                if index >= 5 { break } 
                
                Task {
                    let mesh = await LSystemGenerator.generateModel(species: plant, iterations: 4)
                    
                    let xOffset = (col * spacing) - (spacing / 2)
                    let zOffset = (row * spacing) - (spacing / 2)
                    
                    mesh.position = [xOffset, 0, zOffset]
                    anchor.addChild(mesh)
                }
                
                col += 1
                if col > 2 {
                    col = 0
                    row += 1
                }
            }
        }
    }
}
