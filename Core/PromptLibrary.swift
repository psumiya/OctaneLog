import Foundation
import CoreLocation

/// Central repository for all AI prompts used in the application.
/// Isolates "Prompt Engineering" from "Software Engineering".
public struct PromptLibrary {
    
    /// Prompt for analyzing a drive and generating a narrative log entry.
    public static func narrativeGeneration(context: String, events: [String], theme: String, title: String) -> String {
        return """
        You are a Field Logger creating a concise travel log called '\(title)'.
        The Theme is: \(theme).
        
        Previous context: \(context).
        
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
    }
    
    /// Prompt for describing a scene from an image.
    public static func sceneDescription(location: CLLocation?) -> String {
        var basePrompt = "Describe the scene concisely. Do NOT capture or transcribe license plates, faces, or specific street numbers. Focus on vehicle types, traffic flow, and environment."
        
        if let loc = location {
             basePrompt += " Context: Coordinates \(loc.coordinate.latitude), \(loc.coordinate.longitude)."
        }
        
        return basePrompt
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
}
