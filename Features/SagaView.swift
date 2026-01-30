import SwiftUI

public struct SagaView: View {
    @State private var season: SeasonArc?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let season = season {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading) {
                            Text("YOUR SAGA")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                            Text(season.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top)
                        .padding(.horizontal)
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // Mixed Timeline: Recaps + OctaneSouls
                        // We need to sort them by date/year.
                        // Since they are separate arrays, we'll just display them in sections for now for simplicity,
                        // or interleave them if we had a unified date protocol.
                        // Let's display OctaneSouls (Annual) first, then Recaps.
                        
                        if !season.octaneSouls.isEmpty {
                            Text("ANNUAL ODYSSEYS")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                            
                            ForEach(season.octaneSouls) { soul in
                                OctaneSoulView(report: soul)
                                    .frame(height: 500)
                                    .cornerRadius(20)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Text("JOURNAL")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if season.recaps.isEmpty {
                            Text("No journals yet. Keep driving.")
                                .foregroundColor(.gray)
                                .italic()
                                .padding(.horizontal)
                        } else {
                            ForEach(season.recaps.reversed()) { recap in
                                RecapRow(recap: recap)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            self.season = await SeasonManager.shared.loadSeason()
                        }
                    }
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct RecapRow: View {
    let recap: Recap
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(recap.periodType.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
                    .foregroundColor(colorForType(recap.periodType))
                
                Spacer()
                Text(recap.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(recap.summary)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    func colorForType(_ type: String) -> Color {
        switch type {
        case "Weekly": return .blue
        case "Monthly": return .purple
        case "Yearly": return .orange
        default: return .white
        }
    }
}
