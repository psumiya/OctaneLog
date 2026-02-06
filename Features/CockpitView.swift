import SwiftUI
import AVFoundation


public struct CockpitView: View {
    var director: DirectorService
    private let aiService: AIService
    @AppStorage("isDeveloperMode") private var isDeveloperMode: Bool = false
    @State private var lastAnalysis: String?
    @State private var isAnalyzing = false
    
    var onEndDrive: (([String], [RoutePoint], [URL]) -> Void)?
    
    public init(director: DirectorService, aiService: AIService, onEndDrive: (([String], [RoutePoint], [URL]) -> Void)? = nil) {
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
            CameraPreview(session: director.captureSession)
                .edgesIgnoringSafeArea(.all)
                .overlay(Color.black.opacity(0.1)) // Slight tint
            
            if !director.isRunning {
                 VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .padding()
                    Text("SESSION ENDED")
                        .font(.caption)
                        .tracking(2.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
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

                    // Center Controls
                    HStack(spacing: 20) {
                        // AI Trigger Button REMOVED (Legacy Frame Analysis)
                        // If we want manual snapshots later, we need to reimplement snapshot() in DirectorService
                        // using AVCaptureVideoDataOutput alongside MovieFileOutput. 
                        
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
                                    onEndDrive?(SimulationData.driveEvents, [], [])
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
                print("📱 App Backgrounded. Stopping active clips.")
                // Should we stop session? Or just clip?
                // Director handles backgrounding logic internally if needed, 
                // but actually Director needs to know.
                // We added handleBackgrounding() to Director. Let's call it.
                director.handleBackgrounding()
            } else if newPhase == .active {
                // Foreground
                director.handleForegrounding()
            }
        }
    }
    
    // MARK: - Actions
    // analyzeFrame Removed
    
    private func finishDrive() {
        director.stopSession() // Stop camera and location
        let result = director.finishDrive()
        onEndDrive?(result.events, result.route, result.videoClips)
    }
}

struct CockpitView_Previews: PreviewProvider {
    static var previews: some View {
        CockpitView(director: DirectorService(), aiService: GeminiService())
    }
}
// MARK: - Camera Preview (UIViewRepresentable)
#if os(iOS)
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            previewLayer.session = session
        }
    }
}
#elseif os(macOS)
// macOS fallback
struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> NSView {
         let view = NSView(frame: .zero)
         view.wantsLayer = true
         view.layer?.backgroundColor = NSColor.black.cgColor
         return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
