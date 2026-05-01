import Foundation

public enum DebatePhase: String, Codable, Equatable, Sendable {
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

    public var next: DebatePhase? {
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
