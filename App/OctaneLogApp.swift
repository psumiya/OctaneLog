import SwiftUI
import OctaneLogCore

@main
struct OctaneLogApp: App {
    @State private var director = DirectorService()
    @State private var narrativeAgent = NarrativeAgent() // Create the Showrunner
    
    public init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(director: director, narrativeAgent: narrativeAgent, aiService: GeminiService())
                .onAppear { print("📱 WindowGroup visible") }
        }
    }
    
    private func configureAudioSession() {
        do {
            // Configure audio session to allow background music to continue playing.
            // The .ambient category does not allow audio recording (Microphone access).
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio Session Configured: Background music allowed (No Microphone)")
        } catch {
            print("❌ Failed to configure Audio Session: \(error)")
        }
    }
}
