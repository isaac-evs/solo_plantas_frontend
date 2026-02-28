//
//  ScanViewModel.swift
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
    
    var detectedCategoryLabel: String {
        matchedCategory?.rawValue.uppercased() ?? "—"
    }

    
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
                 
            self.scanComplete = true
        }
    }
    
    // --- Logic ---
    
    private func classifyPlant(from color: Color, unlockedIDs: Set<String>) {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let h = hue * 360.0

        print("Scan: Hue: \(Int(h))° Sat: \(String(format: "%.2f", saturation)) Bright: \(String(format: "%.2f", brightness))")

        if saturation < 0.15 && brightness > 0.75 {
            matchedCategory = .white
            print("Scan: → white (low saturation, high brightness)")

        } else if brightness < 0.15 {
            matchedCategory = .green
            print("Scan: → dark/black, unreliable")

        } else if saturation < 0.15 {
            matchedCategory = .white
            print("Scan: → gray → white")

        // --- Hue-based classification ---
        } else {
            switch h {

            case 330...360, 0..<15:
                if brightness > 0.7 && saturation < 0.6 {
                    matchedCategory = .purple
                } else {
                    matchedCategory = .orange
                }

            case 15..<45:
                matchedCategory = .orange

            case 45..<70:
                matchedCategory = .yellow

            case 70..<85:
                matchedCategory = .yellow

            case 85..<165:
                matchedCategory = .green

            case 165..<195:
                matchedCategory = .blue

            case 195..<260:
                matchedCategory = .blue

            case 260..<330:
                matchedCategory = .purple

            default:
                matchedCategory = .green
            }

            print("Scan: Hue: \(Int(h))° → \(matchedCategory?.rawValue ?? "unknown")")
        }

        // --- Filter catalog ---
        let allPlants = DataService.shared.catalog
        
        self.matchedPlants = allPlants.filter { plant in
            guard !unlockedIDs.contains(plant.id) else { return false }
            
            if self.matchedCategory == .green {
                return true
            }
            
            return plant.dominantColor == self.matchedCategory
        }
    }
}
