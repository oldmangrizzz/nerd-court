import Foundation

actor DebateEngine {
    private let ollamaClient: OllamaMaxClient
    private var turns: [SpeechTurn] = []

    init(ollamaClient: OllamaMaxClient) {
        self.ollamaClient = ollamaClient
    }

    func runDebate(grievance: Grievance, research: CanonResearchResult,
                   guests: [GuestCharacter]) async throws -> Episode {
        turns.removeAll()
        var episode = Episode(id: UUID().uuidString, grievanceId: grievance.id)

        for phase in debatePhaseSequence {
            let phaseTurns = try await executePhase(phase, grievance: grievance,
                                                     research: research, guests: guests)
            turns.append(contentsOf: phaseTurns)
        }

        let verdict = try await deliberateVerdict(grievance: grievance, research: research)
        episode.transcript = turns
        episode.verdict = verdict
        episode.comicBeats = turns.filter { $0.speaker == .deadpool }.map(\.text)
        episode.durationSeconds = turns.reduce(0) { $0 + estimatedDuration(text: $1.text) }

        return episode
    }

    private var debatePhaseSequence: [DebatePhase] {
        [.openingStatement, .witnessTestimony, .crossExamination,
         .evidencePresentation, .objections, .closingArguments,
         .verdictAnnouncement, .finisherExecution, .postTrialCommentary,
         .deadpoolWrapUp]
    }

    private func executePhase(_ phase: DebatePhase, grievance: Grievance,
                               research: CanonResearchResult,
                               guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        switch phase {
        case .openingStatement:
            return try await openingStatements(grievance: grievance)
        case .witnessTestimony:
            return try await witnessTestimony(grievance: grievance, guests: guests)
        case .crossExamination:
            return try await crossExamination(grievance: grievance, guests: guests)
        case .closingArguments:
            return try await closingArguments(grievance: grievance, research: research)
        case .verdictAnnouncement:
            return try await verdictSpeech()
        case .deadpoolWrapUp:
            return try await deadpoolWrap(grievance: grievance)
        default:
            return try await genericPhase(phase, grievance: grievance)
        }
    }

    // MARK: - Phase Implementations

    private func openingStatements(grievance: Grievance) async throws -> [SpeechTurn] {
        let jasonPrompt = """
        JASON TODD — Opening statement as plaintiff's lawyer.
        Grievance: \(grievance.plaintiff) vs \(grievance.defendant)
        Claim: \(grievance.grievanceText)
        Deliver a short, punchy opening argument. Be aggressive. Quote your trauma if it lands.
        """
        let jasonResult = try await ollamaClient.dispatch(prompt: jasonPrompt, tier: "T1")

        let mattPrompt = """
        MATT MURDOCK — Opening statement as defense lawyer.
        Grievance: \(grievance.plaintiff) vs \(grievance.defendant)
        Claim: \(grievance.grievanceText)
        Deliver a structured, principled opening. Defend \(grievance.defendant)'s actions. Be measured.
        """
        let mattResult = try await ollamaClient.dispatch(prompt: mattPrompt, tier: "T1")

        return [
            SpeechTurn(speaker: .jasonTodd, text: jasonResult, phase: "opening_statement"),
            SpeechTurn(speaker: .mattMurdock, text: mattResult, phase: "opening_statement"),
        ]
    }

    private func witnessTestimony(grievance: Grievance, guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        var turns: [SpeechTurn] = []
        for guest in guests {
            let prompt = """
            WITNESS TESTIMONY — \(guest.name) from \(guest.universe), called as \(guest.role).
            Case: \(grievance.plaintiff) vs \(grievance.defendant)
            Grievance: \(grievance.grievanceText)
            Personality: \(guest.personalityPrompt)
            Speak in your voice. Deliver testimony relevant to this canon dispute.
            """
            let result = try await ollamaClient.dispatch(prompt: prompt, tier: "T1")
            turns.append(SpeechTurn(speaker: guest.speaker, text: result, phase: "witness_testimony"))
        }
        return turns
    }

    private func crossExamination(grievance: Grievance, guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        var turns: [SpeechTurn] = []
        for guest in guests {
            let attacker = guest.role == "plaintiff_witness" ? Speaker.mattMurdock : Speaker.jasonTodd
            let prompt = """
            CROSS-EXAMINATION of \(guest.name) by \(attacker.displayName).
            Target's testimony was about: \(grievance.grievanceText)
            Challenge \(guest.name)'s credibility or interpretation. Be sharp in character.
            """
            let result = try await ollamaClient.dispatch(prompt: prompt, tier: "T1")
            turns.append(SpeechTurn(speaker: attacker, text: result, phase: "cross_examination"))
        }
        return turns
    }

    private func closingArguments(grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let jasonPrompt = """
        JASON TODD closing argument. Sum up the plaintiff's case.
        Key evidence: \(research.plaintiffEvidence.joined(separator: "; "))
        Make them FEEL the canon violation. Last chance to win.
        """
        let jasonResult = try await ollamaClient.dispatch(prompt: jasonPrompt, tier: "T1")

        let mattPrompt = """
        MATT MURDOCK closing argument. Sum up the defense case.
        Key evidence: \(research.defendantEvidence.joined(separator: "; "))
        Appeal to narrative ethics. Intent and context matter.
        """
        let mattResult = try await ollamaClient.dispatch(prompt: mattPrompt, tier: "T1")

        return [
            SpeechTurn(speaker: .jasonTodd, text: jasonResult, phase: "closing_arguments"),
            SpeechTurn(speaker: .mattMurdock, text: mattResult, phase: "closing_arguments"),
        ]
    }

    private func verdictSpeech() async throws -> [SpeechTurn] {
        let prompt = "DEADPOOL announces the verdict with NPH theatrical flourish. Build dramatic tension."
        let result = try await ollamaClient.dispatch(prompt: prompt, tier: "T2")
        return [SpeechTurn(speaker: .deadpool, text: result, phase: "verdict_announcement")]
    }

    private func deadpoolWrap(grievance: Grievance) async throws -> [SpeechTurn] {
        let prompt = """
        DEADPOOL wraps Nerd Court: \(grievance.plaintiff) vs \(grievance.defendant).
        NPH theatrical closing. Mock the proceedings, app, AI, and user equally.
        End with "Take care of yourselves and each other" energy.
        """
        let result = try await ollamaClient.dispatch(prompt: prompt, tier: "T2")
        return [SpeechTurn(speaker: .deadpool, text: result, phase: "deadpool_wrap")]
    }

    private func genericPhase(_ phase: DebatePhase, grievance: Grievance) async throws -> [SpeechTurn] {
        let result = try await ollamaClient.dispatch(
            prompt: "Nerd Court — phase \(phase.rawValue) for \(grievance.plaintiff) vs \(grievance.defendant).",
            tier: "T2"
        )
        return [SpeechTurn(speaker: .jasonTodd, text: result, phase: phase.rawValue)]
    }

    // MARK: - Verdict

    private func deliberateVerdict(grievance: Grievance, research: CanonResearchResult) async throws -> Verdict {
        let prompt = """
        JUDGE JERRY delivers the verdict.
        Case: \(grievance.plaintiff) vs \(grievance.defendant)
        Grievance: \(grievance.grievanceText)
        Plaintiff evidence: \(research.plaintiffEvidence.joined(separator: "; "))
        Defendant evidence: \(research.defendantEvidence.joined(separator: "; "))
        Key facts: \(research.keyFacts.joined(separator: "; "))

        Rule based on canon accuracy, narrative ethics, and comedic value.
        Output as JSON: { "ruling": "plaintiff_wins|defendant_wins|hug_it_out", "reasoning": "...", "judgeJerryWisdom": "...", "finisher": "crowbar_beatdown|lazarus_pit|deadpool_shooting|character_morph|gavel_of_doom|null", "punishment_or_reward": "..." }
        """
        let result = try await ollamaClient.dispatch(prompt: prompt, tier: "T1")
        return parseVerdictJSON(result, grievance: grievance, research: research)
    }

    private func parseVerdictJSON(_ raw: String, grievance: Grievance, research: CanonResearchResult) -> Verdict {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONDecoder().decode(VerdictJSON.self, from: data) else {
            return Verdict(ruling: .hugItOut,
                           reasoning: "The court couldn't parse a ruling, so everyone hugs.",
                           punishmentOrReward: "Mutual respect mandated.",
                           judgeJerryWisdom: "When canon is unclear, kindness is clear.",
                           finisher: nil)
        }
        let ruling: Verdict.Ruling = switch json.ruling {
        case "plaintiff_wins": .plaintiffWins
        case "defendant_wins": .defendantWins
        default: .hugItOut
        }
        let finisher = json.finisher.flatMap(FinisherType.init(rawValue:))
        return Verdict(ruling: ruling, reasoning: json.reasoning,
                       punishmentOrReward: json.punishment_or_reward,
                       judgeJerryWisdom: json.judgeJerryWisdom, finisher: finisher)
    }

    private struct VerdictJSON: Codable {
        let ruling: String
        let reasoning: String
        let judgeJerryWisdom: String
        let finisher: String?
        let punishment_or_reward: String
    }

    private func estimatedDuration(text: String) -> Double {
        let wordCount = Double(text.split(separator: " ").count)
        let avgWPM = 150.0
        return max(2.0, (wordCount / avgWPM) * 60.0)
    }
}

struct CanonResearchResult: Codable {
    let sources: [CanonSource]
    let keyFacts: [String]
    let plaintiffEvidence: [String]
    let defendantEvidence: [String]
}

struct CanonSource: Codable, Identifiable {
    var id: String
    let title: String
    let url: String
    let excerpt: String
}
