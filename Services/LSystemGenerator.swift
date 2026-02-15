//
//  LSystemGenerator.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import Foundation
import RealityKit
import UIKit

class LSystemGenerator {
    
    // --- Types ---
    struct Rules {
        let axiom: String
        let rule: [Character: String]
        let angle: Float
    }
    
    // --- Logic ---
    ///Converts PlantDNA into specific set of growth rules
    static func getRules(for dna: PlantDNA) -> Rules {
        /// Tall Plants
        if dna.shapeRatio < 0.8 {
            return Rules (
                axiom: "X",
                rule: ["X": "F-[[X]+X]+F[+FX]-X", "F": "FF"],
                angle: 25.0)
        }
        
        /// Wide Plants
        else if dna.shapeRatio > 1.2 {
            return Rules(
                axiom: "X",
                rule: ["X": "F[+X]F[-X]+X", "F": "FF"],
                angle: 20.0)
        }
        /// Balanced
        else {
            return Rules(
                axiom: "X",
                rule: ["X": "F[+X][-X]FX", "F": "FF"],
                angle: 22.5)
        }
    }

    // Recursive function for generating sequence
    static func generateString(dna: PlantDNA, iterations: Int) -> String {
        let rules = getRules(for: dna)
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
        }
        
        return currentString
    }
    
    // --- 3D Generation ---
    
    // Convert String into RealityKit Model
    @MainActor
    static func generateModel(dna: PlantDNA, iterations: Int) -> Entity {
        
        print("3D Generation: Startin from Iteration: \(iterations).") // DEBUG
        
        if iterations == 0 {
            print(("3D Generation: Iteration is 0, returning empty root.")) // DEBUG
            return Entity()
        }
        
        let lSystemString = generateString(dna: dna, iterations: iterations)
        print("3D Generation: String Length is \(lSystemString.count) characters.") // DEBUG
        
        let rules = getRules(for: dna)
        let rootEntity = Entity()
        
        var nodeStack: [Entity] = []
        var currentNode: Entity = rootEntity
        
        let branchLength: Float = 0.05
        let branchRadius: Float = 0.005
        
        // --- Mesh Instancing ---
        
        let sharedMesh = MeshResource.generateBox(size: [branchRadius, branchLength, branchRadius])
        
        let sharedmaterial = SimpleMaterial(
                    color: UIColor(
                        red: CGFloat(dna.colorComponents[0]),
                        green: CGFloat(dna.colorComponents[1]),
                        blue: CGFloat(dna.colorComponents[2]),
                        alpha: 1.0
                    ),
                    isMetallic: false
                )
        // -----------------------
        

        var branchCount = 0 // DEBUG
        
        for char in lSystemString {
            switch char {
            case "F":
                // Create Mesh
                let branch = ModelEntity(mesh: sharedMesh, materials: [sharedmaterial])
                
                // Move it up half its length
                branch.position.y = branchLength / 2
                
                // Attach it
                currentNode.addChild(branch)
                
                // Create a tip as anchor to next segment
                let tip = Entity()
                tip.position.y = branchLength / 2
                branch.addChild(tip)
                currentNode = tip
                
                branchCount += 1 // DEBUG
                
            case "X":
                break
            
            case "+":
                // Rotate Right
                currentNode.orientation *= simd_quatf(angle: rules.angle * .pi / 180, axis: [0,0,1])
            
            case "-":
                // Rotate Left
                currentNode.orientation *= simd_quatf(angle: -rules.angle * .pi / 180, axis: [0,0,1])
            
            case "[":
                // Start Branch
                nodeStack.append(currentNode)
                
            case "]":
                // End Branch
                if let lastNode = nodeStack.popLast(){
                    currentNode = lastNode
                }
                
            default:
                break
            }
        }
        
        print("3D Generation: Finished. Created \(branchCount) branches.") // DEBUG
        return rootEntity
    }
}
