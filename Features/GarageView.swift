import SwiftUI

@Observable
class GarageViewModel {
    var season: SeasonArc?
    var isLoading = false
    var statusMessage: String = "Loading..."
    var showSagaView = false // For programmatic navigation
    
    // Selection Mode State
    var isSelectionMode = false
    var selectedEpisodeIds: Set<UUID> = []
    
    func loadSeason() async {
        print("GarageViewModel: Start Loading Season...")
        // If we are already loading, maybe we don't need to check again? 
        // But for safety, let's keep it simple.
        // We set isLoading = true only if we want to show the spinner. 
        // But if called from onAppear, we might want to be silent if data exists?
        // For now, consistent spinner.
        self.isLoading = true 
        self.statusMessage = "Loading Season..."
        self.season = await SeasonManager.shared.loadSeason()
        self.isLoading = false
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
    
    func analyzeSeason(agent: NarrativeAgent) async -> String {
        self.isLoading = true
        self.statusMessage = "Submitting episodes to Gemini for analysis...\nHang on, this may take a while."
        let result = await agent.analyzeCurrentSeason()
        await loadSeason() // Reload to get new theme/title
        self.isLoading = false
        return result
    }
}

public struct GarageView: View {
    @State private var viewModel = GarageViewModel()
    
    let narrativeAgent: NarrativeAgent
    
    public init(narrativeAgent: NarrativeAgent) {
        self.narrativeAgent = narrativeAgent
    }
    
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
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        Text(viewModel.statusMessage)
                            .foregroundColor(.white)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
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
                                Menu {
                                    Button(action: {
                                        viewModel.showSagaView = true
                                    }) {
                                        Label("View Saga", systemImage: "book")
                                    }
                                    
                                    Button(action: {
                                        Task {
                                            // 1. Analyze
                                            let _ = await viewModel.analyzeSeason(agent: narrativeAgent)
                                            // 2. Auto-Navigate to Saga
                                            viewModel.showSagaView = true
                                        }
                                    }) {
                                        Label("Analyze Season Theme", systemImage: "wand.and.stars")
                                    }
                                } label: {
                                    Text("Saga")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                                .background(
                                    NavigationLink(isActive: $viewModel.showSagaView, destination: { SagaView() }, label: { EmptyView() })
                                )
                                
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
                                        NavigationLink(destination: LogDetailView(episode: episode, narrativeAgent: narrativeAgent)) {
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
                // Fix infinite loading: Only load if we don't have a season or if explicitly requested.
                // But for now, just load it, but make sure isLoading is handled in loadSeason.
                Task {
                    viewModel.isLoading = true 
                    await viewModel.loadSeason()
                     // Force isLoading off after valid load, handled in viewModel.loadSeason but ensuring here too if needed
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
        GarageView(narrativeAgent: NarrativeAgent(geminiService: PreviewMockAIService()))
    }
}

fileprivate struct PreviewMockAIService: AIService {
    func generateText(prompt: String) async throws -> String { return "Mock Text" }
    func generateImage(prompt: String) async throws -> Data { return Data() }
}
