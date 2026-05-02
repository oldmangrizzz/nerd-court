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

    public var displayName: String {
        switch self {
        case .intake: return "Intake"
        case .canonResearch: return "Canon Research"
        case .openingStatement: return "Opening Statement"
        case .witnessTestimony: return "Witness Testimony"
        case .crossExamination: return "Cross Examination"
        case .evidencePresentation: return "Evidence"
        case .objections: return "Objections"
        case .closingArguments: return "Closing Arguments"
        case .juryDeliberation: return "Jury Deliberation"
        case .verdictAnnouncement: return "Verdict"
        case .finisherExecution: return "Finisher"
        case .postTrialCommentary: return "Commentary"
        case .deadpoolWrapUp: return "Deadpool Wrap"
        case .complete: return "Complete"
        }
    }
}
