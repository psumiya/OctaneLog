import SwiftUI


public struct CockpitView: View {
    @State var director: DirectorService
    
    public init(director: DirectorService) {
        self.director = director
    }
    
    public var body: some View {
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
                VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .padding()
                    Text("WAITING FOR VIDEO SOURCE")
                        .font(.caption)
                        .tracking(2.0)
                }
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
        }
        .onAppear {
            print("🚀 CockpitView APPEARED")
            Task {
                print("🎬 Director Starting Session...")
                await director.startSession()
            }
        }
        .onDisappear {
            director.stopSession()
        }
    }
}

struct CockpitView_Previews: PreviewProvider {
    static var previews: some View {
        CockpitView(director: DirectorService(videoSource: MockCameraSource()))
    }
}
