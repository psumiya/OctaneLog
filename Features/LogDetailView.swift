import SwiftUI

struct LogDetailView: View {
    let index: Int
    
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
                    Text("AI SUMMARY")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text("This drive included a scenic route along PCH. Moderate traffic was encountered near Santa Monica. Total stop time: 4 minutes.")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.body)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("Log #00\(index + 1)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
