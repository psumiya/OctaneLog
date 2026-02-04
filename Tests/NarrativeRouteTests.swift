import XCTest
@testable import OctaneLogCore
import CoreLocation

final class NarrativeRouteTests: XCTestCase {
    
    func testRoutePersistence() throws {
        // 1. Create Route Points
        let now = Date()
        let route = [
            RoutePoint(latitude: 37.7749, longitude: -122.4194, timestamp: now),
            RoutePoint(latitude: 37.7799, longitude: -122.4294, timestamp: now.addingTimeInterval(60))
        ]
        
        // 2. Create Episode
        let episode = Episode(
            id: UUID(),
            date: now,
            title: "Route Test",
            summary: "Testing Route",
            tags: ["Test"],
            route: route
        )
        
        // 3. Verify Route Data
        XCTAssertEqual(episode.route.count, 2)
        XCTAssertEqual(episode.route.first?.latitude, 37.7749)
    }
    
    func testDirectorServiceRouteAccumulation() {
        let director = DirectorService(videoSource: MockCameraSource())
        // Start session to enable monitoring (mocked)
        // Since we can't easily mock CoreLocation updates from here without refactoring DirectorService to accept a mock LocationService,
        // we will verify the finishDrive() signature and basic state.
        
        let result = director.finishDrive()
        XCTAssertTrue(result.route.isEmpty, "Route should be empty initially")
    }
    
    func testNarrativeAgentProcessDriveWithRoute() async {
         let seasonManager = SeasonManager(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent("TestRouteSeason.json"))
        let agent = NarrativeAgent(seasonManager: seasonManager, geminiService: MockAIService())
        
        let route = [
            RoutePoint(latitude: 37.0, longitude: -122.0, timestamp: Date())
        ]
        
        _ = await agent.processDrive(events: ["Drive Started"], route: route)
        
        let season = await seasonManager.loadSeason()
        guard let savedEpisode = season.episodes.last else {
            XCTFail("Episode should be saved")
            return
        }
        
        XCTAssertEqual(savedEpisode.route.count, 1)
        XCTAssertEqual(savedEpisode.route.first?.latitude, 37.0)
        
        // Cleanup
        try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("TestRouteSeason.json")) 
    }
}

// Simple Mock for testing
class MockAIService: AIService {
    func generateText(prompt: String) async throws -> String {
        return "Mock Narrative"
    }
    
    func generateDescription(from imageData: Data, location: CLLocation?) async throws -> String {
        return "Mock Description"
    }
}
