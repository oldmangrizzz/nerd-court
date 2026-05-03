import XCTest
import Foundation
@testable import NerdCourt

private final class StubLLMClient: LLMClient, @unchecked Sendable {
    func dispatch(systemPrompt: String,
                  debateContext: String,
                  turnHistory: [SpeechTurn]) async throws -> String {
        return "Stubbed argument for unit test."
    }
}

final class DebateEngineTests: XCTestCase {

    var engine: DebateEngine!

    override func setUp() async throws {
        engine = DebateEngine(ollamaClient: StubLLMClient())
    }

    override func tearDown() async throws {
        engine = nil
    }

    // MARK: - Helpers

    func makeSampleGrievance() -> Grievance {
        Grievance(
            id: "g1",
            plaintiff: "Batman",
            defendant: "Superman",
            grievanceText: "Who would win in a fight?"
        )
    }

    func makeSampleCanonResearch() -> CanonResearchResult {
        CanonResearchResult(
            sources: [],
            keyFacts: ["Batman is a peak human with gadgets.", "Superman is a Kryptonian with superpowers."],
            plaintiffEvidence: ["Batman beat Superman with kryptonite"],
            defendantEvidence: ["Superman lifted infinity"],
            researchedAt: .now
        )
    }

    func makeSampleGuestCharacters() -> [GuestCharacter] {
        [
            GuestCharacter(
                id: "gc1",
                name: "Wonder Woman",
                universe: "DC",
                role: "plaintiff_witness",
                personalityPrompt: "You are Wonder Woman, an Amazon warrior.",
                generatedAt: .now
            )
        ]
    }

    // MARK: - Tests

    func testRunDebateProducesEpisodeWithCorrectStructure() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()

        let episode = try await engine.runDebate(
            grievance: grievance,
            research: research,
            guests: guests
        )

        XCTAssertEqual(episode.grievanceId, grievance.id)
        XCTAssertFalse(episode.transcript.isEmpty)
        XCTAssertNotNil(episode.verdict)
        XCTAssertGreaterThan(episode.durationSeconds, 0)
    }

    func testRunDebateIncludesVerdict() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()

        let episode = try await engine.runDebate(
            grievance: grievance,
            research: research,
            guests: guests
        )

        let verdict = episode.verdict
        XCTAssertNotNil(verdict)
        let validRulings: [Verdict.Ruling] = [.plaintiffWins, .defendantWins, .hugItOut]
        XCTAssertTrue(validRulings.contains(verdict!.ruling))
        XCTAssertFalse(verdict!.reasoning.isEmpty)
        XCTAssertFalse(verdict!.punishmentOrReward.isEmpty)
    }
}
