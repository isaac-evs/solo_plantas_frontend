//
//  CameraViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 14/02/26.
//

import SwiftUI
import Combine

// Coordinates the scanning process and the final PlantDNA generation
class CameraViewModel: ObservableObject {
    
    // --- Dependencies ---
    let cameraService = CameraService()
    
    // --- Published Properties ---
    
    /// Currently captured DNA, when set move AR View
    @Published var capturePlant: PlantDNA? = nil
    
    /// Tracks if we are in a scan
    @Published var isScanning: Bool = false
    
    /// Temp Storage for plants variables
    @Published var currentRGB: [Float] = [0.0, 1.0, 0.0]
    @Published var liveColor: Color = .green
    @Published var measuredHeight: Float = 0.5 // Default 0.5 meters
    @Published var measuredShapeRatio: Float = 1.0 // Default 1.0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(){
        // Subscribe Camera Color update
        cameraService.$extractedColor
            .compactMap { $0 }
            .sink { [weak self] cgColor in
                guard let self = self else { return }
        
            // Convert CGColor to SwiftUI Color for display
            self.liveColor = Color(cgColor: cgColor)
            
            // Convert to [Float]
                if let components =  cgColor.components, components.count >= 3 {
                    self.currentRGB = [
                        Float(components[0]),   // Red
                        Float(components[1]),  // Green
                        Float(components[2])  //  Blue
                    ]
                }
        }
            .store(in: &cancellables)
    }
    
    // --- Actions ---
    
    /// Resets State to start a new Scan
    func resetScan(){
        capturePlant = nil
        isScanning = true
    }
    
    /// Finalizes the data collection and generates the PlantDNA object
    func generatePlant(){
        let newPlant = PlantDNA(
            colorComponents: currentRGB,
            height: measuredHeight,
            shapeRatio: measuredShapeRatio,
            timestamp: Date()
        )
        
        // Trigger to switch UI to AR
        self.capturePlant = newPlant
    }
}

