//
//  LSystemGenerator.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import Foundation
import RealityKit
import UIKit
import simd

class LSystemGenerator {

    struct Rules {
        let axiom : String
        let rule : [Character: String]
        let angle : Float
    }
    
    static func getRules(for type: GrowthType) -> Rules {
        switch type {
        case .tall:
            return Rules(axiom: "X", rule: ["X": "F-[[X]+X]+F[+FX]-X", "F": "FF"], angle: 25.0)
        case .wide:
            return Rules(axiom: "X", rule: ["X": "F[+X]F[-X]+X", "F": "F"], angle: 35.0)
        case .balanced:
            return Rules(axiom: "X", rule: ["X": "F-[[X]+X]+F[+FX]-X", "F": "FF"], angle: 22.5)
        }
    }
    
    static func generateString(type: GrowthType, iterations: Int) -> String {
        let rules = getRules(for:type)
        var current = rules.axiom
        for _ in 0..<iterations {
            var next = ""
            for ch in current {
                next += rules.rule[ch].map { String($0) } ?? String(ch)
            }
            current = next
            if current.count > 150_000 {break}
        }
        return current
    }
    
    // --- Cache Materials ---
    
    @MainActor private static var branchMaterial: (any RealityKit.Material)?
    @MainActor private static var leafMaterials: [String: (any RealityKit.Material)] = [:]
    
    @MainActor
    private static func getBranchMaterial() -> any RealityKit.Material {
        if let cached = branchMaterial { return cached }
        let mat = WatercolorMaterialFactory.create(
            color: UIColor(red: 0.38, green: 0.28, blue: 0.18, alpha: 1))
        branchMaterial = mat
        return mat
    }

    @MainActor
    private static func getLeafMaterial(for speciesID: String, r: CGFloat, g: CGFloat, b: CGFloat) -> any RealityKit.Material {
        if let cached = leafMaterials[speciesID] { return cached }
        let mat = WatercolorMaterialFactory.create(
            color: UIColor(red: r, green: g, blue: b, alpha: 1))
        leafMaterials[speciesID] = mat
        return mat
    }
    
    // --- Generate Model ---
    
    @MainActor
    static func generateModel(species: PlantSpecies, iterations: Int) async -> Entity {
        guard iterations > 0 else { return Entity() }
        
        let rules = getRules(for: species.growthType)
        let angleRad = rules.angle * .pi / 180.0
        
        // --- Offload from the main thread ---
        let (branchBuilder, leafBuilder) = await Task.detached(priority: .userInitiated){
            
            let LString = generateString(type: species.growthType, iterations: iterations)
            
            let branchBuilder = MeshBuilder()
            let leafBuilder   = MeshBuilder()
            
            struct TurtleState {
                var transform: simd_float4x4   // orientiation matrix
                var radiusTaper: Float
                var lengthTaper: Float
            }
            
            var stack: [TurtleState] = []
            var state = TurtleState(
                transform: matrix_identity_float4x4,
                radiusTaper: 1.0,
                lengthTaper: 1.0
            )
            
            let baseRadius: Float = 0.012
            let baseLength: Float = 0.055
            let sides = 7
            
            // Rotation Axes
            let rotZ_pos = simd_float4x4(rotationAngle:  angleRad, axis: [0, 0, 1])
            let rotZ_neg = simd_float4x4(rotationAngle: -angleRad, axis: [0, 0, 1])
            let rotX_pos = simd_float4x4(rotationAngle:  angleRad, axis: [1, 0, 0])
            let rotX_neg = simd_float4x4(rotationAngle: -angleRad, axis: [1, 0, 0])
            
            for ch in LString {
                switch ch {
                    
                    
                case "F":
                    let r = baseRadius * state.radiusTaper
                    let l = baseLength * state.lengthTaper
                    
                    branchBuilder.addTube(
                        transform: state.transform,
                        bottomRadius : r,
                        topRadius: r *  0.82,
                        length: l,
                        sides: sides
                    )
                    
                    var advance = matrix_identity_float4x4
                    advance.columns.3.y = l
                    state.transform = state.transform * advance
                    state.radiusTaper *= 0.88
                    state.lengthTaper *= 0.94
                    
                case "X":
                    let leafSize = 0.025 * state.radiusTaper
                    leafBuilder.addLeaf(
                        transform: state.transform,
                        size: leafSize
                    )
                    
                case "+":
                    state.transform = state.transform * rotZ_pos
                    
                case "-":
                    state.transform = state.transform * rotZ_neg
                
                case "^":
                    state.transform = state.transform * rotX_pos
                    
                case "&":
                    state.transform = state.transform * rotX_neg
                
                case "[":
                    stack.append(state)
                    
                    // Randomiza azimuth
                    let yaw = Float.random(in: 0 ..< 2 * .pi)
                    let yawMat = simd_float4x4(rotationAngle: yaw, axis: [0, 1, 0])
                    state.transform = state.transform * yawMat
                
                case "]":
                    if let saved = stack.popLast() { state = saved }
                
                default:
                    break
                }
            }
            
            return (branchBuilder, leafBuilder)
        }.value
        
        // --- Main Actor ---
        
        // Leaf Colors
        let (r, g, b):  (CGFloat, CGFloat, CGFloat) = {
            switch species.id {
            case "salvia": return (0.60, 0.20, 0.65)
            case "agave":     return (0.25, 0.52, 0.58)
            case "primavera": return (0.92, 0.80, 0.18)
            default:          return (0.28, 0.62, 0.22)
            }
        }()

        let branchMat = getBranchMaterial()
        let leafMat   = getLeafMaterial(for: species.id, r: r, g: g, b: b)
        
        let root = Entity()
        if let bm = branchBuilder.build() { root.addChild(ModelEntity(mesh: bm, materials: [branchMat])) }
        if let lm = leafBuilder.build()   { root.addChild(ModelEntity(mesh: lm, materials: [leafMat])) }
        
        print("L System: branch tris: \(branchBuilder.indices.count / 3), leaf tris: \(leafBuilder.indices.count / 3)") // DEBUG
        return root
    }
}

// --- Mesh Builder --

final class MeshBuilder: @unchecked Sendable {
    
    // Buffers
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var uvs: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    
    // Tube Segment
    func addTube(
        transform: simd_float4x4,
        bottomRadius: Float,
        topRadius: Float,
        length: Float,
        sides: Int,
    ) {
        let base = UInt32(positions.count)
        let n = sides
        
        // Bottom and top ring
        for ring in 0...1 {
            let y = ring == 0 ? Float(0) : length
            let r = ring == 0 ? bottomRadius : topRadius
            let v = Float(ring)
            
            for i in 0..<n {
                let theta = Float(i) / Float(n) * 2 * .pi
                let cosT = cos(theta)
                let sinT = sin(theta)
                
                // Local ring position
                let localPos = SIMD4<Float>(r * cosT, y, r * sinT, 1)
                // Outward facing normal
                let slope = (bottomRadius - topRadius) / length
                let localNorm = normalize(SIMD3<Float>(cosT, slope, sinT))
                
                let worldPos = transform * localPos
                let worldnorm = normalize(rotateVector(localNorm, by: transform))
                
                let u = Float(i) / Float(n)
                positions.append(SIMD3(worldPos.x, worldPos.y, worldPos.z))
                normals.append(worldnorm)
                uvs.append(SIMD2(u, v))
                                
            }
        }
        
        // Stich rings into quads
        for i in 0..<UInt32(n) {
            let next = (i + 1) % UInt32(n)
            let b0 = base + i, b1 = base + next // bottom ring
            let t0 = base + UInt32(n) + i, t1 = base + UInt32(n) + next // top ring
            
            // CCW Triangles
            indices.append(contentsOf: [b0, t0, b1])
            indices.append(contentsOf: [b1, t0, t1])
        }
        
        // Cap the Bottom
        addDiskCap(transform: transform, y: 0, radius: bottomRadius, sides: n, faceUp: false)
        // Cap the top
        var topTransform = transform
        topTransform.columns.3 += transform.columns.1 * length
        addDiskCap(transform: topTransform, y:0, radius: topRadius, sides: n, faceUp: true)
    }
    
    private func addDiskCap(
        transform: simd_float4x4,
        y: Float,
        radius: Float,
        sides: Int,
        faceUp: Bool
    ) {
        guard radius > 0.0001 else { return }
        let base = UInt32(positions.count)
        let centerW = transform * SIMD4<Float>(0, y, 0, 1)
        let normDir: SIMD3<Float> = faceUp ? [0, 1, 0] : [0, -1, 0]
        let worldN = normalize(rotateVector(normDir, by: transform))
        
        // Centre Vertex
        positions.append(SIMD3(centerW.x, centerW.y, centerW.z))
        normals .append(worldN)
        uvs .append(SIMD2(0.5, 0.5))
        
        for i in 0..<sides {
            let theta = Float(i) / Float(sides) * 2 * .pi
            let lp = SIMD4<Float>(radius * cos(theta), y, radius * sin(theta), 1)
            let wp = transform * lp
            positions.append(SIMD3(wp.x, wp.y, wp.z))
            normals .append(worldN)
            uvs .append(SIMD2(0.5 + 0.5 * cos(theta), 0.5 + 0.5 * sin(theta)))
        }
        
        for i in 0..<UInt32(sides) {
            let curr = base + 1 + i
            let next = base + 1 + (i + 1) % UInt32(sides)
            if faceUp {
                indices.append(contentsOf: [base, curr, next])
            } else {
                indices.append(contentsOf: [base, next, curr])
            }
        }
    }
    
    // --- Leaf : two crossed quads ---
    
    func addLeaf(transform: simd_float4x4, size: Float) {
        addLeafPlane(transform: transform, size: size, normal: [0, 1, 0])
        addLeafPlane(transform: transform, size: size, normal: [1, 0, 0])
    }
    
    private func addLeafPlane(transform: simd_float4x4, size: Float, normal: SIMD3<Float>) {
        let base = UInt32(positions.count)
        
        // Perpendicular axes from the normal
        let up: SIMD3<Float> = [0, 1, 0]
        let right: SIMD3<Float> = normalize(cross(up, normal))
        let realUp = normalize(cross(normal, right))
        
        let corners: [SIMD3<Float>] = [
            -right * size - realUp * size * 0.3,
             right * size - realUp * size * 0.3,
             right * size * 0.6 + realUp * size,
             -right * size * 0.6 + realUp * size,
        ]
        
        let worldN = normalize(rotateVector(normal, by: transform))
        let worldNBack = -worldN
        
        for (idx, c) in corners.enumerated(){
            let lp = SIMD4<Float>(c.x, c.y, c.z, 1)
            let wp = transform * lp
            positions.append(SIMD3(wp.x, wp.y, wp.z))
            normals.append(worldN)
            uvs.append(leafUV(idx))
        }
        
        for (idx, c) in corners.enumerated(){
            let lp = SIMD4<Float>(c.x, c.y, c.z, 1)
            let wp = transform * lp
            positions.append(SIMD3(wp.x, wp.y, wp.z))
            normals.append(worldNBack)
            uvs.append(leafUV(idx))
        }
        
        //Front face
        indices.append(contentsOf: [base+0, base+1, base+2, base+0, base+2, base+3])
                       
        //Back face
        let b2 = base + 4
        indices.append(contentsOf: [b2+0, b2+2, b2+1, b2+0, b2+3, b2+2])
    }
    
    private func leafUV(_ i : Int) -> SIMD2<Float> {
        switch i {
        case 0: return [0,0]
        case 1: return [1,0]
        case 2: return [1,1]
        default: return [0,1]
        }
    }
    
    // --- Build ---
    @MainActor
    func build() -> MeshResource? {
        guard !positions.isEmpty else { return nil }
        
        var desc = MeshDescriptor(name: "plant")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        desc.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [desc])
    }
}

// -- Helper Functions ---

private func rotateVector(_ v: SIMD3<Float>, by m: simd_float4x4) -> SIMD3<Float> {
    let r = m * SIMD4<Float>(v.x, v.y, v.z, 0)
    return SIMD3(r.x, r.y, r.z)
}

extension simd_float4x4 {
    init(rotationAngle angle: Float, axis: SIMD3<Float>){
        self = simd_float4x4(simd_quatf(angle: angle, axis: normalize(axis)))
    }
}

// Async call:
// let plant = await LSystemGenerator.generateModel(species: species, iterations: iterations)
