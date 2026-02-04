import SwiftUI

struct LogDetailView: View {
    let episode: Episode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map Route Path with Replay
                if !episode.route.isEmpty {
                    ReplayMapView(route: episode.route)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                } else {
                    // Fallback Placeholder if no route data
                    RoundedRectangle(cornerRadius: 12)
                           .fill(Color.blue.opacity(0.1))
                           .frame(height: 150)
                           .overlay(Text("No Route Data Available").foregroundColor(.white.opacity(0.5)))
                }
                
                // Transcript / Summary
                VStack(alignment: .leading, spacing: 10) {
                    Text("AI FIELD LOG")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text(episode.summary)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.body)
                    
                    if !episode.tags.isEmpty {
                        Divider().background(Color.gray)
                        HStack {
                            ForEach(episode.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(4)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle(episode.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
