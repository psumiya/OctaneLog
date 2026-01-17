import SwiftUI

@main
struct OctaneLogApp: App {
    // Inject dependencies
    @State private var director = DirectorService()
    
    var body: some Scene {
        WindowGroup {
            CockpitView(director: director)
        }
    }
}

// MARK: - Views (Scaffolding this here for speed, will move to Features/ later)

struct CockpitView: View {
    @State var director: DirectorService
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 1. Live Viewfinder
            if let frame = director.lastFrame {
                Image(decorative: frame, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(Color.black.opacity(0.2)) // Cinematic dims
            } else {
                Text("WAITING FOR VIDEO SOURCE")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 2. HUD (Heads-Up Display)
            VStack {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("OCTANELOG")
                        .font(.custom("HelveticaNeue-CondensedBlack", size: 24))
                        .foregroundColor(.white)
                    Spacer()
                    
                    if director.isRunning {
                        Text("LIVE")
                            .font(.caption)
                            .padding(4)
                            .background(Color.red)
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()
                
                // Stats Debugger
                VStack(alignment: .leading) {
                    Text("FRAMES: \(director.frameCount)")
                    Text("AI STATE: STANDBY")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.green)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            Task {
                await director.startSession()
            }
        }
    }
}
