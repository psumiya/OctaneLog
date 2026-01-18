import Foundation
import CoreGraphics
import CoreImage

/// A mock video source that emits a static placeholder frame.
/// Used for SwiftUI Previews to prevent accessing the physical camera.
public class MockCameraSource: VideoSourceProtocol {
    
    public var frameStream: AsyncStream<CGImage> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    private var continuation: AsyncStream<CGImage>.Continuation?
    private var task: Task<Void, Never>?
    
    public init() {}
    
    public func prepare() async throws {
        // No-op for mock
    }
    
    public func start() async {
        // Start emitting a dummy frame every second
        task = Task {
            while !Task.isCancelled {
                if let frame = createPlaceholderFrame() {
                    continuation?.yield(frame)
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1fps
            }
        }
    }
    
    public func stop() {
        task?.cancel()
        task = nil
        continuation?.finish()
    }
    
    private func createPlaceholderFrame() -> CGImage? {
        let width = 1080
        let height = 1920
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0))
        context?.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw an "X" or text would be harder without UIKit/AppKit imports in generic context,
        // so just a colored rect is fine for now.
        return context?.makeImage()
    }
}
