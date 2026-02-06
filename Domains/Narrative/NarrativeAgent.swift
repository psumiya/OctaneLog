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
    
    private let geminiFileService = GeminiFileService(apiKey: "") // Will init with correct key inside if possible or we pass it. 
    // Actually we should inject it or init it properly. 
    // Ideally we use the AIService protocol but File API is specific.
    // Let's lazily init it or use the key from GeminiService if accessible. 
    // For now, let's look up the key again securely or pass it.
    
    // Better approach: Let's assume GeminiService holds the key or we retrieve it from Keychain again.
    
    /// Processes a completed drive, updates the season arc, and generates an episode summary.
    public func processDrive(events: [String], route: [RoutePoint], videoClips: [URL]) async -> String {
        // Fallback for empty drives
        let driveEvents = events.isEmpty ? ["Drive started.", "Drive ended unexpectedly (No events)."] : events
        let hasVideo = !videoClips.isEmpty
        
        // 1. Context Retrieval
        var season = await seasonManager.loadSeason()
        
        // 2. IMMEDIATE SAVE (The "Save First" Pattern)
        // We create a placeholder episode so data is not lost if the app terminates during AI generation.
        let newEpisodeId = UUID()
        let pendingEpisode = Episode(
            id: newEpisodeId,
            date: dateProvider(),
            title: "Drive #\(season.episodes.count + 1) (Processing)",
            summary: "Analyzing \(videoClips.count) video clips... (Do not close app)",
            tags: [AppConstants.Narrative.processingTag],
            rawEvents: driveEvents,
            route: route,
            isProcessing: true
        )
        season.episodes.append(pendingEpisode)
        await seasonManager.saveSeason(season)
        ThoughtLogger.log(step: "Persistence", content: "Saved raw drive data. Starting AI generation (Video-Mode: \(hasVideo))...")
        
        // 3. Draft Narrative (Simulated or Real Gemini Call)
        // This is the slow part where the user might exit.
        var narrative = ""
        
        if hasVideo {
            narrative = await generateVideoNarrative(clips: videoClips, events: driveEvents, season: season)
        } else {
            narrative = await generateNarrative(events: driveEvents, season: season)
        }
        
        // 4. Update the Placeholder with Real Data
        // We reload the season to ensure we don't overwrite any parallel changes (unlikely here but good practice)
        var currentSeason = await seasonManager.loadSeason()
        if let index = currentSeason.episodes.firstIndex(where: { $0.id == newEpisodeId }) {
            currentSeason.episodes[index].summary = narrative
            currentSeason.episodes[index].title = "Drive #\(currentSeason.episodes.count)" // Finalize title
            currentSeason.episodes[index].tags = [AppConstants.Narrative.newTag] // Reset tags
            currentSeason.episodes[index].isProcessing = false
            
            // Check alignment (formerly step 2, now post-processing)
            let alignment = analyzeAlignment(events: driveEvents, season: currentSeason)
            ThoughtLogger.log(step: "Thematic Analysis", content: alignment)
            
            await seasonManager.saveSeason(currentSeason)
        }
        
        // 5. Periodic Summaries
        await checkAndGenerateRecaps(season: currentSeason)
        
        return narrative
    }
    
    private func generateVideoNarrative(clips: [URL], events: [String], season: SeasonArc) async -> String {
        // 1. Authenticate (Get Key)
        guard let apiKey = KeychainHelper.standard.read(service: "com.octanelog.api.key", account: "gemini_api_key_v1")
            .flatMap({ String(data: $0, encoding: .utf8) }) else {
            return "Error: No API Key found for video analysis."
        }
        
        let fileService = GeminiFileService(apiKey: apiKey)
        var uploadedUris: [String] = []
        
        // 2. Upload Clips
        for (index, clipUrl) in clips.enumerated() {
            do {
                ThoughtLogger.log(step: "Video Upload", content: "Uploading clip \(index + 1)/\(clips.count): \(clipUrl.lastPathComponent)...")
                let name = try await fileService.uploadFile(url: clipUrl, mimeType: "video/quicktime")
                ThoughtLogger.log(step: "Video Processing", content: "Waiting for clip \(index + 1) to be ready...")
                let uri = try await fileService.waitForActiveState(fileName: name)
                uploadedUris.append(uri)
                ThoughtLogger.log(step: "Video Ready", content: "Clip \(index + 1) ready for analysis.")
            } catch {
                print("NarrativeAgent: Failed to upload clip \(clipUrl). Error: \(error)")
                ThoughtLogger.log(step: "Upload Error", content: "Failed to upload \(clipUrl.lastPathComponent): \(error.localizedDescription)")
                // Continue with other clips
            }
        }
        
        if uploadedUris.isEmpty {
            ThoughtLogger.log(step: "Upload Failed", content: "All video uploads failed. Falling back to text-only narrative.")
            return "Error: Failed to upload video clips for analysis. Falling back to text-only mode."
        }
        
        // 3. Generate with Gemini 3
        let prompt = PromptLibrary.narrativeGeneration(
            context: season.recurringCharacters.joined(separator: ", "),
            events: events,
            theme: season.theme,
            title: season.title
        ) + "\n\n[SYSTEM NOTE]: The attached video files are the visual record of this drive. Use them to describe the scenery, lighting, and driving behavior in vivid detail."
        
        do {
            ThoughtLogger.log(step: "Gemini 3 Generation", content: "Generating narrative from \(uploadedUris.count) video files...")
            // Use gemini-3-flash-preview as verified
            return try await fileService.generateContent(
                credential: apiKey,
                model: "gemini-3-flash-preview", 
                prompt: prompt,
                fileURIs: uploadedUris,
                mimeType: "video/quicktime"
            )
        } catch {
             ThoughtLogger.logDecision(topic: "Video Generation Failure", decision: "Fallback to Text", reasoning: "\(error)")
             return await generateNarrative(events: events, season: season) // Fallback to text-only logic
        }
    }
    
    private func analyzeAlignment(events: [String], season: SeasonArc) -> String {
        // In a real system, this would be a separate Gemini call to "Reason" without generating text.
        // "Does this drive reinforce the 'Discovery' theme?"
        if events.contains(where: { $0.contains("Scenic") || $0.contains(AppConstants.Narrative.newTag) }) {
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
            return AppConstants.Narrative.offlineModeSummary
        }
    }
    
    private func checkAndGenerateRecaps(season: SeasonArc) async {
        let now = dateProvider()
        let calendar = Calendar.current
        var updatedSeason = await seasonManager.loadSeason() // Reload to get latest state
        
        // --- Weekly Recap ---
        let lastWeekly = updatedSeason.lastWeeklyRecapDate ?? updatedSeason.episodes.first?.date ?? now
        // Check if 7 days have passed since last weekly recap (or start of season)
        if let daysSince = calendar.dateComponents([.day], from: lastWeekly, to: now).day, daysSince >= AppConstants.Config.weeklyRecapIntervalDays {
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
                
                // ALSO trigger OctaneSoul (Yearly Odyssey)
                await generateAndSaveOctaneSoul(season: &updatedSeason)
                
                updatedSeason.lastYearlyRecapDate = now
            }
        }
        
        await seasonManager.saveSeason(updatedSeason)
    }
    
    // MARK: - OctaneSoul Generation
    
    private func generateAndSaveOctaneSoul(season: inout SeasonArc) async {
        let now = dateProvider()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        
        // 1. Filter Episodes for Current Year
        let yearEpisodes = season.episodes.filter { calendar.component(.year, from: $0.date) == currentYear }
        guard !yearEpisodes.isEmpty else { return }
        
        // 2. Calculate Metadata (Stats)
        let totalDrives = yearEpisodes.count
        
        // Count tags
        var tagCounts: [String: Int] = [:]
        for ep in yearEpisodes {
            for tag in ep.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        let topTags = tagCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        
        // 3. Generate Soul (Persona) via Gemini
        let prompt = PromptLibrary.generateOctaneSoul(context: season.title, episodes: yearEpisodes)
        
        var soulTitle = "The Unknown Driver"
        var soulDesc = "Not enough data to determine the soul."
        
        do {
            let jsonString = try await geminiService.generateText(prompt: prompt)
            
            // Clean markdown fences if present
            let cleanedJSON = jsonString.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let data = cleanedJSON.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                soulTitle = json["soulTitle"] ?? soulTitle
                soulDesc = json["soulDescription"] ?? soulDesc
            }
            
            ThoughtLogger.log(step: "OctaneSoul Generation", content: "Soul Identified: \(soulTitle)")
            
        } catch {
             ThoughtLogger.logDecision(topic: "OctaneSoul Failure", decision: "Skip", reasoning: "API/Parsing Error: \(error)")
        }
        
        // 4. Save
        let report = OctaneSoulReport(
            id: UUID(),
            year: currentYear,
            totalDrives: totalDrives,
            topTags: Array(topTags),
            soulTitle: soulTitle,
            soulDescription: soulDesc
        )
        season.octaneSouls.append(report)
    }
    
    private func generateAndSaveRecap(periodType: String, season: inout SeasonArc) async {
        // Filter episodes for the period? 
        // For simplicity, we pass the last 10 episodes or filter by date.
        // Let's pass episodes from the relevant window to keep context focused.
        // But for now, just passing the last 7 episodes for Weekly, last 30 for Monthly?
        // To save tokens, let's just pass the last 10 episodes regardless, or maybe refine logic later.
        let recentEpisodes = season.episodes.suffix(AppConstants.Config.episodeRecapSuffixCount) // simple heuristic
        
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
            tags: [AppConstants.Narrative.autoGeneratedTag]
        )
        updatedSeason.episodes.append(newEpisode)
        
        // Simple heuristic for recurring characters update
        if summary.contains(AppConstants.Narrative.coffeeKeyword) && !updatedSeason.recurringCharacters.contains(AppConstants.Narrative.recurringCharacterCoffeeShop) {
            updatedSeason.recurringCharacters.append(AppConstants.Narrative.recurringCharacterCoffeeShop)
            ThoughtLogger.log(step: "State Update", content: "New recurring location unlocked: The Coffee Shop")
        }
        
        await seasonManager.saveSeason(updatedSeason)
        ThoughtLogger.log(step: "Persistence", content: "Season Arc updated. Total episodes: \(updatedSeason.episodes.count)")
    }
}
