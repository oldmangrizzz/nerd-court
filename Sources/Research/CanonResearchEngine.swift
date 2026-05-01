import Foundation

actor CanonResearchEngine {
    func research(grievance: Grievance) async throws -> CanonResearchResult {
        // Phase 1: canonical mock research. In production this calls the MCP search service.
        let plaintiffSources = [
            CanonSource(id: "1", title: "Fan Wiki — \(grievance.plaintiff) Canon Entry",
                        url: "https://example.com/wiki/\(grievance.plaintiff)",
                        excerpt: "Primary canon reference material for \(grievance.plaintiff)."),
        ]
        let defendantSources = [
            CanonSource(id: "2", title: "Creator Interview Archive — \(grievance.defendant)",
                        url: "https://example.com/interviews/\(grievance.defendant)",
                        excerpt: "Original creator statements on intent for \(grievance.defendant)."),
        ]

        return CanonResearchResult(
            sources: plaintiffSources + defendantSources,
            keyFacts: [
                "\(grievance.plaintiff) established canonical presence in their source material.",
                "\(grievance.defendant)'s actions have documented canon implications.",
            ],
            plaintiffEvidence: [
                "Canon supports \(grievance.plaintiff)'s original claim to narrative integrity.",
            ],
            defendantEvidence: [
                "\(grievance.defendant)'s actions can be interpreted as narrative evolution, not theft.",
            ],
            researchedAt: .now
        )
    }
}
