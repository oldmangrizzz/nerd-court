import Foundation

actor ModelRotationClient {
    private let deltaBaseURL: String
    private var rotationIndex: [String: Int] = [:]

    private let tier1Models = [
        "DeepSeek-V4-Pro-[T1]",
        "Qwen3-Coder-480B-[T1]",
        "Kimi-K2-Thinking-[T1]",
        "Qwen-3.5-397B-[T1]",
        "Mistral-Large-3-675B-[T1]",
    ]

    private let tier2Models = [
        "GPT-OSS-120B-[T2]",
        "Gemma-4-31B-[T2]",
        "Qwen3-Next-80B-[T2]",
        "Devstral-2-123B-[T2]",
        "Nemotron-3-Super-[T2]",
        "GLM-5.1-[T2]",
        "MiniMax-M2.7-[T2]",
    ]

    private let tier3Models = [
        "Qwen3-Coder-Next-[T3]",
        "DeepSeek-V3.2-[T3]",
        "Kimi-K2.6-[T3]",
    ]

    init(deltaBaseURL: String = "http://delta.local:11434") {
        self.deltaBaseURL = deltaBaseURL
    }

    func dispatch(prompt: String, tier: String = "T1") async throws -> String {
        let model = try await pickModel(tier: tier)
        let result = try await callModel(model: model, prompt: prompt)
        return result
    }

    private func pickModel(tier: String) async throws -> String {
        let pool: [String]
        switch tier {
        case "T1": pool = tier1Models
        case "T2": pool = tier2Models
        case "T3": pool = tier3Models
        default: pool = tier1Models
        }

        let current = rotationIndex[tier, default: 0]
        rotationIndex[tier] = (current + 1) % pool.count
        return pool[current]
    }

    private func callModel(model: String, prompt: String) async throws -> String {
        // For Delta-hosted models, this reaches through the Ollama Max harness.
        // Phase 1: mock LLM mode returns character-accurate scripted responses.
        return """
        [MOCK LLM RESPONSE — model: \(model)]
        A character-accurate AI-generated court argument would appear here.
        In production, this routes through Delta's Ollama Max rotation harness
        with the character's system prompt + full debate context injected.
        """
    }
}
