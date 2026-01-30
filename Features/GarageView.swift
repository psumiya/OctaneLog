import SwiftUI

@Observable
class GarageViewModel {
    var season: SeasonArc?
    var isLoading = false
    
    // Selection Mode State
    var isSelectionMode = false
    var selectedEpisodeIds: Set<UUID> = []
    
    func loadSeason() async {
        print("GarageViewModel: Start Loading Season...")
        self.isLoading = true
        self.season = await SeasonManager.shared.loadSeason()
        self.isLoading = false
        print("GarageViewModel: Finished Loading Season. Season is nil? \(self.season == nil)")
    }
    
    func deleteEpisode(id: UUID) async {
        await SeasonManager.shared.deleteEpisode(id: id)
        await loadSeason()
    }
    
    func deleteSelectedEpisodes() async {
        await SeasonManager.shared.deleteEpisodes(ids: selectedEpisodeIds)
        selectedEpisodeIds.removeAll()
        isSelectionMode = false
        await loadSeason()
    }
    
    func toggleSelection(for id: UUID) {
        if selectedEpisodeIds.contains(id) {
            selectedEpisodeIds.remove(id)
        } else {
            selectedEpisodeIds.insert(id)
        }
    }
}

public struct GarageView: View {
    @State private var viewModel = GarageViewModel()
    
    public init() {}
    
    var editButton: some View {
        Button(action: {
            viewModel.isSelectionMode.toggle()
            viewModel.selectedEpisodeIds.removeAll()
        }) {
            Text(viewModel.isSelectionMode ? "Done" : "Edit")
                .foregroundColor(.red)
        }
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let season = viewModel.season {
                    VStack(alignment: .leading) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SEASON THEME")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .tracking(2)
                                Text(season.theme.uppercased())
                                    .font(.custom("HelveticaNeue-CondensedBlack", size: 32))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            HStack {
                                NavigationLink(destination: SagaView()) {
                                    Text("Saga")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                                editButton
                            }
                        }
                        .padding()
                        
                        Text("RECURRING CHARACTERS")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .tracking(2)
                            .padding(.horizontal)
                        
                        if season.recurringCharacters.isEmpty {
                            Text("None detected yet.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)
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
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                            .padding(.vertical)
                        
                        // Episodes List
                        List {
                            ForEach(season.episodes.reversed()) { episode in
                                HStack {
                                    if viewModel.isSelectionMode {
                                        Image(systemName: viewModel.selectedEpisodeIds.contains(episode.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(viewModel.selectedEpisodeIds.contains(episode.id) ? .red : .gray)
                                            .onTapGesture {
                                                viewModel.toggleSelection(for: episode.id)
                                            }
                                    }
                                    
                                    if viewModel.isSelectionMode {
                                        EpisodeRow(episode: episode)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                 viewModel.toggleSelection(for: episode.id)
                                            }
                                    } else {
                                        NavigationLink(destination: LogDetailView(episode: episode)) {
                                            EpisodeRow(episode: episode)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                Task {
                                    // Map indexSet (which is relative to the reversed list) back to IDs
                                    let reversedEpisodes = Array(season.episodes.reversed())
                                    for index in indexSet {
                                        if index < reversedEpisodes.count {
                                            let episodeToDelete = reversedEpisodes[index]
                                            await viewModel.deleteEpisode(id: episodeToDelete.id)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        
                        if viewModel.isSelectionMode {
                            Button(action: {
                                Task {
                                    await viewModel.deleteSelectedEpisodes()
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "trash")
                                    Text("Delete Selected (\(viewModel.selectedEpisodeIds.count))")
                                    Spacer()
                                }
                                .padding()
                                .background(viewModel.selectedEpisodeIds.isEmpty ? Color.gray : Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.selectedEpisodeIds.isEmpty)
                            .padding()
                        }
                    }
                } else {
                    Text("No Season Found")
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadSeason()
                }
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
            // Chevron is handled by NavigationLink explicitly or omitted in selection mode
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
