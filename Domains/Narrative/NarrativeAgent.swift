import Foundation

/// The "Showrunner" agent that orchestrates the user's life narrative.
/// It uses a multi-step verification process (Thinking Levels) and persists state (Season Arc).
public actor NarrativeAgent {
    private let seasonManager: SeasonManager
    private let geminiService: AIService // Use Protocol
    private let dateProvider: () -> Date
    
    public init(seasonManager: SeasonManager = .shared, geminiService: AIService = GeminiService(), dateProvider: @escaping () -> Date = Date.init) {
        self.seasonManager = seasonManager
        self.geminiService = geminiService
        self.dateProvider = dateProvider
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
        
        // 5. Periodic Summaries
        await checkAndGenerateRecaps(season: season)
        
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
        // Use PromptLibrary for prompt construction
        let prompt = PromptLibrary.narrativeGeneration(
            context: season.recurringCharacters.joined(separator: ", "),
            events: events,
            theme: season.theme,
            title: season.title
        )
        
        ThoughtLogger.log(step: "Prompt Engineering", content: "Constructed prompt with \(season.episodes.count) episodes of history.")
        
        do {
            // Use the protocol-based service
            return try await geminiService.generateText(prompt: prompt)
        } catch {
            ThoughtLogger.logDecision(topic: "API Failure", decision: "Fallback to offline generator", reasoning: "Gemini API unavailable or key missing.")
            return "Offline Mode: Just another day on the asphalt. (Check API Key for the full story)."
        }
    }
    
    private func checkAndGenerateRecaps(season: SeasonArc) async {
        let now = dateProvider()
        let calendar = Calendar.current
        var updatedSeason = await seasonManager.loadSeason() // Reload to get latest state
        
        // --- Weekly Recap ---
        let lastWeekly = updatedSeason.lastWeeklyRecapDate ?? updatedSeason.episodes.first?.date ?? now
        // Check if 7 days have passed since last weekly recap (or start of season)
        if let daysSince = calendar.dateComponents([.day], from: lastWeekly, to: now).day, daysSince >= 7 {
            ThoughtLogger.log(step: "Periodic Check", content: "Weekly recap due. Days since last: \(daysSince)")
            await generateAndSaveRecap(periodType: "Weekly", season: &updatedSeason)
            updatedSeason.lastWeeklyRecapDate = now
        }
        
        // --- Monthly Recap ---
        // Check if today is the last day of the month
        if let interval = calendar.dateInterval(of: .month, for: now),
           let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: interval.end) {
            
            let isLastDay = calendar.isDate(now, inSameDayAs: lastDayOfMonth)
            let alreadyDone = updatedSeason.lastMonthlyRecapDate.map { calendar.isDate($0, inSameDayAs: now) } ?? false
            
            if isLastDay && !alreadyDone {
                ThoughtLogger.log(step: "Periodic Check", content: "End of Month detected.")
                await generateAndSaveRecap(periodType: "Monthly", season: &updatedSeason)
                updatedSeason.lastMonthlyRecapDate = now
            }
        }
        
        // --- Yearly Recap ---
        // Check if today is December 31st
        if calendar.component(.month, from: now) == 12 && calendar.component(.day, from: now) == 31 {
             let alreadyDone = updatedSeason.lastYearlyRecapDate.map { calendar.isDate($0, inSameDayAs: now) } ?? false
            
            if !alreadyDone {
                ThoughtLogger.log(step: "Periodic Check", content: "End of Year detected.")
                await generateAndSaveRecap(periodType: "Yearly", season: &updatedSeason)
                updatedSeason.lastYearlyRecapDate = now
            }
        }
        
        await seasonManager.saveSeason(updatedSeason)
    }
    
    private func generateAndSaveRecap(periodType: String, season: inout SeasonArc) async {
        // Filter episodes for the period? 
        // For simplicity, we pass the last 10 episodes or filter by date.
        // Let's pass episodes from the relevant window to keep context focused.
        // But for now, just passing the last 7 episodes for Weekly, last 30 for Monthly?
        // To save tokens, let's just pass the last 10 episodes regardless, or maybe refine logic later.
        let recentEpisodes = season.episodes.suffix(15) // simple heuristic
        
        let prompt = PromptLibrary.periodicRecap(
            context: season.title,
            episodes: Array(recentEpisodes),
            periodType: periodType
        )
        
        do {
            let summary = try await geminiService.generateText(prompt: prompt)
            let recap = Recap(date: dateProvider(), periodType: periodType, summary: summary)
            season.recaps.append(recap)
            ThoughtLogger.log(step: "Recap Generation", content: "Generated \(periodType) Recap: \(summary)")
        } catch {
            ThoughtLogger.logDecision(topic: "Recap Failure", decision: "Skip", reasoning: "API Error: \(error)")
        }
    }
    
    private func updateState(season: SeasonArc, newEpisodeTitle: String, summary: String) async {
        var updatedSeason = season
        let newEpisode = Episode(
            id: UUID(),
            date: dateProvider(),
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
