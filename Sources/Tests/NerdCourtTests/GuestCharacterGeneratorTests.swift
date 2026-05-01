import XCTest
@testable import NerdCourt

final class GuestCharacterGeneratorTests: XCTestCase {
    
    // MARK: - Mock Services
    
    class MockCanonResearchService: CanonResearchService {
        var researchResult: Result<CanonResearchResult, Error> = .failure(NSError(domain: "mock", code: 0))
        var lastRequest: (name: String, universe: String, role: GuestRole)?
        
        override func research(name: String, universe: String, role: GuestRole) async throws -> CanonResearchResult {
            lastRequest = (name, universe, role)
            return try researchResult.get()
        }
    }
    
    class MockVoiceSynthesisService: VoiceSynthesisService {
        var voiceModelResult: Result<VoiceModelID, Error> = .failure(NSError(domain: "mock", code: 0))
        var lastSourceURLs: [URL]?
        
        override func generateVoiceModel(from sourceURLs: [URL]) async throws -> VoiceModelID {
            lastSourceURLs = sourceURLs
            return try voiceModelResult.get()
        }
    }
    
    // MARK: - Helpers
    
    func makeGenerator(
        researchResult: Result<CanonResearchResult, Error> = .failure(NSError(domain: "mock", code: 0)),
        voiceResult: Result<VoiceModelID, Error> = .failure(NSError(domain: "mock", code: 0))
    ) -> (generator: GuestCharacterGenerator, research: MockCanonResearchService, voice: MockVoiceSynthesisService) {
        let research = MockCanonResearchService()
        research.researchResult = researchResult
        let voice = MockVoiceSynthesisService()
        voice.voiceModelResult = voiceResult
        let generator = GuestCharacterGenerator(researchService: research, voiceService: voice)
        return (generator, research, voice)
    }
    
    func sampleResearchResult() -> CanonResearchResult {
        CanonResearchResult(
            personality: "Wisecracking anti-hero",
            speechPatterns: ["catchphrase", "sarcasm"],
            voiceReferences: [URL(string: "https://example.com/voice1.mp3")!]
        )
    }
    
    // MARK: - Tests
    
    func testGenerateSuccess() async throws {
        let researchResult = sampleResearchResult()
        let voiceID = VoiceModelID("voice-123")
        let (generator, researchMock, voiceMock) = makeGenerator(
            researchResult: .success(researchResult),
            voiceResult: .success(voiceID)
        )
        
        let character = try await generator.generate(
            name: "Deadpool",
            universe: "Marvel",
            role: .witness
        )
        
        XCTAssertEqual(character.name, "Deadpool")
        XCTAssertEqual(character.universe, "Marvel")
        XCTAssertEqual(character.role, .witness)
        XCTAssertEqual(character.voiceModelId, voiceID)
        XCTAssertTrue(character.systemPrompt.contains(researchResult.personality))
        for pattern in researchResult.speechPatterns {
            XCTAssertTrue(character.systemPrompt.contains(pattern))
        }
        
        let lastResearch = researchMock.lastRequest
        XCTAssertEqual(lastResearch?.name, "Deadpool")
        XCTAssertEqual(lastResearch?.universe, "Marvel")
        XCTAssertEqual(lastResearch?.role, .witness)
        
        let lastVoiceURLs = voiceMock.lastSourceURLs
        XCTAssertEqual(lastVoiceURLs, researchResult.voiceReferences)
    }
    
    func testGenerateResearchFailure() async throws {
        let expectedError = NSError(domain: "ResearchError", code: 404)
        let (generator, _, _) = makeGenerator(researchResult: .failure(expectedError))
        
        do {
            _ = try await generator.generate(name: "Test", universe: "U", role: .witness)
            XCTFail("Expected research error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "ResearchError")
            XCTAssertEqual((error as NSError).code, 404)
        }
    }
    
    func testGenerateVoiceFailure() async throws {
        let researchResult = sampleResearchResult()
        let voiceError = NSError(domain: "VoiceError", code: 500)
        let (generator, _, _) = makeGenerator(
            researchResult: .success(researchResult),
            voiceResult: .failure(voiceError)
        )
        
        do {
            _ = try await generator.generate(name: "Test", universe: "U", role: .witness)
            XCTFail("Expected voice error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "VoiceError")
            XCTAssertEqual((error as NSError).code, 500)
        }
    }
    
    func testGenerateWithEmptyNameThrows() async {
        let (generator, _, _) = makeGenerator(
            researchResult: .success(sampleResearchResult()),
            voiceResult: .success(VoiceModelID("id"))
        )
        
        do {
            _ = try await generator.generate(name: "", universe: "U", role: .witness)
            XCTFail("Expected validation error for empty name")
        } catch {
            // Verify it's a validation error (domain could be app-specific)
            XCTAssertNotNil(error)
        }
    }
    
    func testGenerateWithEmptyUniverseThrows() async {
        let (generator, _, _) = makeGenerator(
            researchResult: .success(sampleResearchResult()),
            voiceResult: .success(VoiceModelID("id"))
        )
        
        do {
            _ = try await generator.generate(name: "Char", universe: "", role: .witness)
            XCTFail("Expected validation error for empty universe")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testSystemPromptConstruction() async throws {
        let researchResult = CanonResearchResult(
            personality: "Grumpy but lovable",
            speechPatterns: ["growl", "one-liner"],
            voiceReferences: [URL(string: "https://example.com/voice2.mp3")!]
        )
        let (generator, _, _) = makeGenerator(
            researchResult: .success(researchResult),
            voiceResult: .success(VoiceModelID("v2"))
        )
        
        let character = try await generator.generate(name: "Wolverine", universe: "Marvel", role: .expertWitness)
        
        XCTAssertTrue(character.systemPrompt.contains("Grumpy but lovable"))
        XCTAssertTrue(character.systemPrompt.contains("growl"))
        XCTAssertTrue(character.systemPrompt.contains("one-liner"))
        // Ensure it doesn't just dump raw data but formats it
        XCTAssertFalse(character.systemPrompt.contains("voiceReferences"))
    }
}