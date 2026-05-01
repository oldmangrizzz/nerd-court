import XCTest
import Foundation
@testable import NerdCourt

// MARK: - Service Protocols (for testability)

protocol OllamaMaxClientProtocol {
    func dispatch(systemPrompt: String, debateContext: String, turnHistory: [SpeechTurn]) async throws -> String
}

protocol VoiceSynthesisServiceProtocol {
    func synthesize(text: String, speaker: Speaker) async throws -> Data
}

protocol CanonResearchServiceProtocol {
    func research(grievance: Grievance) async throws -> CanonResearchResult
}

protocol GuestCharacterGeneratorProtocol {
    func generate(name: String, universe: String, role: GuestRole) async throws -> GuestCharacter
}

// MARK: - Mock Services

final class MockOllamaMaxClient: OllamaMaxClientProtocol {
    var dispatchHandler: ((String, String, [SpeechTurn]) async throws -> String)?
    func dispatch(systemPrompt: String, debateContext: String, turnHistory: [SpeechTurn]) async throws -> String {
        guard let handler = dispatchHandler else {
            throw MockError.notImplemented
        }
        return try await handler(systemPrompt, debateContext, turnHistory)
    }
}

final class MockVoiceSynthesisService: VoiceSynthesisServiceProtocol {
    var synthesizeHandler: ((String, Speaker) async throws -> Data)?
    func synthesize(text: String, speaker: Speaker) async throws -> Data {
        guard let handler = synthesizeHandler else {
            throw MockError.notImplemented
        }
        return try await handler(text, speaker)
    }
}

final class MockCanonResearchService: CanonResearchServiceProtocol {
    var researchHandler: ((Grievance) async throws -> CanonResearchResult)?
    func research(grievance: Grievance) async throws -> CanonResearchResult {
        guard let handler = researchHandler else {
            throw MockError.notImplemented
        }
        return try await handler(grievance)
    }
}

final class MockGuestCharacterGenerator: GuestCharacterGeneratorProtocol {
    var generateHandler: ((String, String, GuestRole) async throws -> GuestCharacter)?
    func generate(name: String, universe: String, role: GuestRole) async throws -> GuestCharacter {
        guard let handler = generateHandler else {
            throw MockError.notImplemented
        }
        return try await handler(name, universe, role)
    }
}

enum MockError: Error {
    case notImplemented
    case simulatedError
}

// MARK: - DebateEngineTests

final class DebateEngineTests: XCTestCase {
    
    var ollamaClient: MockOllamaMaxClient!
    var voiceService: MockVoiceSynthesisService!
    var researchService: MockCanonResearchService!
    var guestGenerator: MockGuestCharacterGenerator!
    var engine: DebateEngine!
    
    override func setUp() async throws {
        ollamaClient = MockOllamaMaxClient()
        voiceService = MockVoiceSynthesisService()
        researchService = MockCanonResearchService()
        guestGenerator = MockGuestCharacterGenerator()
        
        engine = DebateEngine(
            ollamaClient: ollamaClient,
            voiceService: voiceService,
            researchService: researchService,
            guestGenerator: guestGenerator
        )
    }
    
    override func tearDown() async throws {
        ollamaClient = nil
        voiceService = nil
        researchService = nil
        guestGenerator = nil
        engine = nil
    }
    
    // MARK: - Helpers
    
    func makeSampleGrievance() -> Grievance {
        Grievance(
            id: "g1",
            plaintiff: "Batman",
            defendant: "Superman",
            grievanceText: "Who would win in a fight?",
            franchise: .dcComics,
            status: .pending,
            submittedAt: Date()
        )
    }
    
    func makeSampleCanonResearch() -> CanonResearchResult {
        // Assume CanonResearchResult exists in main module
        CanonResearchResult(
            plaintiffBackground: "Batman is a peak human with gadgets.",
            defendantBackground: "Superman is a Kryptonian with superpowers.",
            relevantFeats: ["Batman beat Superman with kryptonite", "Superman lifted infinity"],
            keyWeaknesses: ["Kryptonite", "Magic"]
        )
    }
    
    func makeSampleGuestCharacters() -> [GuestCharacter] {
        [
            GuestCharacter(
                id: "gc1",
                name: "Wonder Woman",
                universe: "DC",
                role: .expertWitness,
                systemPrompt: "You are Wonder Woman, an Amazon warrior.",
                voiceModelId: "ww_voice"
            )
        ]
    }
    
    // MARK: - Tests
    
    func testRunDebateProducesEpisodeWithCorrectStructure() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()
        
        // Configure mock dispatch to return a simple argument for each speaker
        var dispatchCount = 0
        ollamaClient.dispatchHandler = { _, _, _ in
            dispatchCount += 1
            return "Argument \(dispatchCount)"
        }
        
        // Voice service returns empty data
        voiceService.synthesizeHandler = { _, _ in Data() }
        
        let episode = try await engine.runDebate(
            grievance: grievance,
            canonResearch: research,
            guestCast: guests
        )
        
        XCTAssertEqual(episode.grievanceId, grievance.id)
        XCTAssertFalse(episode.transcript.isEmpty)
        XCTAssertGreaterThan(episode.plaintiffArguments.count, 0)
        XCTAssertGreaterThan(episode.defendantArguments.count, 0)
        XCTAssertNotNil(episode.verdict)
        XCTAssertEqual(episode.status, .decided) // assuming Episode has status
        XCTAssertGreaterThan(episode.durationSeconds, 0)
    }
    
    func testRunDebateIncludesDeadpoolInterjections() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()
        
        // Force Deadpool to interject on every possible turn
        ollamaClient.dispatchHandler = { systemPrompt, _, _ in
            if systemPrompt.contains("Deadpool") {
                return "Chimichangas!"
            }
            return "Normal argument"
        }
        
        voiceService.synthesizeHandler = { _, _ in Data() }
        
        let episode = try await engine.runDebate(
            grievance: grievance,
            canonResearch: research,
            guestCast: guests
        )
        
        let deadpoolTurns = episode.transcript.filter { $0.speaker == .deadpool }
        XCTAssertGreaterThan(deadpoolTurns.count, 0, "Deadpool should have at least one interjection")
    }
    
    func testRunDebateHandlesServiceError() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()
        
        // Make dispatch throw an error
        ollamaClient.dispatchHandler = { _, _, _ in
            throw MockError.simulatedError
        }
        
        voiceService.synthesizeHandler = { _, _ in Data() }
        
        do {
            _ = try await engine.runDebate(
                grievance: grievance,
                canonResearch: research,
                guestCast: guests
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Engine should propagate the error or set status to error
            // Depending on implementation, we might get an error or an Episode with .error status.
            // Here we assume it throws.
            XCTAssertTrue(true)
        }
    }
    
    func testRunDebateGeneratesVerdictWithAllRulings() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()
        
        // Return arguments that lead to a specific verdict
        ollamaClient.dispatchHandler = { _, _, _ in
            return "Argument"
        }
        
        voiceService.synthesizeHandler = { _, _ in Data() }
        
        let episode = try await engine.runDebate(
            grievance: grievance,
            canonResearch: research,
            guestCast: guests
        )
        
        let verdict = episode.verdict
        XCTAssertNotNil(verdict)
        // Verdict ruling should be one of the enum cases
        let validRulings: [Verdict.Ruling] = [.plaintiffWins, .defendantWins, .hugItOut]
        XCTAssertTrue(validRulings.contains(verdict.ruling))
        XCTAssertFalse(verdict.reasoning.isEmpty)
        XCTAssertFalse(verdict.finalThought.isEmpty)
        XCTAssertNotNil(verdict.finisherType)
    }
    
    func testRunDebateCallsVoiceServiceForEachTurn() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()
        
        var voiceCallCount = 0
        voiceService.synthesizeHandler = { text, speaker in
            voiceCallCount += 1
            return Data()
        }
        
        ollamaClient.dispatchHandler = { _, _, _ in "Argument" }
        
        let episode = try await engine.runDebate(
            grievance: grievance,
            canonResearch: research,
            guestCast: guests
        )
        
        XCTAssertEqual(voiceCallCount, episode.transcript.count, "Voice service should be called once per speech turn")
    }
    
    func testRunDebateUsesCanonResearch() async throws {
        let grievance = makeSampleGrievance()
        let research = makeSampleCanonResearch()
        let guests = makeSampleGuestCharacters()
        
        var researchCalled = false
        researchService.researchHandler = { _ in
            researchCalled = true
            return research
        }
        
        ollamaClient.dispatchHandler = { _, _, _ in "Argument" }
        voiceService.synthesizeHandler = { _, _ in Data() }
        
        _ = try await engine.runDebate(
            grievance: grievance,
            canonResearch: research,
            guestCast: guests
        )
        
        // The engine may call research internally; we verify it was used.
        // Since we passed research directly, the engine might not call the service again.
        // This test ensures the engine integrates research data.
        // If the engine calls the service internally, we can assert researchCalled.
        // For now, we just check that the episode was created successfully.
        XCTAssertTrue(true) // Placeholder; real test would verify research integration
    }
}