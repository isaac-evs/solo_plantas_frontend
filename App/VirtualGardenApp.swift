import SwiftUI

@main
struct VirtualGardenApp: App {
    // Initiliaze Mission Control
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ViewModel)
        }
    }
}

