import Foundation
import CoreLocation

/// Central repository for all AI prompts used in the application.
/// Isolates "Prompt Engineering" from "Software Engineering".
public struct PromptLibrary {
    
    /// Prompt for analyzing a drive and generating a narrative log entry.
    public static func narrativeGeneration(context: String, events: [String], theme: String, title: String) -> String {
        return """
        Analyze this video for the 'OctaneLog' series as my spirited AI Co-Pilot. Write a 2-paragraph narrative on the 'feel' and transition of the drive, followed by bulleted 'Co-Pilot Notes' on technical maneuvers and landmarks. 
        
        STRICT PRIVACY RULE: Do not mention, transcribe, or approximate license plates, specific street numbers, or exact addresses. Use general descriptors (e.g., 'a silver sedan,' 'the local grocery hub,' or 'a major intersection') to maintain total anonymity while capturing the drive's character.
        
        (Telemetry Events for Reference):
        \(events.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
    

    /// Generates a high-level recap for a specific time period.
    public static func periodicRecap(context: String, episodes: [Episode], periodType: String) -> String {
        let episodeLog = episodes.map { "- \($0.date.formatted(date: .numeric, time: .omitted)): \($0.summary)" }.joined(separator: "\n")
        
        return """
        You are the Narrator of a life-log series called '\(context)'.
        
        Current Task: Write a \(periodType) Recap (e.g., "Weekly Update", "End of Month Review").
        
        Source Material (Recent Episodes):
        \(episodeLog)
        
        Directives:
        1. SYNTHESIS: Do not just list the events. Identify the pattern. Was it a busy week? A quiet one?
        2. HIGHLIGHTS: Mention 1-2 standout moments or recurring locations ("The Coffee Shop" appeared 3 times).
        3. TRANSITION: End with a forward-looking sentence about the next chapter.
        4. LENGTH: Max 4 sentences.
        
        Tone: Reflective, like a journal entry summarizing a chapter of life.
        """
    }
    
    /// Generates a structured 'OctaneSoul' (Yearly Odyssey) report in JSON format.
    /// Returns a JSON string suitable for decoding specific fields manually (since we can't trust the model to output perfect JSON schema every time without typed API, 
    /// but for this prompt we will ask for a specific JSON structure).
    public static func generateOctaneSoul(context: String, episodes: [Episode]) -> String {
        // We pass the full list of summaries for the year
        let episodeLog = episodes.map { "- \($0.date.formatted(date: .numeric, time: .omitted)): \($0.summary)" }.joined(separator: "\n")
        
        return """
        You are the Keeper of the Road.
        Analyze the past year of driving logs for the user's series: '\(context)'.
        
        Source Material:
        \(episodeLog)
        
        Task: Create a 'Driver Persona' (OctaneSoul) based on these habits.
        
        Return ONLY a raw JSON object (no markdown formatting) with this structure:
        {
            "soulTitle": "The [Adjective] [Noun]",  // e.g. "The Midnight Wanderer", "The Asphalt Architect"
            "soulDescription": "A 2-sentence description of why this title fits, citing specific patterns (e.g. 'You prefer rainy nights...')"
        }
        """
    }

    /// Analyzes the recent episodes to determine the overarching theme of the season.
    public static func analyzeSeasonTheme(episodes: [Episode]) -> String {
        let episodeLog = episodes.map { "- \($0.date.formatted(date: .numeric, time: .omitted)): \($0.summary)" }.joined(separator: "\n")
        
        return """
        You are the Director of the 'OctaneLog' series.
        Analyze the recent episodes to identify the current Season Theme.
        
        Source Material:
        \(episodeLog)
        
        Task: Determine the current Season Theme, Title, and Saga Narrative based on the narrative arc so far.
        
        Return ONLY a raw JSON object (no markdown formatting) with this structure:
        {
            "theme": "One Word Theme", // e.g. "Discovery", "Velocity", "Solitude", "Urban"
            "title": "Season Title",   // e.g. "Season 1: The Concrete Jungle", "Season 2: Into the Wild"
            "sagaNarrative": "Two paragraphs summarizing the season's journey so far. Focus on the emotional arc, key recurring locations, and the evolution of the driving style. Make it sound epic and cinematic."
        }
        """
    }
}
