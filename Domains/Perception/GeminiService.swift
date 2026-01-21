import Foundation
import Observation
import GoogleGenerativeAI

/// Service responsible for interacting with the Google Gemini ecosystem.
/// Supports both Gemini 3 Flash (fast, real-time) and Pro (complex synthesis).
@Observable
public class GeminiService {
    
    // MARK: - Properties
    
    private var apiKey: String = ""
    private var fastClient: GenerativeModel?      // gemini-3.0-flash (Speed/Vision)
    private var reasoningClient: GenerativeModel? // gemini-3.0-pro (Reasoning/Navigator)
    
    // MARK: - Initialization
    
    public init() {
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty {
            self.configure(with: key)
        }
    }
    
    // MARK: - Configuration
    
    public func configure(with apiKey: String) {
        self.apiKey = apiKey
        
        // UPGRADE TO GEMINI 3.0
        // Flash for high-frequency video analysis
        self.fastClient = GenerativeModel(name: "gemini-3.0-flash", apiKey: apiKey)
        
        // Pro for deep reasoning and narrative generation (Marathon Agent)
        self.reasoningClient = GenerativeModel(name: "gemini-3.0-pro", apiKey: apiKey)
        
        print("GeminiService: Configured (Flash 3.0 & Pro 3.0).")
    }
    
    // MARK: - Core Features
    
    /// Generates text content using the Reasoning model (Pro).
    public func generateText(prompt: String) async throws -> String {
        guard let client = reasoningClient else {
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
    
    /// Generates a description using the Fast model (Flash).
    public func generateDescription(from imageData: Data) async throws -> String {
        guard let client = fastClient else {
            throw GeminiError.notConfigured
        }
        
        do {
            let prompt = "Describe the scene concisely. Do NOT capture or transcribe license plates, faces, or specific street numbers. Focus on vehicle types, traffic flow, and environment."
            
            // gemini-3.0-flash is multimodal.
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
