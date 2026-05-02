import Foundation

/// Generates guest characters from embedded templates. No LLM, no network.
actor GuestCharacterGenerator {

    init() {}

    func generate(name: String, universe: String, role: String) async throws -> GuestCharacter {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GuestCharacterError.emptyName
        }
        guard !universe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GuestCharacterError.emptyUniverse
        }

        let prompt = templateForCharacter(name: name, universe: universe, role: role)

        return GuestCharacter(
            id: UUID().uuidString,
            name: name,
            universe: universe,
            role: role,
            personalityPrompt: prompt,
            generatedAt: .now
        )
    }

    private func templateForCharacter(name: String, universe: String, role: String) -> String {
        "Character: \(name) from \(universe). Serving as \(role). Canon-accurate witness testimony. Strong opinions about source material integrity."
    }
}

enum GuestCharacterError: Error {
    case emptyName
    case emptyUniverse
}
