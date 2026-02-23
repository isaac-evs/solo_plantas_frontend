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

    // --- String Generator ---

    static func generateString(dna: LSystemDNA, iterations: Int) -> String {
        var current = dna.axiom
        for _ in 0..<iterations {
            var next = ""
            for ch in current {
                let charString = String(ch)
                if let replacement = dna.rules[charString] {
                    next += replacement
                } else {
                    next += charString
                }
            }
            current = next
            if current.count > 150_000 { break }
        }
        return current
    }
    
    // --- Cache Materials ---
    
    @MainActor private static var materialCache: [String: (any RealityKit.Material)] = [:]
    
    @MainActor
    private static func getMaterial(hexColor: String) -> any RealityKit.Material {
        if let cached = materialCache[hexColor] { return cached }
        
        let rgb = hexColor.toRGB()
        let mat = WatercolorMaterialFactory.create(
            color: UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        )
        materialCache[hexColor] = mat
        return mat
    }

    // --- Generate Model ---
    
    @MainActor
    static func generateModel(species: PlantSpecies, iterations: Int) async -> Entity {
        guard iterations > 0 else { return Entity() }
        
        let dna = species.lsystem
        let angleRad = dna.branchAngle * .pi / 180.0
        
        let growthScale = Float(iterations - 2) / Float(4 - 2)
        let thicknessScale = 0.5 + 0.5 * growthScale
        
        // --- Offload from the main thread ---
        
        let (branchBuilder, leafBuilder, flowerBuilder) = await Task.detached(priority: .userInitiated) {
            
            // Pass DNA to the string generator
            let LString = generateString(dna: dna, iterations: iterations)
            
            let branchBuilder = MeshBuilder()
            let leafBuilder   = MeshBuilder()
            let flowerBuilder = MeshBuilder()
            
            struct TurtleState {
                var transform: simd_float4x4
                var radiusTaper: Float
                var lengthTaper: Float
            }
            
            var stack: [TurtleState] = []
            var state = TurtleState(
                transform: matrix_identity_float4x4,
                radiusTaper: 1.0,
                lengthTaper: 1.0
            )
            
            let baseRadius: Float = dna.baseThickness *  thicknessScale
            let baseLength: Float = dna.baseThickness * 4.5
            let sides = 7
            
            // Rotation Axes
            let rotZ_pos = simd_float4x4(rotationAngle:  angleRad, axis: [0, 0, 1])
            let rotZ_neg = simd_float4x4(rotationAngle: -angleRad, axis: [0, 0, 1])
            let rotX_pos = simd_float4x4(rotationAngle:  angleRad, axis: [1, 0, 0])
            let rotX_neg = simd_float4x4(rotationAngle: -angleRad, axis: [1, 0, 0])
            
            for ch in LString {
                switch ch {
                case "F":
                    let clampedRadius = max(state.radiusTaper, 0.35)
                    let r = baseRadius * clampedRadius
                    let l = baseLength * state.lengthTaper
                    
                    branchBuilder.addTube(
                        transform: state.transform,
                        bottomRadius: r,
                        topRadius: r * 0.88,
                        length: l,
                        sides: sides
                    )
                    
                    var advance = matrix_identity_float4x4
                    advance.columns.3.y = l
                    state.transform = state.transform * advance
                    
                    state.radiusTaper *= 0.88
                    state.lengthTaper *= dna.lengthMultiplier
                    
                case "X":
                    let leafSize = dna.leafScale * max(state.radiusTaper, 0.4)
                    leafBuilder.addLeaf(transform: state.transform, size: leafSize)

                case "O":
                    let flowerSize = dna.flowerScale * max(state.radiusTaper, 0.4)
                    flowerBuilder.addFlower(transform: state.transform, size: flowerSize)
                    
                case "+": state.transform = state.transform * rotZ_pos
                case "-": state.transform = state.transform * rotZ_neg
                case "^": state.transform = state.transform * rotX_pos
                case "&": state.transform = state.transform * rotX_neg
                case "[":
                    stack.append(state)
                    let yaw = Float.random(in: 0 ..< 2 * .pi)
                    let yawMat = simd_float4x4(rotationAngle: yaw, axis: [0, 1, 0])
                    state.transform = state.transform * yawMat
                case "]":
                    if let saved = stack.popLast() { state = saved }
                default: break
                }
            }
            return (branchBuilder, leafBuilder, flowerBuilder)
        }.value
        
        // --- Main Actor ---
        
        let branchMat = getMaterial(hexColor: dna.stemColor)
        let leafMat   = getMaterial(hexColor: dna.leafColor)
        let flowerMat = getMaterial(hexColor: dna.flowerColor)
        
        let root = Entity()
        if let bm = branchBuilder.build() { root.addChild(ModelEntity(mesh: bm, materials: [branchMat])) }
        if let lm = leafBuilder.build()   { root.addChild(ModelEntity(mesh: lm, materials: [leafMat])) }
        if let fm = flowerBuilder.build() { root.addChild(ModelEntity(mesh: fm, materials: [flowerMat])) }
        
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
    
    // --- Flower: central disc + radiating petals ---

    func addFlower(transform: simd_float4x4, size: Float) {
        addFlowerDisc(transform: transform, radius: size * 0.25)
        let petalCount = 6
        for i in 0..<petalCount {
            let angle = Float(i) / Float(petalCount) * 2 * .pi
            addPetal(transform: transform, petalAngle: angle, size: size)
        }
    }

    private func addFlowerDisc(transform: simd_float4x4, radius: Float) {
        let base = UInt32(positions.count)
        let sides = 8
        let worldN = normalize(rotateVector([0, 1, 0], by: transform))

        // Centre
        let centerW = transform * SIMD4<Float>(0, 0, 0, 1)
        positions.append(SIMD3(centerW.x, centerW.y, centerW.z))
        normals.append(worldN)
        uvs.append([0.5, 0.5])

        for i in 0..<sides {
            let theta = Float(i) / Float(sides) * 2 * .pi
            let lp = SIMD4<Float>(radius * cos(theta), 0, radius * sin(theta), 1)
            let wp = transform * lp
            positions.append(SIMD3(wp.x, wp.y, wp.z))
            normals.append(worldN)
            uvs.append(SIMD2(0.5 + 0.5 * cos(theta), 0.5 + 0.5 * sin(theta)))
        }

        for i in 0..<UInt32(sides) {
            let curr = base + 1 + i
            let next = base + 1 + (i + 1) % UInt32(sides)
            indices.append(contentsOf: [base, curr, next])
            indices.append(contentsOf: [base, next, curr]) // back face
        }
    }

    private func addPetal(transform: simd_float4x4, petalAngle: Float, size: Float) {
        let base = UInt32(positions.count)

        let cosA = cos(petalAngle)
        let sinA = sin(petalAngle)
        let outward  = SIMD3<Float>(cosA, 0, sinA)
        let sideways = SIMD3<Float>(-sinA, 0, cosA)

        let petalLength = size
        let petalWidth  = size * 0.45
        let petalLift   = size * 0.15

        // base-left, base-right, tip-right, tip-left
        let localCorners: [SIMD3<Float>] = [
            outward * size * 0.2 - sideways * petalWidth * 0.4,          // base left
            outward * size * 0.2 + sideways * petalWidth * 0.4,          // base right
            outward * (size * 0.2 + petalLength) + sideways * petalWidth * 0.2 + [0, petalLift, 0], // tip right
            outward * (size * 0.2 + petalLength) - sideways * petalWidth * 0.2 + [0, petalLift, 0], // tip left
        ]

        let worldN     = normalize(rotateVector([0, 1, 0], by: transform))
        let worldNBack = -worldN

        // Front face vertices
        for (idx, c) in localCorners.enumerated() {
            let wp = transform * SIMD4<Float>(c.x, c.y, c.z, 1)
            positions.append(SIMD3(wp.x, wp.y, wp.z))
            normals.append(worldN)
            uvs.append(leafUV(idx))
        }
        // Back face vertices
        for (idx, c) in localCorners.enumerated() {
            let wp = transform * SIMD4<Float>(c.x, c.y, c.z, 1)
            positions.append(SIMD3(wp.x, wp.y, wp.z))
            normals.append(worldNBack)
            uvs.append(leafUV(idx))
        }

        // Front
        indices.append(contentsOf: [base+0, base+1, base+2, base+0, base+2, base+3])
        // Back
        let b2 = base + 4
        indices.append(contentsOf: [b2+0, b2+2, b2+1, b2+0, b2+3, b2+2])
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
