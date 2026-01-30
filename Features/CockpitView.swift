import SwiftUI


public struct CockpitView: View {
    var director: DirectorService
    @State private var gemini = GeminiService()
    @AppStorage("isDeveloperMode") private var isDeveloperMode: Bool = false
    @State private var lastAnalysis: String?
    @State private var isAnalyzing = false
    
    var onEndDrive: (([String]) -> Void)?
    
    public init(director: DirectorService, onEndDrive: (([String]) -> Void)? = nil) {
        self.director = director
        self.onEndDrive = onEndDrive
    }
    
    public var body: some View {
        ZStack {
            // 1. Live Viewfinder
            if let frame = director.lastFrame {
                Image(decorative: frame, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all) // Background ignores safe area
                    .overlay(Color.black.opacity(0.2))
            } else {
                VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .padding()
                    Text("WAITING FOR VIDEO SOURCE")
                        .font(.caption)
                        .tracking(2.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all) // Placeholder ignores safe area
                .foregroundColor(.gray)
            }
            
            // 2. HUD (Heads-Up Display)
            VStack {
                // Top Bar
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("OCTANELOG")
                        .font(.custom("HelveticaNeue-CondensedBlack", size: 24))
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .tracking(1.0)
                    
                    Spacer()
                    
                    if director.isRunning {
                        Text("REC")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    } else {
                        Text("STANDBY")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .clear]), startPoint: .top, endPoint: .bottom))
                
                // Analysis Overlay
                if let analysis = lastAnalysis {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("GEMINI VISION")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                            Text(analysis)
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Bottom stats
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FRAMES")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(director.frameCount)")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    // Center Controls
                    HStack(spacing: 20) {
                        // AI Trigger Button
                        Button(action: {
                            analyzeFrame()
                        }) {
                            VStack {
                                Image(systemName: isAnalyzing ? "camera.aperture" : "camera.viewfinder")
                                    .font(.title)
                                    .foregroundColor(isAnalyzing ? .yellow : .white)
                                Text(isAnalyzing ? "CHECKING..." : "SCENE CHECK")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 80, height: 80)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        .disabled(isAnalyzing)
                        
                        // Drive Control Button (Start/End)
                        Button(action: {
                            if director.isRunning {
                                finishDrive()
                            } else {
                                Task {
                                    await director.startSession()
                                }
                            }
                        }) {
                            VStack {
                                Image(systemName: director.isRunning ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(director.isRunning ? .red : .green)
                                Text(director.isRunning ? "END DRIVE" : "START DRIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 80, height: 80)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        
                        // TEST NARRATIVE (Gemini 3 Check)
                        if isDeveloperMode {
                            Button(action: {
                                Task {
                                    // Simulate a short drive to test the Narrative Agent
                                    // Simulate a short drive to test the Narrative Agent
                                    print("🧪 Triggering Narrative Test with Gemini 3...")
                                    onEndDrive?(SimulationData.driveEvents)
                                }
                            }) {
                                VStack {
                                    Image(systemName: "ant.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.purple)
                                    Text("DEBUG TEST")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 80, height: 80)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("AI SYSTEM")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("ONLINE")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
            }
            // HUD now respects Safe Area by default because we removed it from ZStack parent
        }
        .onAppear {
            print("🚀 CockpitView APPEARED")
            // Auto-start removed. User must manually start drive.
        }
        .onDisappear {
            director.stopSession()
        }
    }
    
    // MARK: - Actions
    
    private func analyzeFrame() {
        guard let data = director.snapshot() else {
            print("❌ No frame to analyze")
            return
        }
        
        isAnalyzing = true
        lastAnalysis = "Capturing..."
        
        Task {
            do {
                let description = try await gemini.generateDescription(from: data)
                await MainActor.run {
                    withAnimation {
                        self.lastAnalysis = description
                        self.isAnalyzing = false
                        // LOG EVENT FOR NARRATIVE
                        self.director.logEvent(description)
                    }
                }
            } catch {
                await MainActor.run {
                    self.lastAnalysis = "Error: Check API Key"
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    private func finishDrive() {
        director.stopSession() // Stop camera and location
        let events = director.finishDrive()
        onEndDrive?(events)
    }
}

struct CockpitView_Previews: PreviewProvider {
    static var previews: some View {
        CockpitView(director: DirectorService(videoSource: MockCameraSource()))
    }
}
