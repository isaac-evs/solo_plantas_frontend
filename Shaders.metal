//
//  Shaders.metal
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 17/02/26.
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

using namespace metal;

// ──────────────────────────────────────────────────────────────────────────────
// MARK: - Noise Helpers
// ──────────────────────────────────────────────────────────────────────────────

float hash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
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

// ──────────────────────────────────────────────────────────────────────────────
// MARK: - Geometry Modifier
// Adds a subtle hand-drawn wobble to every vertex.
// ──────────────────────────────────────────────────────────────────────────────

[[visible]]
void handDrawnGeometry(realitykit::geometry_parameters params) {
    float3 pos    = params.geometry().model_position();
    float wobbleX = sin(pos.y * 50.0) * 0.002;
    float wobbleZ = cos(pos.y * 40.0) * 0.002;
    params.geometry().set_model_position_offset(float3(wobbleX, 0.0, wobbleZ));
}

// ──────────────────────────────────────────────────────────────────────────────
// MARK: - Surface Shader
// Watercolor look: edge darkening (Fresnel) + procedural grain.
// ──────────────────────────────────────────────────────────────────────────────

[[visible]]
void watercolorSurface(realitykit::surface_parameters params) {

    // Base colour from material constant
    float3 baseColor = params.material_constants().base_color_tint();

    // Fresnel: NdotV == 1 → centre, 0 → edge
    float3 viewDir   = params.geometry().view_direction();
    float3 normal    = params.geometry().normal();
    float  NdotV     = abs(dot(normal, viewDir));
    float  edgeFactor = smoothstep(0.1, 0.5, NdotV);

    // Procedural paper grain
    float2 uv   = params.geometry().uv0() * 200.0;
    float  grain = noise(uv);

    // Colour mix
    float3 centerColor = baseColor + float3(grain) * 0.1;
    float3 edgeColor   = float3(0.05, 0.05, 0.05);
    float3 finalColor  = mix(edgeColor, centerColor, edgeFactor);

    // Output — emissive so it is unaffected by scene lighting
    params.surface().set_base_color(half3(0.0));
    params.surface().set_emissive_color(half3(finalColor));
    params.surface().set_roughness(1.0);
    params.surface().set_metallic(0.0);
    params.surface().set_specular(0.0);
    params.surface().set_opacity(1.0);
}
