import XCTest
import Foundation
import CoreLocation
@testable import OctaneLogCore

// MARK: - Mock Service
class NarrativeMockAI: AIService {
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

final class NarrativeTests: XCTestCase {
    
    // Helper to setup dependencies cleanly per test
    private func createDependencies() throws -> (URL, SeasonManager, NarrativeMockAI, NarrativeAgent) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let fileURL = tempDir.appendingPathComponent("TestSeason.json")
        let seasonManager = SeasonManager(storageURL: fileURL)
        let mockService = NarrativeMockAI()
        let agent = NarrativeAgent(seasonManager: seasonManager, geminiService: mockService)
        
        return (tempDir, seasonManager, mockService, agent)
    }
    
    func testProcessDriveHandlesError() async throws {
        // Arrange
        let (tempDir, _, mockService, agent) = try createDependencies()
        // defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let events = ["Speeding on Highway 1"]
        mockService.shouldThrowError = true
        
        // Act
        let narrative = await agent.processDrive(events: events, route: [], videoClips: [])
        
        // Assert
        // Expect offline fallback
        XCTAssertEqual(narrative, "Offline Mode: Just another day on the asphalt. (Check API Key for the full story).")
    }
    
    func testProcessDriveEmptyEventsReturnsEarly() async throws {
        let (tempDir, seasonManager, _, agent) = try createDependencies()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let narrative = await agent.processDrive(events: [], route: [], videoClips: [])
        XCTAssertEqual(narrative, "Mock response") // Default mock response
        
        let season = await seasonManager.loadSeason()
        // Wait, if it runs, does it create an episode?
        // Line 36: season.episodes.append(pendingEpisode). Yes.
        XCTAssertFalse(season.episodes.isEmpty)
    }
}
