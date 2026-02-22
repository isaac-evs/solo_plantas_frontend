//
//  CameraViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI
import Combine

@MainActor
class ScanViewModel: ObservableObject {
    
    // Dependencies
    let cameraService = CameraService()
    
    // UI State
    @Published var liveColor: Color = .clear
    @Published var isScanning: Bool = false
    @Published var scanComplete: Bool = false
    
    // Results
    @Published var matchedCategory: PlantColorCategory? = .green
    @Published var matchedPlants: [PlantSpecies] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(){
        cameraService.$extractedColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uiColor in
                guard let self = self else { return }
                // Update UI color
                self.liveColor = Color(uiColor: uiColor)
            }
            .store(in: &cancellables)
    }
    
    // --- Actions ---
    
    func startCamera(){
        cameraService.start()
        isScanning = false
        scanComplete = false
        matchedPlants = []
    }
    
    func stopCamera(){
        cameraService.stop()
    }
    
    func performScan(unlockedIDs: Set<String>) {
        isScanning = true
            
        let colorToAnalyze = self.liveColor
            
        Task { @MainActor in
             try? await Task.sleep(nanoseconds: 2_000_000_000)
                
            self.isScanning = false
            self.classifyPlant(from: colorToAnalyze, unlockedIDs: unlockedIDs)
                
            // Trigger the sheet directly
            self.scanComplete = true
        }
    }
    
    // --- Logic ---
    
    private func classifyPlant(from color: Color, unlockedIDs: Set<String>){
        // Convert SwiftUI Color to HSV values
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let hueDegrees = hue * 360.0
        
        if hueDegrees > 45 && hueDegrees < 85 {
            matchedCategory = .yellow
        } else if hueDegrees > 180 && hueDegrees < 250 {
            matchedCategory = .blue
        } else if (hueDegrees > 250 && hueDegrees < 330){
            matchedCategory = .purple
        } else {
            matchedCategory = .green
        }
        
        print("Scan: Hue: \(Int(hueDegrees))° Category: \(matchedCategory?.rawValue ?? "unknown")")
        
        // Filter DB
        let  allPlants = DataService.shared.catalog
        
        self.matchedPlants = allPlants.filter{ plant in
            plant.dominantColor == self.matchedCategory && !unlockedIDs.contains(plant.id)
        }
    }
}
