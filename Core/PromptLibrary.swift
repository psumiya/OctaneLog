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
}
