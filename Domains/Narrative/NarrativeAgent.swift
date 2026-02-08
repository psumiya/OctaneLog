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
    public func processDrive(events: [String], route: [RoutePoint], videoClips: [URL], driveID: String?, visionAnalyses: [VisionAnalyzer.DriveAnalysis] = []) async -> String {
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
            isProcessing: true,
            driveFolder: driveID // Store the link!
        )
        season.episodes.append(pendingEpisode)
        await seasonManager.saveSeason(season)
        ThoughtLogger.log(step: "Persistence", content: "Saved raw drive data. DriveID: \(driveID ?? "nil"). Starting AI generation...")
        
        // 3. Draft Narrative (Simulated or Real Gemini Call)
        // This is the slow part where the user might exit.
        var narrative = ""
        
        if hasVideo {
            narrative = await generateVideoNarrative(clips: videoClips, events: driveEvents, season: season, visionAnalyses: visionAnalyses)
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
    
    // MARK: - Regeneration & Smart Match
    
    /// Re-generates the narrative for an existing episode using the latest prompt and models.
    /// Attempts to find the video files via `manualDriveURL` (if provided), `driveFolder`, or "Smart Match" date heuristics.
    public func regenerateNarrative(for episodeID: UUID, manualDriveURL: URL? = nil) async -> String {
        // 1. Load Episode
        var season = await seasonManager.loadSeason()
        guard let index = season.episodes.firstIndex(where: { $0.id == episodeID }) else {
            return "Error: Episode not found."
        }
        let episode = season.episodes[index]
        
        ThoughtLogger.log(step: "Regeneration", content: "Starting regeneration for '\(episode.title)'...")
        
        // 2. Determine Drive Folder
        var clips: [URL] = []
        var finalDriveID: String?
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let drivesURL = docsURL.appendingPathComponent("Drives")
        
        if let manualURL = manualDriveURL {
             // MANUAL OVERRIDE
             ThoughtLogger.log(step: "Regeneration", content: "Using manual folder: \(manualURL.path)")
             
             // Check if we can read it (Security Scoped?)
             // The caller (View) should have started access, but we should be careful.
             
             do {
                 let files = try fileManager.contentsOfDirectory(at: manualURL, includingPropertiesForKeys: nil)
                 clips = files.filter { $0.pathExtension == "mov" }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                 
                 // If successful, update the link!
                 // We need to know if this folder is inside our app's Documents/Drives.
                 // If it is, store the UUID. If it's outside (e.g. iCloud Drive), we might not be able to store a persistent ID easily without bookmarks.
                 // For now, let's try to see if the folder name is a UUID and assumes it's one of ours.
                 if let uuid = UUID(uuidString: manualURL.lastPathComponent) {
                      finalDriveID = uuid.uuidString
                 }
             } catch {
                 return "Error: Could not read manual folder. \(error.localizedDescription)"
             }
             
        } else {
            // AUTOMATIC / SMART MATCH
            var driveID = episode.driveFolder
            
            // SMART MATCH LOGIC: If no ID, scan folders by date
            if driveID == nil {
                ThoughtLogger.log(step: "Smart Match", content: "No Drive ID linked. Scouring file system for matching folder...")
                do {
                    let driveFolders = try fileManager.contentsOfDirectory(at: drivesURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
                    
                    for folder in driveFolders {
                        if let attrs = try? fileManager.attributesOfItem(atPath: folder.path),
                           let creationDate = attrs[.creationDate] as? Date {
                            
                            // Match within 2 minutes (120 seconds) tolerance
                            if abs(creationDate.timeIntervalSince(episode.date)) < 120 {
                                driveID = folder.lastPathComponent
                                ThoughtLogger.log(step: "Smart Match", content: "✅ FOUND MATCH! Linked to folder: \(driveID!)")
                                break
                            }
                        }
                    }
                } catch {
                    ThoughtLogger.log(step: "Smart Match", content: "Failed to scan drives: \(error)")
                }
            }
            
            if let dID = driveID {
                finalDriveID = dID
                let driveDir = drivesURL.appendingPathComponent(dID)
                do {
                    let files = try fileManager.contentsOfDirectory(at: driveDir, includingPropertiesForKeys: nil)
                    clips = files.filter { $0.pathExtension == "mov" }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                } catch {
                    // fallthrough
                }
            }
        }
        
        if clips.isEmpty {
            return "Error: No video clips found. Please select a folder manually."
        }
        
        // 3. Persist Link (if found)
        if let foundID = finalDriveID, season.episodes[index].driveFolder != foundID {
             season.episodes[index].driveFolder = foundID
             await seasonManager.saveSeason(season)
             ThoughtLogger.log(step: "Persistence", content: "Linked drive folder: \(foundID)")
        }
        
        // 4. Generate
        // We use stored events if available, or empty events
        let events = episode.rawEvents ?? ["Drive regeneration."]
        
        // Mark as processing UI update
        // Reload season to avoid conflicts
        season = await seasonManager.loadSeason()
        if let idx = season.episodes.firstIndex(where: { $0.id == episodeID }) {
            season.episodes[idx].summary = "Regenerating with Gemini 3..."
            season.episodes[idx].isProcessing = true
            await seasonManager.saveSeason(season)
        }
        
        let newNarrative = await generateVideoNarrative(clips: clips, events: events, season: season, visionAnalyses: [])
        
        // 5. Save Result
        season = await seasonManager.loadSeason()
        if let idx = season.episodes.firstIndex(where: { $0.id == episodeID }) {
            season.episodes[idx].summary = newNarrative
            season.episodes[idx].isProcessing = false
            season.episodes[idx].tags = Array(Set(season.episodes[idx].tags + ["Remastered"])) // Add tag
            await seasonManager.saveSeason(season)
        }
        
        return newNarrative
    }
    
    // MARK: - Season Analysis
    
    /// Analyzes the current season's episodes to determine the overarching theme and title.
    /// Updates the SeasonArc with the new metadata.
    public func analyzeCurrentSeason() async -> String {
        var season = await seasonManager.loadSeason()
        
        // 1. Gather Context
        // We use all episodes, or maybe the last 20 if it's too long.
        let episodes = season.episodes.suffix(20)
        
        if episodes.isEmpty {
             return "Not enough episodes to analyze."
        }
        
        ThoughtLogger.log(step: "Season Analysis", content: "Analyzing \(episodes.count) episodes for season theme...")
        
        // 2. Generate
        let prompt = PromptLibrary.analyzeSeasonTheme(episodes: Array(episodes))
        ThoughtLogger.log(step: "Season Prompt", content: "Prompt sent to Gemini:\n\(prompt)")
        
        do {
            let jsonString = try await geminiService.generateText(prompt: prompt)
            
            // Clean markdown fences if present
            let cleanedJSON = jsonString.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let data = cleanedJSON.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                
                if let newTheme = json["theme"] {
                    season.theme = newTheme
                }
                if let newTitle = json["title"] {
                    season.title = newTitle
                }
                if let newNarrative = json["sagaNarrative"] {
                    season.sagaNarrative = newNarrative
                }
                
                await seasonManager.saveSeason(season)
                ThoughtLogger.log(step: "Season Update", content: "Theme: \(season.theme)\nTitle: \(season.title)\nNarrative Length: \(season.sagaNarrative?.count ?? 0) chars")
                return "Season updated: \(season.title) (\(season.theme))"
            } else {
                return "Error: Could not parse AI response."
            }
        } catch {
            ThoughtLogger.logDecision(topic: "Season Analysis Failure", decision: "Abort", reasoning: "\(error)")
            return "Error analyzing season: \(error.localizedDescription)"
        }
    }
    
    private func generateVideoNarrative(clips: [URL], events: [String], season: SeasonArc, visionAnalyses: [VisionAnalyzer.DriveAnalysis]) async -> String {
        // 1. Authenticate (Get Key)
        guard let apiKey = KeychainHelper.standard.read(service: "com.octanelog.api.key", account: "gemini_api_key_v1")
            .flatMap({ String(data: $0, encoding: .utf8) }) else {
            return "Error: No API Key found for video analysis."
        }
        
        // 2. Build Vision Analysis Summary
        var visionSummary = ""
        if !visionAnalyses.isEmpty {
            ThoughtLogger.log(step: "Local Analysis", content: "Processing \(visionAnalyses.count) video clips with Vision framework...")
            
            var allObjects = Set<String>()
            var allScenes = Set<String>()
            var avgBrightness: Double = 0
            
            for analysis in visionAnalyses {
                allObjects.formUnion(analysis.detectedObjects)
                allScenes.formUnion(analysis.sceneTypes)
                avgBrightness += analysis.averageBrightness
            }
            
            avgBrightness /= Double(visionAnalyses.count)
            let timeOfDay = visionAnalyses.first?.timeOfDay ?? "Unknown"
            
            visionSummary = """
            
            [LOCAL VISION ANALYSIS]:
            - Time of Day: \(timeOfDay)
            - Detected Objects: \(Array(allObjects).prefix(15).joined(separator: ", "))
            - Scene Types: \(Array(allScenes).joined(separator: ", "))
            - Lighting: \(String(format: "%.0f", avgBrightness * 100))% brightness
            """
            
            ThoughtLogger.log(step: "Vision Summary", content: visionSummary)
        }
        
        // 3. Decide: Upload video or use Vision-only?
        // For short drives (<2 min) or if Vision found interesting content, upload video
        let shouldUploadVideo = clips.count <= 2 || !visionAnalyses.isEmpty
        
        if !shouldUploadVideo {
            // Use Vision analysis only (faster, cheaper)
            ThoughtLogger.log(step: "Smart Mode", content: "Using Vision-only analysis (no video upload)")
            return await generateNarrative(events: events + [visionSummary], season: season)
        }
        
        let fileService = GeminiFileService(apiKey: apiKey)
        var uploadedUris: [String] = []
        
        // 4. Upload Clips (only if needed)
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
            ThoughtLogger.log(step: "Upload Failed", content: "All video uploads failed. Using Vision analysis only.")
            return await generateNarrative(events: events + [visionSummary], season: season)
        }
        
        // 5. Generate with Gemini 3 (Video + Vision metadata)
        let prompt = PromptLibrary.narrativeGeneration(
            context: season.recurringCharacters.joined(separator: ", "),
            events: events,
            theme: season.theme,
            title: season.title
        ) + visionSummary + "\n\n[SYSTEM NOTE]: The attached video files are the visual record of this drive. Use them along with the Vision analysis to describe the scenery, lighting, and driving behavior in vivid detail."
        
        do {
            ThoughtLogger.log(step: "Gemini 3 Generation", content: "Generating narrative from \(uploadedUris.count) video files + Vision analysis...")
            // Use gemini-3-flash-preview as verified
            return try await fileService.generateContent(
                credential: apiKey,
                model: "gemini-3-flash-preview", 
                prompt: prompt,
                fileURIs: uploadedUris,
                mimeType: "video/quicktime"
            )
        } catch {
             ThoughtLogger.logDecision(topic: "Video Generation Failure", decision: "Fallback to Vision-only", reasoning: "\(error)")
             return await generateNarrative(events: events + [visionSummary], season: season)
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
