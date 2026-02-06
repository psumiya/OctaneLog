import Foundation
import AVFoundation
import CoreLocation
import Observation
#if canImport(UIKit)
import UIKit
#endif

/// The "Director" of the show.
/// Responsible for capturing video clips of the drive.
@Observable
public class DirectorService: NSObject {
    public let locationService = LocationService()
    public let visionAnalyzer = VisionAnalyzer()
    
    // Live Diagnostics for UI
    public var isRunning = false
    
    // Video Recording
    public let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // Multi-Clip Management
    public private(set) var recordedClips: [URL] = []
    private var currentDriveID: UUID?
    
    // Dependencies
    private let cameraQueue = DispatchQueue(label: "com.octanelog.camera")
    
    public override init() {
        super.init()
        self.configureSession()
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480 // 480p is sufficient for AI analysis
        
        // Add Video Input
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let videoInput = try? AVCaptureDeviceInput(device: videoDevice) {
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                self.videoDeviceInput = videoInput
            }
        }
        
        // Audio Input Removed per user request.
        
        // Add Movie Output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    public func startSession() async {
        print("Director: Starting Session...")
        
        // Check Camera Permissions first
        let authorized = await checkCameraPermission()
        guard authorized else {
            print("Director: Camera access denied or restricted.")
            return
        }
        
        self.currentDriveID = UUID() // New Drive ID
        self.recordedClips.removeAll()
        self.events.removeAll()
        self.currentRoute.removeAll()
        
        // Start Location (Must be on Main Thread) and wait for authorization
        await MainActor.run {
            self.locationService.requestPermission()
        }
        
        // Give location service a moment to process permission
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        await MainActor.run {
            self.locationService.startMonitoring()
        }
        
        self.setupLocationObserver()
        
        // Start Camera Flow
        cameraQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            // Wait a moment for session to stabilize then start recording
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startRecordingClip()
            }
        }
        
        await MainActor.run {
            self.isRunning = true
            self.logEvent("Drive started at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))")
        }
        
        print("Director: Session started. Location authorized: \(self.locationService.isAuthorized)")
    }
    
    private func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    public func stopSession() {
        print("Director: Stopping Session...")
        
        // Stop Location
        self.locationService.stopMonitoring()
        
        // Stop Recording
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        
        cameraQueue.async {
            self.captureSession.stopRunning()
        }
        
        self.isRunning = false
    }
    
    // MARK: - Foreground/Background Defenses
    
    /// Called when App enters Background (ScenePhase)
    public func handleBackgrounding() {
        guard isRunning else { return }
        print("Director: App Backgrounded. Stopping current clip.")
        if movieOutput.isRecording {
            movieOutput.stopRecording() // Saves file to disk
        }
    }
    
    /// Called when App enters Foreground (ScenePhase)
    public func handleForegrounding() {
        guard isRunning else { return }
        print("Director: App Foregrounded. Starting new clip.")
        // AVCaptureSession might have stopped if not entitled, so restart check
        cameraQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            // Start NEW clip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startRecordingClip()
            }
        }
    }
    
    private func startRecordingClip() {
        guard let driveID = self.currentDriveID else { return }
        guard !movieOutput.isRecording else { return }
        
        // Create directory: Documents/Drives/[DriveID]/
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let driveDir = paths[0].appendingPathComponent("Drives").appendingPathComponent(driveID.uuidString)
        
        try? FileManager.default.createDirectory(at: driveDir, withIntermediateDirectories: true)
        
        // File Name: clip_[Timestamp].mov
        let clipName = "clip_\(Int(Date().timeIntervalSince1970)).mov"
        let outputURL = driveDir.appendingPathComponent(clipName)
        
        print("Director: Starting Recording to \(outputURL.lastPathComponent)")
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
    }
    
    // MARK: - Legacy / Diagnostics
    // No more frame stream observation.
    
    // MARK: - Event Logging
    public var events: [String] = []
    private var currentRoute: [RoutePoint] = []
    private var lastState: DriveState = .stationary
    private var lastLocationLogTime: Date = Date.distantPast
    
    private func setupLocationObserver() {
        locationService.onLocationUpdate = { [weak self] location, driveState in
            guard let self = self else { return }
            self.handleLocationUpdate(location: location, state: driveState)
        }
    }
    
    private func handleLocationUpdate(location: CLLocation, state: DriveState) {
        let now = Date()
        
        // Track Route (Relaxed Accuracy - accept initial GPS fixes)
        // Urban environments often have 200-500m accuracy initially
        if location.horizontalAccuracy > 0 && location.horizontalAccuracy < 500 {
            self.currentRoute.append(RoutePoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: location.timestamp
            ))
        }

        let timeSinceLastLog = now.timeIntervalSince(lastLocationLogTime)
        
        // Log if state changed significantly
        if state != self.lastState {
            self.logEvent("State changed to [\(state.rawValue)] - Speed: \(Int(locationService.currentSpeed)) mph")
            self.lastState = state
            self.lastLocationLogTime = now
            return
        }
        
        // Log heartbeat
        let heartbeatInterval: TimeInterval = state == .stationary ? 300 : 60
        if timeSinceLastLog >= heartbeatInterval {
             let coordinate = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
             self.logEvent("Heartbeat: [\(state.rawValue)] - Speed: \(Int(locationService.currentSpeed)) mph @ \(coordinate)")
             self.lastLocationLogTime = now
        }
    }
    
    public func logEvent(_ description: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        self.events.append("[\(timestamp)] \(description)")
        // print("Director: Event Logged -> \(description)")
    }
    
    public func finishDrive() -> (events: [String], route: [RoutePoint], videoClips: [URL]) {
        self.logEvent("Drive ended at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))")
        let capturedEvents = self.events
        let capturedRoute = self.currentRoute
        let clips = self.recordedClips
        
        print("Director: Finishing drive - \(capturedEvents.count) events, \(capturedRoute.count) route points, \(clips.count) video clips")
        
        self.events.removeAll()
        self.currentRoute.removeAll()
        self.currentDriveID = nil
        
        return (capturedEvents, capturedRoute, clips)
    }
    
    /// Analyzes video clips using Vision framework to extract metadata
    /// This is called by NarrativeAgent to get local analysis before sending to Gemini
    public func analyzeVideoClips(_ clips: [URL]) async -> [VisionAnalyzer.DriveAnalysis] {
        var analyses: [VisionAnalyzer.DriveAnalysis] = []
        
        for clip in clips {
            do {
                let analysis = try await visionAnalyzer.analyzeVideo(url: clip, sampleInterval: 5.0)
                analyses.append(analysis)
            } catch {
                print("Director: Failed to analyze clip \(clip.lastPathComponent): \(error)")
            }
        }
        
        return analyses
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension DirectorService: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Director: Recording Finished with Error: \(error.localizedDescription)")
             // If success flag is false, check if file exists (might be partial)
        } else {
            print("Director: Clip Saved Successfully. \(outputFileURL.lastPathComponent)")
        }
        
        // Append to session clips
        self.recordedClips.append(outputFileURL)
    }
}
