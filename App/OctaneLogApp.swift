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
            // .ambient option allows background music (Spotify, etc.) to keep playing.
            // It also ensures that if the ringer is silent, the app respects that (though we don't play sound yet).
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio Session Configured: Ambient (Music will continue)")
        } catch {
            print("❌ Failed to configure Audio Session: \(error)")
        }
    }
}
