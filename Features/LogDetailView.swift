import SwiftUI

struct LogDetailView: View {
    let episode: Episode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Video Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 240)
                    .overlay(
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                            Text("Replay Drive")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    )
                
                // Map Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.2))
                    .frame(height: 150)
                    .overlay(Text("Map Route Path").foregroundColor(.white))
                
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
