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
    
    var next: DebatePhase? {
        switch self {
        case .intake: return .canonResearch
        case .canonResearch: return .openingStatement
        case .openingStatement: return .witnessTestimony
        case .witnessTestimony: return .crossExamination
        case .crossExamination: return .evidencePresentation
        case .evidencePresentation: return .objections
        case .objections: return .closingArguments
        case .closingArguments: return .juryDeliberation
        case .juryDeliberation: return .verdictAnnouncement
        case .verdictAnnouncement: return .finisherExecution
        case .finisherExecution: return .postTrialCommentary
        case .postTrialCommentary: return .deadpoolWrapUp
        case .deadpoolWrapUp: return .complete
        case .complete: return nil
        }
    }
}
