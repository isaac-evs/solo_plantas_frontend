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
    
    // --- Types ---
    struct Rules {
        let axiom: String
        let rule: [Character: String]
        let angle: Float
    }
    
    // --- Logic ---
    ///Converts PlantDNA into specific set of growth rules
    static func getRules(for type: GrowthType) -> Rules {
        switch type {
        case .tall:
            return Rules(
                axiom: "X",
                rule: ["X": "F-[[X]+X]+F[+FX]-X", "F": "FF"],
                angle: 25.0)
        case .wide:
            return Rules(
                axiom: "X",
                rule: ["X": "F[+X]F[-X]+X", "F": "F"],
                angle: 35.0)
        case .balanced:
            return Rules(
                axiom: "X",
                rule: ["X": "F-[[X]+X]+F[+FX]-X", "F": "FF"],
                angle: 22.5)
        }
    }

    // Recursive function for generating sequence
    static func generateString(type: GrowthType, iterations: Int) -> String {
        let rules = getRules(for: type)
        var currentString = rules.axiom
        
        for _ in 0..<iterations {
            var nextString = ""
            
            for char in currentString {
                if let replacement = rules.rule[char] {
                    nextString += replacement
                } else {
                    nextString += String(char)
                }
            }
            currentString = nextString
            
            if currentString.count > 20000 {
                print("L-SYSTEM: Reached Safety limit.") // DEBUG
                break
            }
        }
        
        return currentString
    }
    
    // --- 3D Generation ---
    
    // Convert String into RealityKit Model
    @MainActor
    static func generateModel(species: PlantSpecies, iterations: Int) -> Entity {

        
        if iterations == 0 {
            print(("3D Generation: Iteration is 0, returning empty root.")) // DEBUG
            return Entity()
        }
        
        let lSystemString = generateString(type: species.growthType, iterations: iterations)
        print("3D Generation:: Iteration \(iterations) | String Length: \(lSystemString.count)") // DEBUG
        
        let rules = getRules(for: species.growthType)
        
        let rootEntity = Entity()
        
        var transformStack: [simd_float4x4] = []
        var scaleStack: [SIMD3<Float>] = []
        
        var currentTransform = matrix_identity_float4x4
        var currentScale: SIMD3<Float> = [1,1,1]
        
        let branchLength: Float = 0.05
        let branchRadius: Float = 0.008
        
        // --- Mesh Instancing ---
        
        // Branch Mesh
        let branchMesh = MeshResource.generateBox(size: [branchRadius, branchLength, branchRadius])
        
        // Leaf Mesh
        let leafMesh = MeshResource.generateSphere(radius: 0.015)
        
        // Hardcore Colors
        var r : CGFloat = 0.3, g: CGFloat = 0.6, b: CGFloat = 0.2
        if species.id == "salvia" { r = 0.6; g = 0.2; b = 0.6 }
        if species.id == "agave" { r = 0.3; g = 0.5; b = 0.6 }
        if species.id == "primavera" { r = 0.9; g = 0.8; b = 0.2 }
        
        let plantColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        let plantMaterial = WatercolorMaterialFactory.create(color: plantColor)
        
        // Rotation Matrices
        let angleRad = rules.angle * .pi / 180
        let rotateLeft = simd_float4x4(rotationAngle: angleRad, axis:[0, 0, 1])
        let rotateRight = simd_float4x4(rotationAngle: -angleRad, axis:[0, 0, 1])

        // Batching
        var currentBatch = Entity()
        rootEntity.addChild(currentBatch)
        var batchCount = 0;
        var totalBranchCount = 0
        
        // Safety Limit
        let maxBranches = 4000
        
        for char in lSystemString {
            
            if totalBranchCount >= maxBranches {
                print("3D Generator: Max branch count (\(maxBranches)) reached. Stopping to prevent crash.")
                break
            }
    
            switch char {
            case "F":
                // --- Draw Branch ---
                let branch = ModelEntity(mesh: branchMesh, materials: [plantMaterial])
                branch.scale = currentScale
    
                // Position the Branch
                var geometryOffset = matrix_identity_float4x4
                geometryOffset.columns.3.y = branchLength / 2
                
                branch.transform.matrix = currentTransform * geometryOffset
                currentBatch.addChild(branch)
                
                totalBranchCount += 1
                
                // Batching
                batchCount += 1
                if batchCount > 500 {
                    currentBatch = Entity()
                    rootEntity.addChild(currentBatch)
                    batchCount = 0
                }
                
                // Transform Up
                var moveUp = matrix_identity_float4x4
                moveUp.columns.3.y = branchLength
                currentTransform = currentTransform * moveUp
                
                // Tapper next segment
                currentScale *= 0.95
                
            case "X":
                // --- Draw Leaf ---
                let leaf = ModelEntity(mesh: leafMesh, materials: [plantMaterial])
                leaf.scale = [1.5, 0.2, 1.5]
                
                leaf.transform.matrix = currentTransform
                
                currentBatch.addChild(leaf)
                
                totalBranchCount += 1
                
                batchCount += 1
                if batchCount > 500 {
                    currentBatch = Entity()
                    rootEntity.addChild(currentBatch)
                    batchCount = 0
                }
                
            
            case "+":
                // Rotate Right
                currentTransform = currentTransform * rotateLeft
            
            case "-":
                // Rotate Left
                currentTransform = currentTransform * rotateRight
            
            case "[":
                // Push
                transformStack.append(currentTransform)
                scaleStack.append(currentScale)
                
                // Randomly rotate branch around the trunk
                let randomRot = Float.random(in: 0...(2 * .pi))
                let yRotMatrix = simd_float4x4(rotationAngle: randomRot, axis: [0, 1, 0])
                currentTransform = currentTransform * yRotMatrix
                
            case "]":
                // Pop
                if let savedTransform = transformStack.popLast(),
                   let savedScale = scaleStack.popLast() {
                    currentTransform = savedTransform
                    currentScale = savedScale
                }
                
            default:
                break
            }
        }
        
        print("3D Generation: Finished. Created \(totalBranchCount) branches.") // DEBUG
        return rootEntity
    }
}

// --- Matrix Math Extension ---
extension simd_float4x4 {
    init (rotationAngle angle: Float, axis: SIMD3<Float>) {
        let quaternion = simd_quatf(angle: angle, axis: axis)
        self = simd_float4x4(quaternion)
    }
}
