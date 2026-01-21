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
    let narrativeAgent = NarrativeAgent() // The Showrunner
    
    var body: some Scene {
        WindowGroup {
            RootView(director: director, narrativeAgent: narrativeAgent)
        }
    }
}
