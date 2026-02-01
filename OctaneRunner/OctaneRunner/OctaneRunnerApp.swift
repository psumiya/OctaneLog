//
//  OctaneRunnerApp.swift
//  OctaneRunner
//
//  Created by Sumiya Pathak on 1/18/26.
//

import SwiftUI
import OctaneLogCore
@main
struct OctaneRunnerApp: App {
    @State var director = DirectorService()
    
    // Shared Dependencies
    let aiService = GeminiService()
    let narrativeAgent: NarrativeAgent
    
    init() {
        let service = GeminiService()
        self.aiService = service
        self.narrativeAgent = NarrativeAgent(geminiService: service)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(director: director, narrativeAgent: narrativeAgent, aiService: aiService)
        }
    }
}
