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
    @Published var extractedColor : UIColor = .clear
    
    
    // --- Internal Propierties ---
    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var isConfigured = false
    
    // Performance limiter
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
                internalStart()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted { self?.internalStart() }
                }
            default:
                print("Camera : Access Denied")
            }
        }
        
        private func internalStart() {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                
                if !self.isConfigured {
                    self.configureSession()
                    self.isConfigured = true
                }
                
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    // --- Initialization Logic ---
    private func configureSession(){
        self.session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if self.session.canAddInput(input) {
            self.session.addInput(input)
        }
                
        // Output config
        self.output.setSampleBufferDelegate(self, queue: self.sessionQueue)
        self.output.alwaysDiscardsLateVideoFrames = true
        self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                
        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
        }
                
        self.session.commitConfiguration()
       
    }
}

// --- Frame Processing ---
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        
        // Skip Frames to save battery
        frameCounter += 1
        if frameCounter % frameSkip != 0 { return }
        
        // Get Raw Pixel Buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Lock memory address to read it
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        // Unlock when we are done
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        // Calculate Center Region
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // 20 x 20 sampling center square
        let sampleSize = 20
        let startX = (width - sampleSize) / 2
        let startY = (height - sampleSize) / 2
        
        // Read Pixels
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
                // offset + 1 = Green
                // offset + 2 = Red
                // offset + 3 = Alpha
                
                bTotal += Int(buffer[offset])
                gTotal += Int(buffer[offset + 1])
                rTotal += Int(buffer[offset + 2])
            }
        }
        
        // Average
        let pixelCount = sampleSize * sampleSize
        let rAvg = CGFloat(rTotal / pixelCount) / 255.0
        let gAvg = CGFloat(gTotal / pixelCount) / 255.0
        let bAvg = CGFloat(bTotal / pixelCount) / 255.0
        
        let newColor = UIColor(red: rAvg, green: gAvg, blue: bAvg, alpha: 1.0)
        
        // Update UI (Main Thread)
        DispatchQueue.main.async {
            self.extractedColor = newColor
        }
    }
}

