import Foundation
import CoreLocation

/// Protocol abstraction for AI services.
/// Allows swapping implementation (Gemini, Mock, OpenAI) without changing consumers.
public protocol AIService {
    /// Generates text content based on a prompt.
    /// - Parameter prompt: The input prompt for the AI.
    /// - Returns: The generated text string.
    func generateText(prompt: String) async throws -> String
    
    /// Generates a description for an image (multimodal).
    /// - Parameters:
    ///   - imageData: The raw data of the image.
    ///   - location: Optional location context.
    /// - Returns: A textual description of the image.
    func generateDescription(from imageData: Data, location: CLLocation?) async throws -> String
}
