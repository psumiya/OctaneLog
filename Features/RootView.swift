import SwiftUI

public struct RootView: View {
    @State var director: DirectorService
    let narrativeAgent: NarrativeAgent
    
    public init(director: DirectorService, narrativeAgent: NarrativeAgent) {
        self.director = director
        self.narrativeAgent = narrativeAgent
    }
    
    public var body: some View {
        TabView {
            CockpitView(director: director, onEndDrive: { events in
                Task {
                    print("🎬 Ending Drive with \(events.count) events...")
                    let summary = await narrativeAgent.processDrive(events: events)
                    print("📝 Narrative Generated: \(summary)")
                    // In a real app, we might trigger a refresh in GarageView here via NotificationCenter or Environment
                }
            })
            .tabItem {
                Label("Cockpit", systemImage: "video.circle.fill")
            }
            
            GarageView()
                .tabItem {
                    Label("Garage", systemImage: "car.fill")
                }
        }
        .accentColor(.red) // Branding color
        .preferredColorScheme(.dark)
    }
}
