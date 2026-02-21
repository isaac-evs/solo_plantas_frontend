//
//  WatercolorMaterial.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 18/02/26.
//

import RealityKit
import UIKit

// Create Custom Material
struct WatercolorMaterialFactory {
    
    // Load Metal Library
    private static let library: MTLLibrary? = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal : Device creation failed") // DEBUG
            return nil;
        }
        let defaultLibrary = device.makeDefaultLibrary()
        
        if defaultLibrary == nil {
            print("Metal: Library not found ") // DEBUG
        }
        
        return defaultLibrary
    }()
    
    static func create(color: UIColor) -> Material {
        
        print("Custom Material: Creating Custom Material") // DEBUG
        
        // Unwrap library
        guard let library = library else {
            print("Custom Material: Metal Library not found") // DEBUG
            return SimpleMaterial(color: color, isMetallic: false)
        }
        
        // Create Surface Shader
        let surfaceShader = CustomMaterial.SurfaceShader(
            named: "watercolorSurface",
            in: library
        )
        
        // Create Geometry Shader
        let geometryShader = CustomMaterial.GeometryModifier(
            named: "handDrawnGeometry",
            in: library
        )
        
        // Create Material
        do {
            var material = try CustomMaterial(
                surfaceShader: surfaceShader,
                geometryModifier: geometryShader,
                lightingModel: .lit
            )
    
            material.baseColor = CustomMaterial.BaseColor(tint: color)
            material.blending = .opaque
            
            print("Custom Material : Created custom material") // DEBUG
            return material
        } catch {
            print("Custom Material : Failed to crate custom material: \(error)") // DEBUG
            return SimpleMaterial(color: color, isMetallic: false)
        }
        
    }
}
