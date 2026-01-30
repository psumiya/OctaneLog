import SwiftUI

public struct RootView: View {
    var director: DirectorService
    let narrativeAgent: NarrativeAgent
    
    public init(director: DirectorService, narrativeAgent: NarrativeAgent) {
        self.director = director
        self.narrativeAgent = narrativeAgent
    }
    
    @State private var generatedNarrative: String?
    @State private var showSummary = false

    public var body: some View {
        TabView {
            CockpitView(director: director, onEndDrive: { events in
                Task {
                    print("🎬 Ending Drive with \(events.count) events...")
                    let summary = await narrativeAgent.processDrive(events: events)
                    
                    await MainActor.run {
                        self.generatedNarrative = summary
                        self.showSummary = true
                    }
                }
            })
            .sheet(isPresented: $showSummary) {
                if let summary = generatedNarrative {
                    NarrativeSummaryView(summary: summary)
                }
            }
            .tabItem {
                Label("Cockpit", systemImage: "video.circle.fill")
            }
            
            GarageView()
                .tabItem {
                    Label("Garage", systemImage: "car.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.red) // Branding color
        .preferredColorScheme(.dark)
    }
}

// Simple view for the summary sheet
struct NarrativeSummaryView: View {
    let summary: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("DRIVE LOGGED")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(2)
                
                Text(summary)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}
