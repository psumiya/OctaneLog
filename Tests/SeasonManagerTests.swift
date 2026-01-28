import XCTest
@testable import OctaneLogCore

final class SeasonManagerTests: XCTestCase {
    
    // Helper to create a dummy episode
    private func createEpisode(id: UUID = UUID()) -> Episode {
        return Episode(
            id: id,
            date: Date(),
            title: "Test Episode",
            summary: "A test summary",
            tags: ["test"]
        )
    }
    
    func testDeleteSingleEpisode() async {
        let manager = SeasonManager.shared
        // Ensure starting clean or predictable state if possible, 
        // but since it's a singleton using file storage, we might need to be careful.
        // For now, we'll load, add a specific item, save, then delete it.
        
        var season = await manager.loadSeason()
        let newEpisode = createEpisode()
        season.episodes.append(newEpisode)
        await manager.saveSeason(season)
        
        // Verify added
        season = await manager.loadSeason()
        XCTAssertTrue(season.episodes.contains(where: { $0.id == newEpisode.id }), "Episode should be present before delete")
        
        // Execute Delete
        await manager.deleteEpisode(id: newEpisode.id)
        
        // Verify Deleted
        season = await manager.loadSeason()
        XCTAssertFalse(season.episodes.contains(where: { $0.id == newEpisode.id }), "Episode should be removed after delete")
    }
    
    func testDeleteMultipleEpisodes() async {
        let manager = SeasonManager.shared
        
        var season = await manager.loadSeason()
        let ep1 = createEpisode()
        let ep2 = createEpisode()
        let ep3 = createEpisode() // This one won't be deleted
        
        season.episodes.append(contentsOf: [ep1, ep2, ep3])
        await manager.saveSeason(season)
        
        // Execute Bulk Delete
        await manager.deleteEpisodes(ids: [ep1.id, ep2.id])
        
        // Verify
        season = await manager.loadSeason()
        XCTAssertFalse(season.episodes.contains(where: { $0.id == ep1.id }), "Episode 1 should be deleted")
        XCTAssertFalse(season.episodes.contains(where: { $0.id == ep2.id }), "Episode 2 should be deleted")
        XCTAssertTrue(season.episodes.contains(where: { $0.id == ep3.id }), "Episode 3 should remain")
    }
    
}
