//
//  CameraService.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 14/02/26.
//

import AVFoundation
import UIKit
import CoreVideo

// Dedicated Service to manage the hardware camera
final class CameraService: NSObject, ObservableObject, @unchecked Sendable {
    
    // --- Published Propierties ---
    /// Live Color
    @Published var extractedColor : CGColor? = nil
    /// Publish authorization status
    @Published var isAuthorized = false
    
    
    // --- Internal Propierties ---
    
    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private var isConfigured = false
    
    private var frameCounter = 0
    private let frameSkip = 10
    
    
    // --- Init ---
    override init() {
        super.init()
    }
    
    // --- Lyfecycle Control ---
    
    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            self.setupAndStart()
            
        case .notDetermined:
            // Ask for permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupAndStart()
                }
            }
            
        case .denied, .restricted:
            print("Camera Access Denied")
            
        @unknown default:
            break
        }
    }
    
    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    // --- Initialization Logic ---
    private func setupAndStart(){
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 1. Configure it
            if !self.isConfigured {
                self.configureSession()
                self.isAuthorized = true
            }
            
            // 2. Update UI
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            
            // 3. Start Running
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    
    // Configure the input (Camera) and output (Data)
    private func configureSession(){
        self.session.beginConfiguration()
            
        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device) else { return }
            
        if self.session.canAddInput(input){ self.session.addInput(input) }
            
        // 2. Output
        self.output.setSampleBufferDelegate(self, queue: self.queue)
        self.output.alwaysDiscardsLateVideoFrames = true
        self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

        if self.session.canAddOutput(self.output){ self.session.addOutput(self.output)}
            
        self.session.commitConfiguration()
        
    }
}

// --- Frame Processing ---
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        
        // 1. Skip Frames to save battery
        frameCounter += 1
        if frameCounter % frameSkip != 0 { return }
        
        // 2. Get Raw Pixel Buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 3. Lock memory address to read it
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        // Unlock when we are done
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        // 4. Calculate Center Region
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // 20 x 20 sampling center square
        let sampleSize = 20
        let startX = (width - sampleSize) / 2
        let startY = (height - sampleSize) / 2
        
        // 5. Read Pixels
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        var rTotal: Int = 0
        var gTotal: Int = 0
        var bTotal: Int = 0
        
        // Loop trough center square
        for y in startY..<(startY + sampleSize) {
            for x in startX..<(startX + sampleSize){
                let offset = (y * bytesPerRow) + (x * 4)
                
                // BGRA format:
                // offset + 0 = Blue
                // offset + 0 = Green
                // offset + 0 = Red
                // offset + 0 = Alpha
                
                let b = Int(buffer[offset])
                let g = Int(buffer[offset + 1])
                let r = Int(buffer[offset + 2])
                
                rTotal += r
                gTotal += g
                bTotal += b
            }
        }
        
        // 6. Average
        let pixelCount = sampleSize * sampleSize
        let rAvg = CGFloat(rTotal / pixelCount) / 255.0
        let gAvg = CGFloat(gTotal / pixelCount) / 255.0
        let bAvg = CGFloat(bTotal / pixelCount) / 255.0
        
        let newColor = CGColor(srgbRed: rAvg, green: gAvg, blue: bAvg, alpha: 1.0)
        
        // 7. Update UI (Main Thread)
        DispatchQueue.main.async {
            self.extractedColor = newColor
        }
    }
}
