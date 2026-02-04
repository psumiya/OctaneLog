import SwiftUI


public struct CockpitView: View {
    var director: DirectorService
    private let aiService: AIService
    @AppStorage("isDeveloperMode") private var isDeveloperMode: Bool = false
    @State private var lastAnalysis: String?
    @State private var isAnalyzing = false
    
    var onEndDrive: (([String], [RoutePoint]) -> Void)?
    
    public init(director: DirectorService, aiService: AIService, onEndDrive: (([String], [RoutePoint]) -> Void)? = nil) {
        self.director = director
        self.aiService = aiService
        self.onEndDrive = onEndDrive
    }
    
    @Environment(\.scenePhase) var scenePhase
    
    public var body: some View {
        ZStack {
            // 0. FAIL-SAFE BACKGROUND
            // This ensures that if the image layer fails (transparent), we see black, not grey.
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 1. Live Viewfinder
            if let frame = director.lastFrame {
                Image(decorative: frame, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all) // Background ignores safe area
                    .overlay(Color.black.opacity(0.2))
            } else {
                VStack {
                    if isDeveloperMode {
                         Text("DEBUG: No Frame\nRunning: \(director.isRunning)")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .padding()
                    Text(director.isRunning ? AppConstants.UI.waitingForVideo : "SESSION ENDED")
                        .font(.caption)
                        .tracking(2.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8)) // Explicit background
                .edgesIgnoringSafeArea(.all)
                .foregroundColor(.white)
            }
            
            // 2. HUD (Heads-Up Display)
            VStack {
                // Top Bar
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text(AppConstants.UI.appName)
                        .font(.custom("HelveticaNeue-CondensedBlack", size: 24))
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .tracking(1.0)
                    
                    Spacer()
                    
                    if director.isRunning {
                        Text(AppConstants.UI.rec)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    } else {
                        Text(AppConstants.UI.standby)
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
                            Text(AppConstants.UI.geminiVision)
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
                                Text(isAnalyzing ? AppConstants.UI.checking : AppConstants.UI.sceneCheck)
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
                                Text(director.isRunning ? AppConstants.UI.endDrive : AppConstants.UI.startDrive)
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
                                    print("🧪 Triggering Narrative Test with Gemini 3...")
                                    onEndDrive?(SimulationData.driveEvents, [])
                                }
                            }) {
                                VStack {
                                    Image(systemName: "ant.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.purple)
                                    Text(AppConstants.UI.debugTest)
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
                        Text(AppConstants.UI.aiSystem)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(AppConstants.UI.online)
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                print("📱 App Backgrounded. Invalidating preview to prevent zombie frames.")
                // If not running, ensure next launch shows "Session Ended" cleanly
                if !director.isRunning {
                    director.lastFrame = nil
                }
                // If running, we keep it, assuming background task might keep it alive,
                // or we accept the risk. For safety, let's clear it if not crucial.
            }
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
                let description = try await aiService.generateDescription(from: data, location: nil)
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
        let result = director.finishDrive()
        onEndDrive?(result.events, result.route)
    }
}

struct CockpitView_Previews: PreviewProvider {
    static var previews: some View {
        CockpitView(director: DirectorService(videoSource: MockCameraSource()), aiService: GeminiService())
    }
}
