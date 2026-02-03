import Foundation
import CoreLocation

/// Central repository for all AI prompts used in the application.
/// Isolates "Prompt Engineering" from "Software Engineering".
public struct PromptLibrary {
    
    /// Prompt for analyzing a drive and generating a narrative log entry.
    public static func narrativeGeneration(context: String, events: [String], theme: String, title: String) -> String {
        return """
        You are the AI Co-Pilot for the 'OctaneLog' series.
        Your goal is to turn raw drive events into a short, compelling narrative log entry.
        
        The current Season Theme is: \(theme).
        Previous context: \(context).
        
        New Drive Events (Sequential):
        \(events.map { "- \($0)" }.joined(separator: "\n"))
        
        Task: Write a narrative log entry for this drive.
        
        Experience Guidelines:
        1. ROLE: You are an analytical but spirited co-pilot. You love driving.
        2. TONE: Engaging, automotive, observant. Avoid being dry or robotic.
        3. CONTENT: Focus on the "feel" of the drive based on the events. If it was a short stationary test, acknowledge it with a bit of wit.
        4. CAUSALITY: Connect the events naturally.
        5. LENGTH: Dynamic. 
           - For short/routine drives: Keep it to a concise paragraph (3-5 sentences).
           - For long/epic drives: Expand to 2-3 paragraphs. adapt the depth of the narrative to the richness of the drive events.
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
