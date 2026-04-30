import Foundation

struct Verdict: Codable, Equatable {
    enum Ruling: String, Codable, Equatable {
        case plaintiffWins
        case defendantWins
        case hugItOut
    }

    let ruling: Ruling
    let reasoning: String
    let punishmentOrReward: String
    let judgeJerryWisdom: String
    let finisher: FinisherType?
}
