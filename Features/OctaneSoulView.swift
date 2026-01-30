import SwiftUI

public struct OctaneSoulView: View {
    let report: OctaneSoulReport
    
    public init(report: OctaneSoulReport) {
        self.report = report
    }
    
    public var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.8), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                Text("OCTANE SOUL \(String(report.year))")
                    .font(.caption)
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Soul Title
                Text(report.soulTitle)
                    .font(.custom("HelveticaNeue-CondensedBlack", size: 48))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 0)
                
                // Description
                Text(report.soulDescription)
                    .font(.body)
                    .italic()
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider().background(Color.white.opacity(0.3)).padding(.vertical)
                
                // Stats Grid
                HStack(spacing: 40) {
                    VStack {
                        Text("\(report.totalDrives)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("DRIVES")
                            .font(.caption2)
                            .tracking(2)
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text("\(report.topTags.count)") // Fallback or computed
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("TAGS")
                            .font(.caption2)
                            .tracking(2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Top Tags List
                if !report.topTags.isEmpty {
                    VStack(spacing: 8) {
                        Text("TOP VIBES")
                            .font(.caption2)
                            .tracking(2)
                            .foregroundColor(.gray)
                        
                        HStack {
                            ForEach(report.topTags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(15)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // Footer
                Image(systemName: "steeringwheel")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding()
        }
    }
}

// Preview Mock
#if DEBUG
struct OctaneSoulView_Previews: PreviewProvider {
    static var previews: some View {
        OctaneSoulView(report: OctaneSoulReport(
            year: 2025,
            totalDrives: 142,
            topTags: ["NightDrive", "Scenic", "Speed"],
            soulTitle: "The Midnight Wanderer",
            soulDescription: "You thrive when the sun goes down, treating the empty highways as your personal canvas."
        ))
    }
}
#endif
