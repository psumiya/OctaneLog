import XCTest
import CoreLocation
@testable import OctaneLogCore

// MARK: - Mocks

class IntegrationMockAIService: AIService {
    var generatedTextResponse: String = "Mocked AI Response"
    var generateDescriptionResponse: String = "Mocked Description"
    
    func generateText(prompt: String) async throws -> String {
        return generatedTextResponse
    }
    
    func generateDescription(from imageData: Data, location: CLLocation?) async throws -> String {
        return generateDescriptionResponse
    }
}

// MARK: - Integration Tests

final class IntegrationTests: XCTestCase {
    
    var tempDirectory: URL!
    var seasonFileUtils: URL!
    
    override func setUp() {
        super.setUp()
        // Create a temporary directory for each test
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        seasonFileUtils = tempDirectory.appendingPathComponent("SeasonArc.json")
    }
    
    override func tearDown() {
        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    // Test Case 1: The Full Drive Cycle
    func testDirectorToNarrativeFlow() async throws {
        // 1. Setup Dependencies
        let mockAI = IntegrationMockAIService()
        mockAI.generatedTextResponse = "Integration Test Narrative Summary"
        
        let seasonManager = SeasonManager(storageURL: seasonFileUtils)
        let narrativeAgent = NarrativeAgent(seasonManager: seasonManager, geminiService: mockAI)
        let director = DirectorService() // Uses internal MockCameraSource by default in Simulator/Tests
        
        // 2. Simulate Drive
        await director.startSession()
        XCTAssertTrue(director.isRunning)
        
        // Simulate collecting some events
        // Note: logEvent appends a timestamp, so we just check count mainly
        director.logEvent("Engine Started")
        director.logEvent("Speed exceeded 88mph")
        
        // 3. Stop Drive and Process
        director.stopSession()
        XCTAssertFalse(director.isRunning)
        
        let result = director.finishDrive()
        let events = result.events
        // finishDrive also logs "Drive ended...", so count should be 2 + 1 = 3?
        // Let's check DirectorService.finishDrive implementation:
        // func finishDrive() -> [String] {
        //     self.logEvent("Drive ended...")
        //     let capturedEvents = self.events
        //     ...
        // so if we logged 2 events, verify logic:
        // logEvent "Drive started" (in startSession) -> 1
        // logEvent "Engine Started" -> 2
        // logEvent "Speed..." -> 3
        // finishDrive -> logEvent "Drive ended" -> 4
        // So total events should be 4.
        
        XCTAssertGreaterThanOrEqual(events.count, 3)
        
        // 4. Generate Narrative
        let summary = await narrativeAgent.processDrive(events: events, route: [], videoClips: [])
        
        // 5. Verification
        XCTAssertEqual(summary, "Integration Test Narrative Summary")
        
        // Verify Persistence
        let savedSeason = await seasonManager.loadSeason()
        XCTAssertEqual(savedSeason.episodes.count, 1)
        XCTAssertEqual(savedSeason.episodes.first?.summary, "Integration Test Narrative Summary")
        XCTAssertFalse(savedSeason.episodes.first?.isProcessing ?? true)
    }
    
    // Test Case 2: Async Persistence ("Save-First" Pattern)
    func testSaveFirstPattern() async throws {
        let mockAI = IntegrationMockAIService()
        // Determine a way to pause or inspect state during "processing" might be hard without more hooks,
        // but we can verify the final state and the "isProcessing" flag flow if we had granular visibility.
        // For now, let's verify that a "Processing" episode can be saved.
        
        let seasonManager = SeasonManager(storageURL: seasonFileUtils)
        var season = await seasonManager.loadSeason()
        
        let pendingEp = Episode(
            id: UUID(),
            date: Date(),
            title: "Pending Drive",
            summary: "Analyzing...",
            tags: ["Processing"],
            rawEvents: ["Event 1"],
            isProcessing: true
        )
        season.episodes.append(pendingEp)
        await seasonManager.saveSeason(season)
        
        // Reload and verify
        let reloadedSeason = await seasonManager.loadSeason()
        let loadedEp = reloadedSeason.episodes.first
        XCTAssertNotNil(loadedEp)
        XCTAssertTrue(loadedEp?.isProcessing == true)
        XCTAssertEqual(loadedEp?.summary, "Analyzing...")
    }
}
