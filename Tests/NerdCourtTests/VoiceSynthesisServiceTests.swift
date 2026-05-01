import XCTest
@testable import NerdCourt

final class VoiceSynthesisServiceTests: XCTestCase {

    var client: VoiceSynthesisClient!

    @MainActor
    override func setUp() async throws {
        client = VoiceSynthesisClient()
    }

    @MainActor
    override func tearDown() async throws {
        client = nil
    }

    // MARK: - Tests

    @MainActor
    func testClientInitSucceeds() {
        XCTAssertNotNil(client)
    }

    @MainActor
    func testPreloadVoices() {
        client.preloadVoices()
        // No crash = success
        XCTAssertTrue(true)
    }
}
