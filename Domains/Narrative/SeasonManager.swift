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
        do {
            let data = try Data(contentsOf: fileURL)
            let season = try JSONDecoder().decode(SeasonArc.self, from: data)
            return season
        } catch {
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
