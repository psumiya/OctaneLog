import Foundation
import CoreGraphics
import Observation

/// The "Director" of the show.
/// Responsible for analyzing the video feed and deciding what to capture.
@Observable
public class DirectorService {
    private let videoSource: VideoSourceProtocol
    public let locationService = LocationService()
    
    // Live Diagnostics for UI
    public var isRunning = false
    public var frameCount = 0
    public var lastFrame: CGImage? // For UI Preview
    
    public init(videoSource: VideoSourceProtocol? = nil) {
        if let source = videoSource {
            self.videoSource = source
        } else {
            #if targetEnvironment(simulator)
            self.videoSource = MockCameraSource()
            #else
            self.videoSource = LocalCameraSource()
            #endif
        }
    }
    
    public func startSession() async {
        do {
            print("Director: Preparing Session...")
            try await videoSource.prepare()
            
            // Start Location Monitoring
            self.locationService.requestPermission() 
            self.locationService.startMonitoring()
            
            print("Director: Starting Camera...")
            await videoSource.start()
            
            self.isRunning = true
            self.logEvent("Drive started at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))")
            self.observeStream()
            
        } catch {
            print("Director Error: \(error)")
        }
    }
    
    public func stopSession() {
        videoSource.stop()
        locationService.stopMonitoring()
        self.isRunning = false
    }
    
    private func observeStream() {
        Task {
            print("Director: Watching Stream...")
            for await frame in videoSource.frameStream {
                // Main Thread Update for UI Preview
                await MainActor.run {
                    self.frameCount += 1
                    
                    // Throttle preview updates to 10fps to save UI resources
                    if self.frameCount % 3 == 0 {
                        self.lastFrame = frame
                    }
                    
                    // Dynamic AI Analysis
                    self.analyzeFrameIfNeeded(frame)
                }
            }
        }
    }
    
    // MARK: - Smart Capture Logic
    // MARK: - Smart Capture Logic
    private var lastAnalysisTime: Date = Date.distantPast
    private let privacyService = PrivacyService()
    
    // Using FrameUploadQueue to handle uploads sequentially
    private let uploadQueue = FrameUploadQueue(geminiService: GeminiService())

    private func analyzeFrameIfNeeded(_ frame: CGImage) {
        let now = Date()
        let interval = self.getAnalysisInterval()
        
        guard now.timeIntervalSince(lastAnalysisTime) >= interval else { return }
        
        // Update timestamp immediately to prevent double-firing
        self.lastAnalysisTime = now
        
        // Don't analyze if we are effectively off
        if interval == .infinity { return }
        
        // Check for special "Stationary Check" (optional, for now we just respect the interval)
         print("Director: Triggering Analysis at Speed: \(locationService.currentSpeed) mph (State: \(locationService.driveState.rawValue))")
        
        Task {
            // Level 2 Privacy: On-Device Redaction
            guard let sanitizedData = await privacyService.scrub(image: frame) else {
                print("Director: Privacy Scrubbing Failed. Aborting upload.")
                return
            }
            
            // In a real app, we would fire the snapshot to Gemini here using sanitizedData.
            // We now send it to the queue which handles the upload.
            let currentLocation = self.locationService.lastLocation
            await uploadQueue.enqueue(frame: sanitizedData, location: currentLocation)
            
            await MainActor.run {
                var logMsg = "Enqueued [\(locationService.driveState.rawValue)] - \(sanitizedData.count) bytes"
                if let loc = currentLocation {
                    logMsg += " @ \(loc.coordinate.latitude),\(loc.coordinate.longitude)"
                }
                self.logEvent(logMsg)
            }
        }
    }
    
    private func getAnalysisInterval() -> TimeInterval {
        switch locationService.driveState {
        case .stationary:
            return 30.0 // Reduced from 120s to 30s for easier testing
        case .crawling:
            return 45.0 // 45 seconds
        case .cruising:
            return 15.0 // 15 seconds
        }
    }
    
    // MARK: - Event Logging (Narrative Source)
    public var events: [String] = []
    
    public func logEvent(_ description: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        self.events.append("[\(timestamp)] \(description)")
        print("Director: Event Logged -> \(description)")
    }
    
    /// Returns collected events and clears the buffer.
    public func finishDrive() -> [String] {
        self.logEvent("Drive ended at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))")
        let capturedEvents = self.events
        self.events.removeAll()
        return capturedEvents
    }
    /// Captures the current frame as JPEG Data.
    public func snapshot() -> Data? {
        guard let cgImage = self.lastFrame else { return nil }
        
        #if os(macOS)
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [:])
        #else
        // iOS / iPadOS approach using UIKit
        // We need to import UIKit conditionally if not available, but 'Foundation' + 'CoreGraphics' is usually enough for data,
        // however UIImage is the easiest utility. We will assume UIKit is available on iOS.
        // If we want to be pure, we use ImageIO.
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.jpegData(compressionQuality: 0.8)
        #endif
    }
}

#if os(macOS)
import AppKit
#else
import UIKit
#endif
