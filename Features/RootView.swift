import SwiftUI

public struct RootView: View {
    var director: DirectorService
    let narrativeAgent: NarrativeAgent
    let aiService: AIService
    
    public init(director: DirectorService, narrativeAgent: NarrativeAgent, aiService: AIService) {
        self.director = director
        self.narrativeAgent = narrativeAgent
        self.aiService = aiService
    }
    
    @State private var generatedNarrative: String?
    @State private var showSummary = false

    public var body: some View {
        TabView {
            CockpitView(director: director, aiService: aiService, onEndDrive: { events, route in
                Task {
                    print("🎬 Ending Drive with \(events.count) events and \(route.count) route points...")
                    
                    #if os(iOS)
                    // Request extra time from the system to complete AI generation
                    var taskID = UIBackgroundTaskIdentifier.invalid
                    taskID = UIApplication.shared.beginBackgroundTask {
                        // Expiration handler: Force end if time runs out
                        UIApplication.shared.endBackgroundTask(taskID)
                        taskID = .invalid
                    }
                    #endif
                    
                    let summary = await narrativeAgent.processDrive(events: events, route: route)
                    
                    await MainActor.run {
                        self.generatedNarrative = summary
                        self.showSummary = true
                        
                        #if os(iOS)
                        // End the background task
                        UIApplication.shared.endBackgroundTask(taskID)
                        taskID = .invalid
                        #endif
                    }
                }
            })
            .sheet(isPresented: $showSummary) {
                if let summary = generatedNarrative {
                    NarrativeSummaryView(summary: summary)
                } else {
                    // Fallback if sheet is presented but data isn't ready (shouldn't happen, but safe)
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Loading Summary...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    }
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
            
            ScrollView { // Added ScrollView to prevent layout issues with long text
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 40) // Add top padding for scroll view
                    
                    Text("DRIVE LOGGED")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    // Fallback for empty strings causing layout collapse
                    if summary.isEmpty {
                        Text("No summary generated.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        Text(summary)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
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
                    .padding(.bottom, 40) // Add bottom padding for scroll view
                }
                .padding()
            }
        }
    }
}
