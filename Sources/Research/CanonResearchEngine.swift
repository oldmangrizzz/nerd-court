import Foundation

actor CanonResearchEngine {
    func research(grievance: Grievance) async throws -> CanonResearchResult {
        // Phase 1: canonical mock research. In production this calls the MCP search service.
        let plaintiffSources = [
            CanonSource(id: "1", title: "Fan Wiki — \(grievance.plaintiff) Canon Entry",
                        snippet: "Primary canon reference material for \(grievance.plaintiff).",
                        url: URL(string: "https://example.com/wiki/\(grievance.plaintiff)")!,
                        attribution: "Fan Wiki", relevanceScore: 0.95),
        ]
        let defendantSources = [
            CanonSource(id: "2", title: "Creator Interview Archive — \(grievance.defendant)",
                        snippet: "Original creator statements on intent for \(grievance.defendant).",
                        url: URL(string: "https://example.com/interviews/\(grievance.defendant)")!,
                        attribution: "Creator Archive", relevanceScore: 0.90),
        ]

        return CanonResearchResult(
            query: "\(grievance.plaintiff) vs \(grievance.defendant)",
            sources: plaintiffSources + defendantSources,
            summary: "Canon supports both parties' narrative positions; ruling depends on evidence weight.",
            researchedAt: .now,
            keyFacts: [
                "\(grievance.plaintiff) established canonical presence in their source material.",
                "\(grievance.defendant)'s actions have documented canon implications.",
            ],
            plaintiffEvidence: [
                "Canon supports \(grievance.plaintiff)'s original claim to narrative integrity.",
            ],
            defendantEvidence: [
                "\(grievance.defendant)'s actions can be interpreted as narrative evolution, not theft.",
            ]
        )
    }
}
