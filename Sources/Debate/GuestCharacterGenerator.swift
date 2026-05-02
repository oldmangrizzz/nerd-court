import Foundation

/// Generates guest characters by calling the Delta Ollama Max dispatch harness.
actor GuestCharacterGenerator {
    private let ollamaClient: any LLMClient

    init(ollamaClient: any LLMClient) {
        self.ollamaClient = ollamaClient
    }

    func generate(name: String, universe: String, role: String) async throws -> GuestCharacter {
        let prompt = """
        CHARACTER GENERATION: Create a character-accurate personality prompt for \(name) from \(universe).
        They will serve as \(role) in a Nerd Court canon trial.

        Research and provide:
        1. Core backstory (canonically accurate)
        2. Personality traits
        3. Speech patterns and voice description
        4. How they would behave under courtroom examination
        5. Their narrative philosophy (what they think about canon/legacy)

        Output as a cohesive system prompt that would make an LLM speak AS this character.
        Keep it under 200 words. Be canon-accurate.
        """
        let personalityPrompt = try await ollamaClient.dispatch(
            systemPrompt: "You are a character personality generator.",
            debateContext: prompt,
            turnHistory: []
        )

        return GuestCharacter(
            id: UUID().uuidString,
            name: name,
            universe: universe,
            role: role,
            personalityPrompt: personalityPrompt,
            generatedAt: .now
        )
    }
}
