import SwiftUI

struct RootView: View {
    // Connect to Mission Control
    @EnvironmentObject var viewModel: CameraViewModel
    
    var body: some View {
        Group {
            if let plant = viewModel.capturePlant {
                // If we have DNA, show the AR Garden
                ARGardenView(plant: plant)
            } else {
                // If not keep scanning
                ScanView()
            }
        }
    }
}
