import Foundation
import Observation
import GoogleGenerativeAI
import CoreLocation

// MARK: - AIService Conformance

extension GeminiService: AIService {}

public class GeminiService {
    
    // MARK: - Properties
    
    private var apiKey: String = ""
    private var fastClient: GenerativeModel?      // gemini-3.0-flash (Speed/Vision)
    private var reasoningClient: GenerativeModel? // gemini-3.0-pro (Reasoning/Navigator)
    
    // MARK: - Initialization
    
    private let keychainService = "com.octanelog.api.key"
    private let keychainAccount = "gemini_api_key_v1"
    
    public init() {
        // 1. Try Keychain First (Secure)
        if let data = KeychainHelper.standard.read(service: keychainService, account: keychainAccount),
           let key = String(data: data, encoding: .utf8), !key.isEmpty {
            print("GeminiService: Authenticated via Keychain.")
            self.configure(with: key, persist: false) // Don't re-save to avoid loop
            return
        }
        
        // 2. Fallback to User Defaults (Legacy/Dev) & MIGRATION
        if let userKey = UserDefaults.standard.string(forKey: "user_gemini_api_key"), !userKey.isEmpty {
            print("GeminiService: Found legacy key in UserDefaults. Migrating to Keychain...")
            self.configure(with: userKey, persist: true)
            
            // 3. Cleanup Legacy
            UserDefaults.standard.removeObject(forKey: "user_gemini_api_key")
            print("GeminiService: Legacy key removed from UserDefaults.")
        } else {
            print("GeminiService: No API Key found.")
        }
    }
    
    // MARK: - Configuration
    
    public func configure(with apiKey: String, persist: Bool = true) {
        self.apiKey = apiKey
        
        // Persist to Keychain
        if persist, let data = apiKey.data(using: .utf8) {
             KeychainHelper.standard.save(data, service: keychainService, account: keychainAccount)
             print("GeminiService: API Key saved to Keychain.")
        }
        
        // UPGRADE TO GEMINI 3 (Validated from ListModels)
        // Flash for high-frequency video analysis
        self.fastClient = GenerativeModel(name: "gemini-3-flash-preview", apiKey: apiKey)
        
        // Pro for deep reasoning and narrative generation (Marathon Agent)
        self.reasoningClient = GenerativeModel(name: "gemini-3-pro-preview", apiKey: apiKey)
        
        print("GeminiService: Configured (gemini-3-flash-preview & gemini-3-pro-preview).")
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
    

}


public enum GeminiError: Error {
    case notConfigured
}
