import SwiftUI
import OctaneLogCore

@main
struct OctaneLogApp: App {
    @State private var director = DirectorService()
    
    var body: some Scene {
        WindowGroup {
            CockpitView(director: director)
        }
    }
}
