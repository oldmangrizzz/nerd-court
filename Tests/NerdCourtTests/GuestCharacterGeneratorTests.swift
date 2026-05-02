import XCTest
@testable import NerdCourt

/// Mock LLM client for testing GuestCharacterGenerator without hitting a real server.
actor MockLLMClient: LLMClient {
    var cannedResponse: String = "Mock personality prompt for testing purposes."

    func dispatch(systemPrompt: String, debateContext: String, turnHistory: [SpeechTurn]) async throws -> String {
        return cannedResponse
    }
}

final class GuestCharacterGeneratorTests: XCTestCase {

    var generator: GuestCharacterGenerator!

    override func setUp() async throws {
        let mockClient = MockLLMClient()
        generator = GuestCharacterGenerator(ollamaClient: mockClient)
    }

    override func tearDown() async throws {
        generator = nil
    }

    // MARK: - Tests

    func testGenerateReturnsCharacter() async throws {
        let character = try await generator.generate(
            name: "Deadpool",
            universe: "Marvel",
            role: "plaintiff_witness"
        )

        XCTAssertEqual(character.name, "Deadpool")
        XCTAssertEqual(character.universe, "Marvel")
        XCTAssertEqual(character.role, "plaintiff_witness")
        XCTAssertFalse(character.personalityPrompt.isEmpty)
    }

    func testGenerateWithEmptyNameThrows() async {
        do {
            _ = try await generator.generate(name: "", universe: "U", role: "witness")
            XCTFail("Expected validation error for empty name")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testGenerateWithEmptyUniverseThrows() async {
        do {
            _ = try await generator.generate(name: "Char", universe: "", role: "witness")
            XCTFail("Expected validation error for empty universe")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
