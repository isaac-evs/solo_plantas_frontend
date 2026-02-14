import SwiftUI

struct RootView: View {
    // Intialize Mission Control
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        Group {
            if let plant = viewModel.capturePlant {
                // If we have DNA, show the AR Garden
                ARGardenView(plant: plant)
                    .environemntObject(viewModel)
            } else {
                // If not keep scanning
                ScanView()
                    .environmentObject(viewModel)
            }
        }
    }
}
