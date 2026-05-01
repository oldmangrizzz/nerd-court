import XCTest
@testable import NerdCourt

final class GuestCharacterGeneratorTests: XCTestCase {

    var generator: GuestCharacterGenerator!

    override func setUp() async throws {
        let deltaHost = ProcessInfo.processInfo.environment["DELTA_HOST"] ?? "delta.local"
        let client = DeltaDispatchClient(deltaHost: deltaHost)
        generator = GuestCharacterGenerator(ollamaClient: client)
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
