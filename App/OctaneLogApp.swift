import SwiftUI
import OctaneLogCore

@main
struct OctaneLogApp: App {
    @State private var director = DirectorService()
    @State private var narrativeAgent = NarrativeAgent() // Create the Showrunner
    
    var body: some Scene {
        WindowGroup {
            RootView(director: director, narrativeAgent: narrativeAgent)
                .onAppear { print("📱 WindowGroup visible") }
        }
    }
}
