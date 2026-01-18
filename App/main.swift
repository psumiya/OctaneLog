import SwiftUI
import OctaneLogCore

struct OctaneLogApp: App {
    @State private var director = DirectorService()
    
    var body: some Scene {
        WindowGroup {
            CockpitView(director: director)
        }
    }
}

OctaneLogApp.main()
