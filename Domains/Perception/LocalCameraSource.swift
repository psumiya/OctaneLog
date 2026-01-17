import AVFoundation
import CoreImage
import CoreGraphics
import UIKit

/// MVP Implementation of VideoSourceProtocol using the iPhone's Camera.
class LocalCameraSource: NSObject, VideoSourceProtocol {
    
    var frameStream: AsyncStream<CGImage> {
        AsyncStream { continuation in
            self.frameContinuation = continuation
        }
    }
    
    private var frameContinuation: AsyncStream<CGImage>.Continuation?
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.octanelog.cameraQueue")
    private var isAuthorized = false
    
    override init() {
        super.init()
    }
    
    func prepare() async throws {
        // 1. Check Permissions
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
        
        guard isAuthorized else {
            throw CameraError.unauthorized
        }
        
        // 2. Configure Session
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    func start() async {
        guard isAuthorized else { return }
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            self.frameContinuation?.finish()
            self.frameContinuation = nil
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            print("Failed to access back camera")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)
        
        // Output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        // Discard frames if processor is busy (Crucial for realtime AI)
        output.alwaysDiscardsLateVideoFrames = true 
        
        guard captureSession.canAddOutput(output) else {
            print("Failed to add video output")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(output)
        
        // Rotate to Portrait if needed (MVP assumes Portrait for now)
        if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        captureSession.commitConfiguration()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension LocalCameraSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let nav = self.frameContinuation else { return }
        
        // Convert CMSampleBuffer to CGImage
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: cvBuffer)
        
        // Note: CIContext creation is expensive if done every frame. 
        // In a Production app, we'd cache this. For MVP, we let CoreImage handle it internally.
        let context = CIContext() 
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        nav.yield(cgImage)
    }
}

enum CameraError: Error {
    case unauthorized
}
