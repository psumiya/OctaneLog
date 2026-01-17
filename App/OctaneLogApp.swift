import SwiftUI
import OctaneLogCore

@main
struct OctaneLogApp: App {
    // Inject dependencies
    // Note: DirectorService is now part of OctaneLogCore, so it's accessible.
    // However, since `OctaneLogApp` is outside the package sources but likely sharing the same build context in Xcode due to being in the root or referenced,
    // we need to make sure `DirectorService` is public.
    @State private var director = DirectorService()
    
    var body: some Scene {
        WindowGroup {
            CockpitView(director: director)
        }
    }
}
