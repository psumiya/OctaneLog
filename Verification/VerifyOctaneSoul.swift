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
        print("   Step 1: Process Drive (Ep 1)...")
    _ = await agent.processDrive(events: ["Drive to Work", "Commute"], route: [], videoClips: [], driveID: nil)
    
    print("   Step 2: Process Drive (Ep 2)...")
    _ = await agent.processDrive(events: ["Scenic Drive", "Mountains"], route: [], videoClips: [], driveID: nil)
    
    print("   Step 3: Process Drive (Ep 3)...")
    _ = await agent.processDrive(events: ["Grocery Run", "Errands"], route: [], videoClips: [], driveID: nil)
        
        // 2. Fast forward to Dec 31st (Trigger Date)
        print("   Step 2: Jumping to Dec 31st...")
        mockDate.date = formatter.date(from: "2026-12-31")!
        
        // Trigger
        _ = await agent.processDrive(events: ["Final drive of the year"], route: [], videoClips: [], driveID: nil)
        
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
