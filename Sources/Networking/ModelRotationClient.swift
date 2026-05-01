import Foundation

// MARK: - Request / Response Models

private struct OllamaMaxRequest: Codable {
    let systemPrompt: String
    let debateContext: String
    let turnHistory: [SpeechTurn]
}

private struct OllamaMaxResponse: Codable {
    let response: String
}

// MARK: - Ollama Max Client

final class OllamaMaxClient {
    private let deltaHost: String
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(deltaHost: String, session: URLSession = .shared) {
        self.deltaHost = deltaHost
        self.session = session
    }

    /// Dispatches a debate turn to the Ollama Max rotation harness.
    /// - Parameters:
    ///   - systemPrompt: The system prompt defining the character's persona.
    ///   - debateContext: Current debate context (grievance, phase, etc.).
    ///   - turnHistory: Previous turns for continuity.
    /// - Returns: The generated argument text from the model.
    func dispatch(
        systemPrompt: String,
        debateContext: String,
        turnHistory: [SpeechTurn]
    ) async throws -> String {
        guard let url = URL(string: "http://\(deltaHost)/api/generate") else {
            throw OllamaMaxError.invalidURL
        }

        let requestBody = OllamaMaxRequest(
            systemPrompt: systemPrompt,
            debateContext: debateContext,
            turnHistory: turnHistory
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaMaxError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw OllamaMaxError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded = try decoder.decode(OllamaMaxResponse.self, from: data)
        return decoded.response
    }
}

// MARK: - Error Types

enum OllamaMaxError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Delta host URL."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpError(let code):
            return "HTTP error with status code \(code)."
        }
    }
}