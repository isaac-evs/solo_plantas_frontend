//
//  Shaders.metal
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 17/02/26.
//

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
    
    // Get world position of the vertex
    float3 pos = params.geometry().model_position();
    
    // Calculate random offset
    float wobble = sin(pos.y * 20.0) * sin(pos.x * 20.0) * 0.002;
    
    // Apply offset
    params.geometry().set_model_position_offset(float3(wobble, 0.0, wobble));
}

// --- Surface Shader ---
[[visible]]
void watercolorSurface(realitykit::surface_parameters params) {
    
    // Get base color
    half3 baseColor = params.material_constants().base_color_tint();
    
    // Calculate fresnel
    float3 viewDir = normalize(params.geometry().world_position() - params.uniforms().camera_position());
    float3 normal = normalize(params.geometry().normal());
    float NdotV = 1.0 - abs(dot(normal, -viewDir));
    
    // Generate Noise (Grain)
    float2 uv = params.geometry().uv0() * 5.0;
    float grain = noise(uv);
    
    // Mix colors
    half3 centerColor = baseColor + (half3(grain) * 0.1);
    half3 edgeColor = baseColor * 0.5;
    float edgeFactor = smoothstep(0.5, 0.8, NdotV);
    half3 finalColor = mix(centerColor, edgeColor, half(edgeFactor));
    
    // Output
    params.surface().set_base_color(finalColor);
    params.surface().set_roughness(1.0);
    params.surface().set_metallic(0.0);
    params.surface().set_specular(0.0);
    
}
