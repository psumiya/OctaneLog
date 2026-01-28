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

public struct Checkpoint: Codable, Sendable {
    public let date: Date
    public let type: String // "Weekly", "Monthly", "Yearly"
}

public struct Recap: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let periodType: String // "Weekly", "Monthly", "Yearly"
    public let summary: String
    
    public init(id: UUID = UUID(), date: Date, periodType: String, summary: String) {
        self.id = id
        self.date = date
        self.periodType = periodType
        self.summary = summary
    }
}

public struct OctaneSoulReport: Codable, Sendable, Identifiable {
    public let id: UUID
    public let year: Int
    public let totalDrives: Int
    public let topTags: [String]
    public let soulTitle: String
    public let soulDescription: String
    
    public init(id: UUID = UUID(), year: Int, totalDrives: Int, topTags: [String], soulTitle: String, soulDescription: String) {
        self.id = id
        self.year = year
        self.totalDrives = totalDrives
        self.topTags = topTags
        self.soulTitle = soulTitle
        self.soulDescription = soulDescription
    }
}

public struct SeasonArc: Codable, Sendable {
    public let id: UUID
    public var title: String
    public var theme: String
    public var episodes: [Episode]
    public var recurringCharacters: [String] // e.g., "The Coffee Shop", "Old 66 Highway"
    
    // Periodic Summaries
    public var recaps: [Recap]
    public var lastWeeklyRecapDate: Date?
    public var lastMonthlyRecapDate: Date?
    public var lastYearlyRecapDate: Date?
    
    // OctaneSoul (Yearly Odyssey)
    public var octaneSouls: [OctaneSoulReport]
    
    public init(id: UUID, title: String, theme: String, episodes: [Episode], recurringCharacters: [String], recaps: [Recap] = [], lastWeeklyRecapDate: Date? = nil, lastMonthlyRecapDate: Date? = nil, lastYearlyRecapDate: Date? = nil, octaneSouls: [OctaneSoulReport] = []) {
        self.id = id
        self.title = title
        self.theme = theme
        self.episodes = episodes
        self.recurringCharacters = recurringCharacters
        self.recaps = recaps
        self.lastWeeklyRecapDate = lastWeeklyRecapDate
        self.lastMonthlyRecapDate = lastMonthlyRecapDate
        self.lastYearlyRecapDate = lastYearlyRecapDate
        self.octaneSouls = octaneSouls
    }
    
    // Custom decoding for backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.theme = try container.decode(String.self, forKey: .theme)
        self.episodes = try container.decode([Episode].self, forKey: .episodes)
        self.recurringCharacters = try container.decode([String].self, forKey: .recurringCharacters)
        
        // Default to empty/nil if missing
        self.recaps = try container.decodeIfPresent([Recap].self, forKey: .recaps) ?? []
        self.lastWeeklyRecapDate = try container.decodeIfPresent(Date.self, forKey: .lastWeeklyRecapDate)
        self.lastMonthlyRecapDate = try container.decodeIfPresent(Date.self, forKey: .lastMonthlyRecapDate)
        self.lastYearlyRecapDate = try container.decodeIfPresent(Date.self, forKey: .lastYearlyRecapDate)
        
        self.octaneSouls = try container.decodeIfPresent([OctaneSoulReport].self, forKey: .octaneSouls) ?? []
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
