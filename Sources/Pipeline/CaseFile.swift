import Foundation

/// Structured "case file" produced by the research node and consumed by every
/// downstream node in the trial pipeline.
///
/// The point of this struct is exactly what the operator called out: by
/// pre-computing the canonical facts, the contradictions, the per-side
/// evidence ladders, and per-persona briefs, the LLM never has to invent
/// the case from cold air. It only has to *react* in voice. That makes
/// dialogue more authentic and keeps each LLM call cheap and on-rails.
struct CaseFile: Sendable {
    let grievance: Grievance
    let research: CanonResearchResult
    let guests: [GuestCharacter]
    let personaBriefs: [PersonaBrief]

    init(grievance: Grievance,
                research: CanonResearchResult,
                guests: [GuestCharacter],
                personaBriefs: [PersonaBrief]) {
        self.grievance = grievance
        self.research = research
        self.guests = guests
        self.personaBriefs = personaBriefs
    }

    func brief(for speaker: Speaker) -> PersonaBrief? {
        personaBriefs.first { $0.speaker == speaker }
    }
}

/// One side of the case, distilled for a single persona. The persona LLM call
/// receives this brief and a phase tag — nothing else — and produces voice.
struct PersonaBrief: Sendable {
    let speaker: Speaker
    let role: FixedRole
    let argumentLadder: [String]
    let counterPoints: [String]
    let voiceCues: [String]

    init(speaker: Speaker,
                role: FixedRole,
                argumentLadder: [String],
                counterPoints: [String],
                voiceCues: [String]) {
        self.speaker = speaker
        self.role = role
        self.argumentLadder = argumentLadder
        self.counterPoints = counterPoints
        self.voiceCues = voiceCues
    }
}
