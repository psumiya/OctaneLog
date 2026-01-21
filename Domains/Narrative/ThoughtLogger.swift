import Foundation

/// A specialized logger that tracks the agent's "Thought Signatures".
/// This fulfills the "Thought Signatures" requirement by explicitly logging the reasoning process.
public struct ThoughtLogger {
    
    public static func log(step: String, content: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        // XML-style tagging for easy parsing/highlighting
        let formattedLog = """
        [\(timestamp)]
        <thinking_step name="\(step)">
        \(content)
        </thinking_step>
        """
        print(formattedLog)
    }
    
    public static func logDecision(topic: String, decision: String, reasoning: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let formattedLog = """
        [\(timestamp)]
        <decision topic="\(topic)">
          <outcome>\(decision)</outcome>
          <reasoning>\(reasoning)</reasoning>
        </decision>
        """
        print(formattedLog)
    }
}
