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

enum DebatePhase: String, Codable, Equatable {
    case intake
    case canonResearch
    case openingStatement
    case witnessTestimony
    case crossExamination
    case evidencePresentation
    case objections
    case closingArguments
    case juryDeliberation
    case verdictAnnouncement
    case finisherExecution
    case postTrialCommentary
    case deadpoolWrapUp
    case complete
}
