import Foundation
import CoreLocation

/// Manages a local buffer of frames to ensure uploads happen sequentially,
/// preventing network congestion and handling low-bandwidth scenarios.
actor FrameUploadQueue {
    
    // MARK: - Properties
    
    // Storing (Frame Data, Location)
    private var queue: [(Data, CLLocation?)] = []
    private var isProcessing = false
    private let geminiService: GeminiService
    
    // MARK: - Initialization
    
    init(geminiService: GeminiService) {
        self.geminiService = geminiService
    }
    
    // MARK: - API
    
    /// Adds a frame to the upload queue and triggers processing if idle.
    func enqueue(frame: Data, location: CLLocation? = nil) {
        queue.append((frame, location))
        print("FrameUploadQueue: Enqueued frame. Queue size: \(queue.count)")
        
        if !isProcessing {
            isProcessing = true
            Task {
                await processQueue()
            }
        }
    }
    
    // MARK: - Internal Processing
    
    private func processQueue() async {
        while !queue.isEmpty {
            let (frame, location) = queue.removeFirst()
            
            do {
                print("FrameUploadQueue: Processing frame...")
                let description = try await geminiService.generateDescription(from: frame, location: location)
                print("FrameUploadQueue: Success! Description: \(description)")
            } catch {
                print("FrameUploadQueue: Upload failed: \(error)")
                // For MVP, we drop the frame on error to avoid blocking the queue indefinitely.
                // In a production app, we might implement a Retry Policy or DLQ.
            }
        }
        
        isProcessing = false
        print("FrameUploadQueue: Queue drained.")
    }
}
