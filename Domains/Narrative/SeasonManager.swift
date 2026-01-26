import Foundation

/// Manages the long-term state ("Season Arc") of the user's narrative.
/// This fulfills the "Marathon Agent" requirement by persisting context across sessions.
public actor SeasonManager {
    public static let shared = SeasonManager()
    
    private let fileName = "SeasonArc.json"
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    public init() {}
    
    /// Loads the current season state or creates a new one if it doesn't exist.
    public func loadSeason() async -> SeasonArc {
        print("SeasonManager: loadSeason called")
        do {
            let data = try Data(contentsOf: fileURL)
            print("SeasonManager: File data read. Size: \(data.count) bytes")
            let season = try JSONDecoder().decode(SeasonArc.self, from: data)
            print("SeasonManager: Decoded season successfully.")
            return season
        } catch {
            print("SeasonManager: Failed to load (Error: \(error)). Creating new season.")
            // Start a new season if none exists
            let newSeason = SeasonArc(
                id: UUID(),
                title: "Season 1: The New Journey",
                theme: "Discovery",
                episodes: [],
                recurringCharacters: []
            )
            await saveSeason(newSeason)
            return newSeason
        }
    }
    
    /// Saves the updated usage state to disk.
    public func saveSeason(_ season: SeasonArc) async {
        do {
            let data = try JSONEncoder().encode(season)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save Season Arc: \(error)")
        }
    }
    
    /// Deletes a single episode by its ID.
    public func deleteEpisode(id: UUID) async {
        var season = await loadSeason()
        if let index = season.episodes.firstIndex(where: { $0.id == id }) {
            season.episodes.remove(at: index)
            await saveSeason(season)
        }
    }
    
    /// Deletes multiple episodes by their IDs.
    public func deleteEpisodes(ids: Set<UUID>) async {
        var season = await loadSeason()
        let originalCount = season.episodes.count
        season.episodes.removeAll { ids.contains($0.id) }
        
        if season.episodes.count != originalCount {
            await saveSeason(season)
        }
    }
}

// MARK: - Models

public struct SeasonArc: Codable, Sendable {
    public let id: UUID
    public var title: String
    public var theme: String
    public var episodes: [Episode]
    public var recurringCharacters: [String] // e.g., "The Coffee Shop", "Old 66 Highway"
    
    public init(id: UUID, title: String, theme: String, episodes: [Episode], recurringCharacters: [String]) {
        self.id = id
        self.title = title
        self.theme = theme
        self.episodes = episodes
        self.recurringCharacters = recurringCharacters
    }
}

public struct Episode: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let title: String
    public let summary: String
    public let tags: [String] // e.g., "Commute", "RoadTrip", "Scenic"
    
    public init(id: UUID, date: Date, title: String, summary: String, tags: [String]) {
        self.id = id
        self.date = date
        self.title = title
        self.summary = summary
        self.tags = tags
    }
}
