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
