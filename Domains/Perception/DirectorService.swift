import Foundation
import CoreGraphics
import Observation

/// The "Director" of the show.
/// Responsible for analyzing the video feed and deciding what to capture.
@Observable
public class DirectorService {
    private let videoSource: VideoSourceProtocol
    
    // Live Diagnostics for UI
    public var isRunning = false
    public var frameCount = 0
    public var lastFrame: CGImage? // For UI Preview
    
    public init(videoSource: VideoSourceProtocol = LocalCameraSource()) {
        self.videoSource = videoSource
    }
    
    public func startSession() async {
        do {
            print("Director: Preparing Session...")
            try await videoSource.prepare()
            
            print("Director: Starting Camera...")
            await videoSource.start()
            
            self.isRunning = true
            self.observeStream()
            
        } catch {
            print("Director Error: \(error)")
        }
    }
    
    public func stopSession() {
        videoSource.stop()
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
                }
                
                // TODO: AI Analysis logic will go here
                // if self.frameCount % 30 == 0 { analyze(frame) }
            }
        }
    }
}
