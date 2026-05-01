import Foundation

struct GuestCharacter: Codable, Identifiable, Equatable {
    var id: String
    let name: String
    let universe: String
    let role: String
    var voiceId: String?
    var personalityPrompt: String
    var generatedAt: Date
    var usedInEpisodeIds: [String] = []

    var speaker: Speaker {
        .guest(id: id, name: name)
    }
}

enum GuestRole: String, Codable, Equatable {
    case plaintiffWitness = "plaintiff_witness"
    case defendantWitness = "defendant_witness"
}
