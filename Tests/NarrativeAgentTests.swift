import XCTest
import Foundation
import CoreLocation
@testable import OctaneLogCore

// MARK: - Mock Service
class MockAIService: AIService {
    var shouldThrowError = false
    var cannedResponse = "Mock response"
    
    init() {}
    
    func generateText(prompt: String) async throws -> String {
        if shouldThrowError {
            throw GeminiError.notConfigured
        }
        return cannedResponse
    }
    
    func generateDescription(from imageData: Data, location: CLLocation?) async throws -> String {
        if shouldThrowError {
            throw GeminiError.notConfigured
        }
        return "Mock Description"
    }
}

final class NarrativeAgentTests: XCTestCase {
    
    var tempDir: URL!
    var mockService: MockAIService!
    var seasonManager: SeasonManager!
    var agent: NarrativeAgent!
    
    override func setUp() async throws {
        // Create a temporary directory for the test season file
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let fileURL = tempDir.appendingPathComponent("TestSeason.json")
        seasonManager = SeasonManager(storageURL: fileURL)
        
        mockService = MockAIService()
        agent = NarrativeAgent(seasonManager: seasonManager, geminiService: mockService)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    func testProcessDrive_SavesStateAndGeneratesNarrative() async {
        // Arrange
        let events = ["Speeding on Highway 1", "Stopped at red light", "Scenic view of ocean"]
        mockService.cannedResponse = "You drove fast and saw the ocean."
        
        // Act
        let narrative = await agent.processDrive(events: events)
        
        // Assert
        XCTAssertEqual(narrative, "You drove fast and saw the ocean.")
        
        let season = await seasonManager.loadSeason()
        XCTAssertEqual(season.episodes.count, 1)
        
        let episode = season.episodes.first!
        XCTAssertEqual(episode.title, "Drive #1") 
        
        XCTAssertEqual(episode.summary, "You drove fast and saw the ocean.")
        XCTAssertFalse(episode.isProcessing)
    }
    
    func testProcessDrive_EmptyEvents_ReturnsEarly() async {
        let narrative = await agent.processDrive(events: [])
        XCTAssertEqual(narrative, "No events to narrate.")
        
        let season = await seasonManager.loadSeason()
        XCTAssertTrue(season.episodes.isEmpty)
    }
}
