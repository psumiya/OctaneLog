import Foundation
import CoreLocation
import OctaneLogCore

// Helper Mock classes for Manual Verification
class MockAIService: AIService {
    func generateText(prompt: String) async throws -> String {
        if prompt.contains("OctaneSoul") {
             return """
             {
                "soulTitle": "The Mock Soul",
                "soulDescription": "This is a mock description for verification."
             }
             """
        }
        return "Mock Recap for: " + (prompt.contains("Weekly") ? "Weekly" : (prompt.contains("Monthly") ? "Monthly" : "Yearly"))
    }
    func generateJSON<T>(prompt: String, type: T.Type) async throws -> T where T : Decodable {
        fatalError("Not implemented")
    }
    

}

class MockDateProvider {
    var date: Date = Date()
}

public struct RecapVerifier {
    public static func verifyRecaps() async {
        print("\n🧪 Starting Periodic Recap Verification...")
        
        let manager = SeasonManager.shared
        // Reset state for isolation
        let resetSeason = SeasonArc(id: UUID(), title: "Test", theme: "Test", episodes: [], recurringCharacters: [])
        await manager.saveSeason(resetSeason)
        
        let mockDate = MockDateProvider()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Start date: Jan 1st
        mockDate.date = formatter.date(from: "2026-01-01")!
        
        let agent = NarrativeAgent(seasonManager: manager, geminiService: MockAIService(), dateProvider: { mockDate.date })
        
        print("   Step 1: Process Drive on Jan 1st...")
        _ = await agent.processDrive(events: ["Drive 1"], route: [], videoClips: [], driveID: nil)
        
        var season = await manager.loadSeason()
        assert(season.recaps.isEmpty, "Starting state incorrect: Should be no recaps.")
        
        print("   Step 2: Fast forward to Jan 8th (Weekly Trigger)...")
        mockDate.date = formatter.date(from: "2026-01-08")!
        _ = await agent.processDrive(events: ["Drive 2"], route: [], videoClips: [], driveID: nil)
        
        season = await manager.loadSeason()
        if season.recaps.count == 1 && season.recaps.first?.periodType == "Weekly" {
            print("   ✅ Weekly Recap Triggered Successfully.")
        } else {
            print("   ❌ Weekly Recap Failed! Found: \(season.recaps.count) recaps.")
        }
        
        print("   Step 3: Fast forward to Jan 31st (Monthly Trigger)...")
        mockDate.date = formatter.date(from: "2026-01-31")!
        _ = await agent.processDrive(events: ["Drive EOM"], route: [], videoClips: [], driveID: nil)
        
        season = await manager.loadSeason()
        if season.recaps.contains(where: { $0.periodType == "Monthly" }) {
             print("   ✅ Monthly Recap Triggered Successfully.")
        } else {
             print("   ❌ Monthly Recap Failed.")
        }
        
        print("\n✅ Verification Complete.")
    }
}
