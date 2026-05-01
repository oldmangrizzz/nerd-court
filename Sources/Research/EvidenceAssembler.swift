import Foundation

// MARK: - Evidence Models

/// A single piece of evidence supporting one side of a grievance.
struct EvidencePoint: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let source: String
    let confidence: Double // 0...1
}

/// Assembled evidence for both plaintiff and defendant.
struct Evidence: Codable, Identifiable {
    let id: String
    let grievanceId: String
    let plaintiffEvidence: [EvidencePoint]
    let defendantEvidence: [EvidencePoint]
    let assembledAt: Date
}

// MARK: - Evidence Assembler

/// Gathers and organizes canon research into structured evidence for trial.
actor EvidenceAssembler {
    private let researchService: CanonResearchService
    
    init(researchService: CanonResearchService) {
        self.researchService = researchService
    }
    
    /// Assembles evidence for a given grievance by performing canon research
    /// and splitting the results into plaintiff and defendant points.
    func assemble(for grievance: Grievance) async throws -> Evidence {
        // 1. Perform canon research
        let researchResult = try await researchService.research(grievance: grievance)
        
        // 2. Convert raw research into evidence points
        let plaintiffPoints = researchResult.plaintiffArguments.map { raw in
            EvidencePoint(
                id: UUID().uuidString,
                text: raw,
                source: "Canon Research",
                confidence: 0.9
            )
        }
        
        let defendantPoints = researchResult.defendantArguments.map { raw in
            EvidencePoint(
                id: UUID().uuidString,
                text: raw,
                source: "Canon Research",
                confidence: 0.9
            )
        }
        
        // 3. Build and return the evidence package
        return Evidence(
            id: UUID().uuidString,
            grievanceId: grievance.id,
            plaintiffEvidence: plaintiffPoints,
            defendantEvidence: defendantPoints,
            assembledAt: Date()
        )
    }
}

// MARK: - Canon Research Result (assumed from sibling file)

/// Result of canon research containing raw arguments for both sides.
struct CanonResearchResult: Codable {
    let plaintiffArguments: [String]
    let defendantArguments: [String]
    let sources: [String]
}

// MARK: - Canon Research Service Protocol (assumed from sibling file)

/// Service responsible for performing canon research.
protocol CanonResearchService: Actor {
    func research(grievance: Grievance) async throws -> CanonResearchResult
}