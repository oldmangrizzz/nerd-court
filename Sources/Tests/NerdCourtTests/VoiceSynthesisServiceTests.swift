import XCTest
@testable import NerdCourt
import AVFoundation

// MARK: - Mock Voice Synthesis Client

protocol VoiceSynthesisClientProtocol: Sendable {
    func synthesize(text: String, voiceModelID: String) async throws -> Data
    func generateVoiceModel(from samples: [URL], name: String) async throws -> String
}

final class MockVoiceSynthesisClient: VoiceSynthesisClientProtocol, @unchecked Sendable {
    var synthesizeResult: Result<Data, Error> = .success(Data())
    var generateVoiceModelResult: Result<String, Error> = .success("mock-model-id")
    
    private(set) var synthesizeCalls: [(text: String, voiceModelID: String)] = []
    private(set) var generateVoiceModelCalls: [(samples: [URL], name: String)] = []
    
    func synthesize(text: String, voiceModelID: String) async throws -> Data {
        synthesizeCalls.append((text, voiceModelID))
        switch synthesizeResult {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
    
    func generateVoiceModel(from samples: [URL], name: String) async throws -> String {
        generateVoiceModelCalls.append((samples, name))
        switch generateVoiceModelResult {
        case .success(let id):
            return id
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - VoiceSynthesisService Tests

final class VoiceSynthesisServiceTests: XCTestCase {
    
    var mockClient: MockVoiceSynthesisClient!
    var service: VoiceSynthesisService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockVoiceSynthesisClient()
        service = VoiceSynthesisService(client: mockClient)
    }
    
    override func tearDown() async throws {
        mockClient = nil
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - Synthesize Speech Tests
    
    func testSynthesizeSpeechSuccess() async throws {
        // Given
        let expectedData = Data("audio data".utf8)
        mockClient.synthesizeResult = .success(expectedData)
        let text = "Hello, world!"
        let voiceModelID = "jason-todd-v1"
        
        // When
        let result = try await service.synthesizeSpeech(text: text, voiceModelID: voiceModelID)
        
        // Then
        XCTAssertEqual(result, expectedData)
        XCTAssertEqual(mockClient.synthesizeCalls.count, 1)
        XCTAssertEqual(mockClient.synthesizeCalls.first?.text, text)
        XCTAssertEqual(mockClient.synthesizeCalls.first?.voiceModelID, voiceModelID)
    }
    
    func testSynthesizeSpeechEmptyText() async throws {
        // Given
        let text = ""
        let voiceModelID = "matt-murdock-v1"
        
        // When/Then
        do {
            _ = try await service.synthesizeSpeech(text: text, voiceModelID: voiceModelID)
            XCTFail("Expected error for empty text")
        } catch let error as VoiceSynthesisError {
            XCTAssertEqual(error, .emptyText)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSynthesizeSpeechClientError() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 500)
        mockClient.synthesizeResult = .failure(expectedError)
        let text = "Valid text"
        let voiceModelID = "deadpool-v1"
        
        // When/Then
        do {
            _ = try await service.synthesizeSpeech(text: text, voiceModelID: voiceModelID)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
    
    func testSynthesizeSpeechLongText() async throws {
        // Given
        let longText = String(repeating: "A", count: 5000)
        let expectedData = Data("long audio".utf8)
        mockClient.synthesizeResult = .success(expectedData)
        let voiceModelID = "judge-jerry-v1"
        
        // When
        let result = try await service.synthesizeSpeech(text: longText, voiceModelID: voiceModelID)
        
        // Then
        XCTAssertEqual(result, expectedData)
        XCTAssertEqual(mockClient.synthesizeCalls.count, 1)
    }
    
    // MARK: - Generate Voice Model Tests
    
    func testGenerateVoiceModelSuccess() async throws {
        // Given
        let sampleURLs = [URL(fileURLWithPath: "/tmp/sample1.wav"), URL(fileURLWithPath: "/tmp/sample2.wav")]
        let name = "CustomGuest"
        let expectedModelID = "custom-guest-v1"
        mockClient.generateVoiceModelResult = .success(expectedModelID)
        
        // When
        let modelID = try await service.generateVoiceModel(from: sampleURLs, name: name)
        
        // Then
        XCTAssertEqual(modelID, expectedModelID)
        XCTAssertEqual(mockClient.generateVoiceModelCalls.count, 1)
        XCTAssertEqual(mockClient.generateVoiceModelCalls.first?.samples, sampleURLs)
        XCTAssertEqual(mockClient.generateVoiceModelCalls.first?.name, name)
    }
    
    func testGenerateVoiceModelEmptySamples() async throws {
        // Given
        let sampleURLs: [URL] = []
        let name = "NoSamples"
        
        // When/Then
        do {
            _ = try await service.generateVoiceModel(from: sampleURLs, name: name)
            XCTFail("Expected error for empty samples")
        } catch let error as VoiceSynthesisError {
            XCTAssertEqual(error, .emptySamples)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testGenerateVoiceModelClientError() async throws {
        // Given
        let sampleURLs = [URL(fileURLWithPath: "/tmp/sample.wav")]
        let name = "ErrorGuest"
        let expectedError = NSError(domain: "test", code: 400)
        mockClient.generateVoiceModelResult = .failure(expectedError)
        
        // When/Then
        do {
            _ = try await service.generateVoiceModel(from: sampleURLs, name: name)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
    
    // MARK: - Edge Cases
    
    func testSynthesizeSpeechWithSpecialCharacters() async throws {
        // Given
        let text = "Hello, <world> & \"friends\"!"
        let expectedData = Data("special chars".utf8)
        mockClient.synthesizeResult = .success(expectedData)
        let voiceModelID = "guest-123"
        
        // When
        let result = try await service.synthesizeSpeech(text: text, voiceModelID: voiceModelID)
        
        // Then
        XCTAssertEqual(result, expectedData)
    }
    
    func testGenerateVoiceModelWithDuplicateSamples() async throws {
        // Given
        let sampleURLs = [URL(fileURLWithPath: "/tmp/sample.wav"), URL(fileURLWithPath: "/tmp/sample.wav")]
        let name = "Duplicate"
        let expectedModelID = "duplicate-model"
        mockClient.generateVoiceModelResult = .success(expectedModelID)
        
        // When
        let modelID = try await service.generateVoiceModel(from: sampleURLs, name: name)
        
        // Then
        XCTAssertEqual(modelID, expectedModelID)
        // Service should handle duplicates gracefully (no crash)
    }
}

// MARK: - VoiceSynthesisError (if not defined elsewhere)

enum VoiceSynthesisError: Error, Equatable {
    case emptyText
    case emptySamples
    case invalidVoiceModelID
}