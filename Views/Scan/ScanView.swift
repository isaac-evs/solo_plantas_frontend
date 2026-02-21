////
////  ScanView.swift
////  VirtualGarden
////
////  Created by Isaac Vazquez Sandoval on 14/02/26.
////
//
//import SwiftUI
//
//struct ScanView : View {
//    
//    @EnvironmentObject var viewModel: CameraViewModel
//    
//    var body: some View {
//        ZStack {
//            // Live Camera Feed
//            CameraPreview(session: viewModel.cameraService.session)
//                .ignoresSafeArea()
//            
//            // Targeting Reticle
//            Circle()
//                .strokeBorder(Color.white, lineWidth: 2)
//                .frame(width: 30, height: 30)
//                .shadow(radius: 4)
//            
//            // Dashboard
//            VStack {
//                Spacer()
//                
//                scanDashboard
//            }
//            
//            .onAppear {
//                viewModel.cameraService.start()
//            }
//            .onDisappear {
//                viewModel.cameraService.stop()
//            }
//        }
//    }
//    
//    // --- Subviews ---
//    
//    var scanDashboard: some View {
//        VStack(spacing: 20) {
//            
//            // Color Indicator
//            HStack{
//                Text("Detected Color:")
//                    .fontWeight(.semibold)
//                    .foregroundColor(.white)
//                
//                Circle()
//                    .fill(viewModel.liveColor) // Live Camera Color
//                    .frame(width: 30, height: 30)
//                    .overlay(Circle().stroke(Color.white, lineWidth:  2))
//                
//                Spacer()
//            }
//            
//            // Height Input
//            VStack(alignment: .leading){
//                Text("Height: \(String(format: "%.2f", viewModel.measuredHeight)) m")
//                    .foregroundColor(.white)
//                    .font(.caption)
//                
//                Slider(value: $viewModel.measuredHeight, in: 0.1...2.0)
//                    .accentColor(viewModel.liveColor)
//            }
//            
//            
//            // Shape Input
//            VStack(alignment: .leading){
//                HStack {
//                    Text("Shape:")
//                        .foregroundColor(.white)
//                        .font(.caption)
//                    Spacer()
//                    Text(shapeDescription)
//                        .foregroundColor(.white.opacity(0.8))
//                        .font(.caption)
//                }
//                
//                Slider(value: $viewModel.measuredShapeRatio, in: 0.5...2.0)
//                    .accentColor(viewModel.liveColor)
//            }
//            
//            // Generate Button
//            Button(action: {
//                viewModel.generatePlant()
//            }){
//                Text("Generate Garden")
//                    .font(.headline)
//                    .foregroundColor(.black)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(12)
//            }
//            .padding(.top, 10)
//        }
//        .padding(24)
//        .background(
//            Color.black.opacity(0.6)
//                .cornerRadius(20, corners: [.topLeft, .topRight])
//                .ignoresSafeArea(edges: .bottom)
//            
//        )
//    }
//    
//    var shapeDescription: String {
//        if viewModel.measuredShapeRatio < 0.8 { return "Tall (Tree)"}
//        if viewModel.measuredShapeRatio > 1.2 { return "Wide (Bush)"}
//        return "Balanced"
//    }
//    
//}
//
//// Round Corners
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View{
//            clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}
//    
//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners:  UIRectCorner = .allCorners
//        
//    func path(in rect: CGRect) -> Path {
//        let path  = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
//        return Path(path.cgPath)
//    }
//}
