import Foundation
import GoogleGenerativeAI

/// Service responsible for interacting with the Google Gemini ecosystem.
/// Supports both Gemini 3 Flash (fast, real-time) and Pro (complex synthesis).
@Observable
public class GeminiService {
    
    // MARK: - Properties
    
    // We'll use a hardcoded placeholder for now, but in production this should be in an uncached Config file or Keychain.
    private var apiKey: String = "" 
    private var client: GenerativeModel?
    
    // MARK: - Initialization
    
    public init() {
        // Attempt to load API Key from environment or configuration
        // For MVP, we'll check an Environment Variable or allow injection later
        // In a real app, use `Bundle.main.object(forInfoDictionaryKey:)` or similar
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty {
            self.configure(with: key)
        }
    }
    
    // MARK: - Configuration
    
    public func configure(with apiKey: String) {
        self.apiKey = apiKey
        // Initialize the model. Defaulting to Gemini 1.5 Flash (latest stable as of early 2025 in this context)
        // or "gemini-pro" depending on needs. Adjust model name as "gemini-1.5-flash" or similar.
        self.client = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKey)
        print("GeminiService: Configured with API Key.")
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
            print("GeminiService Error: \(error)")
            throw error
        }
    }
    
    // Additional methods for image inputs will go here.
}

public enum GeminiError: Error {
    case notConfigured
}
