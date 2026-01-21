import SwiftUI
import OctaneLogCore

@main
struct OctaneLogApp: App {
    @State private var director = DirectorService()
    
    var body: some Scene {
        WindowGroup {
            RootView(director: director)
                .onAppear { print("📱 WindowGroup visible") }
        }
    }
}
