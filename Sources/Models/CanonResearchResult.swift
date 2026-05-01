import Foundation

/// The result of canon research performed for a trial.
public struct CanonResearchResult: Codable, Equatable, Sendable {
    public let sources: [CanonSource]
    public let keyFacts: [String]
    public let plaintiffEvidence: [String]
    public let defendantEvidence: [String]
    public let researchedAt: Date

    public init(
        sources: [CanonSource],
        keyFacts: [String],
        plaintiffEvidence: [String],
        defendantEvidence: [String],
        researchedAt: Date
    ) {
        self.sources = sources
        self.keyFacts = keyFacts
        self.plaintiffEvidence = plaintiffEvidence
        self.defendantEvidence = defendantEvidence
        self.researchedAt = researchedAt
    }
}
