import SwiftUI

@Observable
class GarageViewModel {
    var season: SeasonArc?
    var isLoading = false
    
    func loadSeason() async {
        self.isLoading = true
        self.season = await SeasonManager.shared.loadSeason()
        self.isLoading = false
    }
}

public struct GarageView: View {
    @State private var viewModel = GarageViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let season = viewModel.season {
                    VStack(alignment: .leading) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SEASON THEME")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                            Text(season.theme.uppercased())
                                .font(.custom("HelveticaNeue-CondensedBlack", size: 32))
                                .foregroundColor(.red)
                            
                            Text("RECURRING CHARACTERS")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                                .padding(.top, 8)
                            
                            if season.recurringCharacters.isEmpty {
                                Text("None detected yet.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(season.recurringCharacters, id: \.self) { char in
                                            Text(char)
                                                .font(.caption)
                                                .padding(6)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(4)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // Episodes List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(season.episodes.reversed()) { episode in
                                    NavigationLink(destination: LogDetailView(episode: episode)) {
                                        EpisodeRow(episode: episode)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    Text("No Season Found")
                        .foregroundColor(.white)
                }
            }
            .task {
                await viewModel.loadSeason()
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
}

struct EpisodeRow: View {
    let episode: Episode
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay {
                    VStack {
                        Text("EP")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(episode.title.components(separatedBy: "#").last ?? "1")")
                            .font(.title)
                            .fontWeight(.heavy)
                    }
                    .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.summary)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    ForEach(episode.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        GarageView()
    }
}
