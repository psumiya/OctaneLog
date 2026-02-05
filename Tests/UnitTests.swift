import XCTest
@testable import OctaneLogCore

final class UnitTests: XCTestCase {
    
    func testDirectorServiceInitialization() {
        let director = DirectorService()
        XCTAssertNotNil(director, "DirectorService should initialize")
        XCTAssertFalse(director.isRunning)
    }
    
    func testGeminiServiceInitialization() {
        let service = GeminiService()
        // Should initialize safely without crash even if key is missing (key logic is in init or configure)
        XCTAssertNotNil(service, "GeminiService should initialize")
    }
    
// testDirectorStopSessionMaintainsLastFrame REMOVED - Logic no longer applies in Video-First architecture.
}
