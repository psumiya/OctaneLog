import Foundation

/// The "Showrunner" agent that orchestrates the user's life narrative.
/// It uses a multi-step verification process (Thinking Levels) and persists state (Season Arc).
public actor NarrativeAgent {
    private let seasonManager: SeasonManager
    private let geminiService: GeminiService
    
    public init(seasonManager: SeasonManager = .shared, geminiService: GeminiService = GeminiService()) {
        self.seasonManager = seasonManager
        self.geminiService = geminiService
    }
    
    /// Processes a completed drive, updates the season arc, and generates an episode summary.
    public func processDrive(events: [String]) async -> String {
        guard !events.isEmpty else { return "No events to narrate." }
        
        // 1. Context Retrieval
        let season = await seasonManager.loadSeason()
        ThoughtLogger.log(step: "Context Retrieval", content: "Loaded Season: '\(season.title)'. Current Episode Count: \(season.episodes.count). Recurring Characters: \(season.recurringCharacters.joined(separator: ", "))")
        
        // 2. The Thinking Process (The Marathon aspect)
        // We analyze how this drive fits into the "discovery" theme.
        let analysis = analyzeAlignment(events: events, season: season)
        ThoughtLogger.log(step: "Thematic Analysis", content: analysis)
        
        // 3. Draft Narrative (Simulated or Real Gemini Call)
        let narrative = await generateNarrative(events: events, season: season)
        
        // 4. Update State
        await updateState(season: season, newEpisodeTitle: "Drive #\(season.episodes.count + 1)", summary: narrative)
        
        return narrative
    }
    
    private func analyzeAlignment(events: [String], season: SeasonArc) -> String {
        // In a real system, this would be a separate Gemini call to "Reason" without generating text.
        // "Does this drive reinforce the 'Discovery' theme?"
        if events.contains(where: { $0.contains("Scenic") || $0.contains("New") }) {
            return "Positive Alignment: The user explored new areas, fitting the '\(season.theme)' theme."
        } else {
            return "Neutral Alignment: Routine drive. Suggest spicing it up in the next episode."
        }
    }
    
    private func generateNarrative(events: [String], season: SeasonArc) async -> String {
        let prompt = """
        You are a Field Logger creating a concise travel log called '\(season.title)'.
        The Theme is: \(season.theme).
        
        Previous context: \(season.recurringCharacters.joined(separator: ", ")).
        
        New Events (Sequential):
        \(events.map { "- \($0)" }.joined(separator: "\n"))
        
        Task: Write a summary that strictly follows the sequence of events.
        
        STRICT RULES:
        1. NO DRAMA. Do NOT use words like "journey", "embrace", "canvas", "unseen", "profound".
        2. FACTS ONLY. State what happened. Do not speculate on feelings or "what could be".
        3. CAUSALITY: Show how one event led to the next (e.g., "After stopping at X, traffic slowed down at Y").
        4. TONE: Dry, concise, observant. Like a pilot's log or a dashcam timestamp description.
        5. LENGTH: Maximum 3 sentences.
        """
        
        ThoughtLogger.log(step: "Prompt Engineering", content: "Constructed prompt with \(season.episodes.count) episodes of history.")
        
        do {
            // Try to use the real service
            return try await geminiService.generateText(prompt: prompt)
        } catch {
            ThoughtLogger.logDecision(topic: "API Failure", decision: "Fallback to offline generator", reasoning: "Gemini API unavailable or key missing.")
            return "Offline Mode: Just another day on the asphalt. (Check API Key for the full story)."
        }
    }
    
    private func updateState(season: SeasonArc, newEpisodeTitle: String, summary: String) async {
        var updatedSeason = season
        let newEpisode = Episode(
            id: UUID(),
            date: Date(),
            title: newEpisodeTitle,
            summary: summary,
            tags: ["Auto-Generated"]
        )
        updatedSeason.episodes.append(newEpisode)
        
        // Simple heuristic for recurring characters update
        if summary.contains("Coffee") && !updatedSeason.recurringCharacters.contains("The Coffee Shop") {
            updatedSeason.recurringCharacters.append("The Coffee Shop")
            ThoughtLogger.log(step: "State Update", content: "New recurring location unlocked: The Coffee Shop")
        }
        
        await seasonManager.saveSeason(updatedSeason)
        ThoughtLogger.log(step: "Persistence", content: "Season Arc updated. Total episodes: \(updatedSeason.episodes.count)")
    }
}
