import CoreGraphics
import Foundation

/// Defines a standardized source for video frames.
/// This abstraction allows us to swap between the Local Camera (MVP)
/// and External Sources (Network Streams, Pis) without changing the core logic.
public protocol VideoSourceProtocol: AnyObject {
    /// The unified stream of video frames.
    /// Consumers (DirectorService) listen to this stream regardless of the source.
    var frameStream: AsyncStream<CGImage> { get }
    
    /// Prepares the source (permissions, connections).
    func prepare() async throws
    
    /// Starts the capture session.
    func start() async
    
    /// Stops the capture session.
    func stop()
}
