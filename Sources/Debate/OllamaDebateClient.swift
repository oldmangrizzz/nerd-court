import Foundation

// MARK: - Request / Response Models

struct OllamaMaxDispatchRequest: Codable {
    let systemPrompt: String
    let debateContext: String
    let turnHistory: [TurnHistoryItem]
    
    struct TurnHistoryItem: Codable {
        let speaker: String
        let text: String
    }
}

struct OllamaMaxDispatchResponse: Codable {
    let text: String
}

// MARK: - Errors

enum OllamaMaxError: Error, LocalizedError {
    case invalidHost
    case invalidURL
    case networkError(Error)
    case serverError(statusCode: Int, body: String?)
    case decodingError(Error)
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidHost:
            return "Delta host is not configured."
        case .invalidURL:
            return "Failed to construct request URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let body):
            return "Server error \(code): \(body ?? "No body")"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .emptyResponse:
            return "Response text was empty."
        }
    }
}

// MARK: - DeltaDispatchClient

/// Real HTTP client for the Delta Ollama Max dispatch harness.
/// Use this in production; swap with ModelRotationClient for mock/rotation mode.
final class DeltaDispatchClient: Sendable {
    private let deltaHost: String
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    /// Creates a client for the Delta rotation harness.
    /// - Parameters:
    ///   - deltaHost: The hostname or IP address of the Delta server (e.g. "delta.local" or "192.168.1.100").
    ///   - session: URLSession to use; defaults to a session with a 30-second timeout.
    init(deltaHost: String, session: URLSession = .shared) {
        precondition(!deltaHost.isEmpty, "Delta host must not be empty.")
        self.deltaHost = deltaHost
        self.session = session
    }
    
    /// Dispatches a debate turn to the Ollama Max rotation harness and returns the generated text.
    /// - Parameters:
    ///   - systemPrompt: The system prompt defining the character's persona.
    ///   - debateContext: The current debate context (case summary, phase, etc.).
    ///   - turnHistory: Previous turns in the debate.
    /// - Returns: The character's argument text.
    func dispatch(
        systemPrompt: String,
        debateContext: String,
        turnHistory: [SpeechTurn]
    ) async throws -> String {
        guard !deltaHost.isEmpty else {
            throw OllamaMaxError.invalidHost
        }
        
        // Build URL
        guard let url = URL(string: "http://\(deltaHost)/api/dispatch") else {
            throw OllamaMaxError.invalidURL
        }
        
        // Convert SpeechTurn to TurnHistoryItem (only speaker + text needed)
        let historyItems = turnHistory.map { turn in
            OllamaMaxDispatchRequest.TurnHistoryItem(
                speaker: speakerIdentifier(for: turn.speaker),
                text: turn.text
            )
        }
        
        let requestBody = OllamaMaxDispatchRequest(
            systemPrompt: systemPrompt,
            debateContext: debateContext,
            turnHistory: historyItems
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(requestBody)
        urlRequest.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaMaxError.networkError(URLError(.badServerResponse))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw OllamaMaxError.serverError(statusCode: httpResponse.statusCode, body: body)
        }
        
        let dispatchResponse: OllamaMaxDispatchResponse
        do {
            dispatchResponse = try decoder.decode(OllamaMaxDispatchResponse.self, from: data)
        } catch {
            throw OllamaMaxError.decodingError(error)
        }
        
        let text = dispatchResponse.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw OllamaMaxError.emptyResponse
        }
        
        return text
    }
    
    // MARK: - Helpers
    
    /// Converts a Speaker enum to a string identifier for the API.
    private func speakerIdentifier(for speaker: Speaker) -> String {
        switch speaker {
        case .jasonTodd: return "jason_todd"
        case .mattMurdock: return "matt_murdock"
        case .judgeJerry: return "judge_jerry"
        case .deadpool: return "deadpool"
        case .guest(let id, let name): return "guest_\(id)_\(name.replacingOccurrences(of: " ", with: "_"))"
        }
    }
}