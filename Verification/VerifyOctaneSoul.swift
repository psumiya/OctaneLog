import Foundation
import CoreLocation
import OctaneLogCore

public struct OctaneSoulVerifier {
    public static func verify() async {
        print("\n🔮 Starting OctaneSoul Verification...")
        
        let manager = SeasonManager.shared
        // Reset state
        let resetSeason = SeasonArc(id: UUID(), title: "Test Soul", theme: "Soul Search", episodes: [], recurringCharacters: [])
        await manager.saveSeason(resetSeason)
        
        // Setup Date Provider to Start of Year
        let mockDate = MockDateProvider()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        mockDate.date = formatter.date(from: "2026-01-01")!
        
        let agent = NarrativeAgent(seasonManager: manager, geminiService: MockAIService(), dateProvider: { mockDate.date })
        
        // 1. Generate some episodes
        print("   Step 1: Simulating drives throughout the year...")
        _ = await agent.processDrive(events: ["Scenic drive on Highway 1"], route: [], videoClips: [])
        
        mockDate.date = formatter.date(from: "2026-06-15")!
        _ = await agent.processDrive(events: ["Night drive in the city", "Heavy traffic"], route: [], videoClips: [])
        
        mockDate.date = formatter.date(from: "2026-11-20")!
        _ = await agent.processDrive(events: ["Mountain pass", "Snowy conditions"], route: [], videoClips: [])
        
        // 2. Fast forward to Dec 31st (Trigger Date)
        print("   Step 2: Jumping to Dec 31st...")
        mockDate.date = formatter.date(from: "2026-12-31")!
        
        // Trigger
        _ = await agent.processDrive(events: ["Final drive of the year"], route: [], videoClips: [])
        
        // 3. Verify
        let season = await manager.loadSeason()
        
        if let soul = season.octaneSouls.first {
            print("   ✅ OctaneSoul Generated!")
            print("      Title: \(soul.soulTitle)")
            print("      Desc:  \(soul.soulDescription)")
            print("      Stats: \(soul.totalDrives) drives, Top Tags: \(soul.topTags)")
            
            if soul.year == 2026 {
                print("   ✅ Year is correct (2026)")
            } else {
                print("   ❌ Year Mismatch: \(soul.year)")
            }
        } else {
            print("   ❌ Failed to generate OctaneSoul.")
            print("   Recaps found: \(season.recaps.count)")
        }
        
        print("\n✅ OctaneSoul Verification Complete.")
    }
}
