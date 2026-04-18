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
        let shaderSource = """
        #include <metal_stdlib>
        #include <RealityKit/RealityKit.h>
        
        using namespace metal;
        
        // Random Noise Functions
        float hash(float2 p) {
            return fract(sin(dot(p, float2(12.9898, 78.233)))* 43758.5453);
        }
        
        float noise(float2 p) {
            float2 i = floor(p);
            float2 f = fract(p);
            float a = hash(i);
            float b = hash(i + float2(1.0, 0.0));
            float c = hash(i + float2(0.0, 1.0));
            float d = hash(i + float2(1.0, 1.0));
            float2 u = f * f * (3.0 - 2.0 * f);
            return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }
        
        // --- Geometry Modifier ---
        [[visible]]
        void handDrawnGeometry(realitykit::geometry_parameters params){
            float3 pos = params.geometry().model_position();
            float wobbleX = sin(pos.y * 50.0) * 0.002;
            float wobbleZ = cos(pos.y * 40.0) * 0.002;
            params.geometry().set_model_position_offset(float3(wobbleX, 0.0, wobbleZ));
        }
        
        // --- Surface Shader ---
        [[visible]]
        void watercolorSurface(realitykit::surface_parameters params) {
            float3 baseColor = params.material_constants().base_color_tint();
            float3 viewDir = params.geometry().view_direction();
            float3 normal = params.geometry().normal();
            float NdotV = abs(dot(normal, viewDir));
            float edgeFactor = smoothstep(0.1, 0.5, NdotV);
            float2 uv = params.geometry().uv0() * 200.0;
            float grain = noise(uv);
            float3 centerColor = baseColor + (float3(grain) * 0.1);
            float3 edgeColor = float3(0.05, 0.05, 0.05);
            float3 finalColor = mix(edgeColor, centerColor, edgeFactor);
            params.surface().set_base_color(half3(0.0));
            params.surface().set_emissive_color(half3(finalColor));
            params.surface().set_roughness(1.0);
            params.surface().set_metallic(0.0);
            params.surface().set_specular(0.0);
            params.surface().set_opacity(1.0);
        }
        """
        
        do {
            let compiledLibrary = try device.makeLibrary(source: shaderSource, options: nil)
            return compiledLibrary
        } catch {
            print("Metal: Library compilation failed: \\(error)") // DEBUG
            return nil
        }
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
