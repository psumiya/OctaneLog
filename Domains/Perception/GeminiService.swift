import Foundation
import Observation
import GoogleGenerativeAI

/// Service responsible for interacting with the Google Gemini ecosystem.
/// Supports both Gemini 3 Flash (fast, real-time) and Pro (complex synthesis).
@Observable
public class GeminiService {
    
    // MARK: - Properties
    
    private var apiKey: String = ""
    private var client: GenerativeModel?
    
    // MARK: - Initialization
    
    public init() {
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty {
            self.configure(with: key)
        }
    }
    
    // MARK: - Configuration
    
    public func configure(with apiKey: String) {
        self.apiKey = apiKey
        // Using "gemini-2.5-flash" as discovered from the user's API capabilities.
        // This is a multimodal model capable of both text and vision.
        self.client = GenerativeModel(name: "gemini-2.5-flash", apiKey: apiKey)
        print("GeminiService: Configured with API Key (Using gemini-2.5-flash).")
    }
    
    // MARK: - Core Features
    
    /// Generates text content from a simple string prompt.
    public func generateText(prompt: String) async throws -> String {
        guard let client = client else {
            throw GeminiError.notConfigured
        }
        
        do {
            let response = try await client.generateContent(prompt)
            return response.text ?? "No text generated."
        } catch {
            print("GeminiService Text Error: \(error)")
            throw error
        }
    }
    
    /// Generates a description for the provided image data (JPEG/PNG).
    public func generateDescription(from imageData: Data) async throws -> String {
        guard let client = client else {
            throw GeminiError.notConfigured
        }
        
        do {
            let prompt = "Describe what you see in this image in one brief sentence."
            
            // gemini-2.5-flash is multimodal.
            // We pass [prompt, image_data]
            let contentStream = client.generateContentStream(prompt, ModelContent.Part.jpeg(imageData))
            
            var fullText = ""
            for try await chunk in contentStream {
                if let text = chunk.text {
                    fullText += text
                }
            }
            
            return fullText.isEmpty ? "No description generated." : fullText
            
        } catch {
            print("GeminiService Vision Error: \(error)")
            throw error
        }
    }
}

public enum GeminiError: Error {
    case notConfigured
}
