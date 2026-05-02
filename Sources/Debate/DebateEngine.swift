import Foundation

actor DebateEngine {
    private let ollamaClient: any LLMClient
    private var turns: [SpeechTurn] = []

    init(ollamaClient: any LLMClient) {
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
            return try await openingStatements(grievance: grievance, research: research)
        case .witnessTestimony:
            return try await witnessTestimony(grievance: grievance, guests: guests)
        case .crossExamination:
            return try await crossExamination(grievance: grievance, research: research, guests: guests)
        case .closingArguments:
            return try await closingArguments(grievance: grievance, research: research)
        case .verdictAnnouncement:
            return try await verdictSpeech(grievance: grievance, research: research)
        case .deadpoolWrapUp:
            return try await deadpoolWrap(grievance: grievance, research: research)
        case .finisherExecution:
            return try await finisherExecution(grievance: grievance, research: research)
        default:
            return try await genericPhase(phase, grievance: grievance, research: research)
        }
    }

    // MARK: - Prompt Builder

    private func buildPrompt(for speaker: Speaker, phase: DebatePhase,
                             grievance: Grievance, research: CanonResearchResult) -> String {
        let staff = StaffCharacters.forSpeaker(speaker)
        let context = """
        CASE: \(grievance.plaintiff) vs \(grievance.defendant)
        GRIEVANCE: \(grievance.grievanceText)
        PHASE: \(phase.displayName)
        PLAINTIFF EVIDENCE: \(research.plaintiffEvidence.joined(separator: "; "))
        DEFENDANT EVIDENCE: \(research.defendantEvidence.joined(separator: "; "))
        KEY FACTS: \(research.keyFacts.joined(separator: "; "))
        """

        return """
        \(staff.systemPrompt)

        \(context)

        INSTRUCTIONS:
        - You are speaking during the \(phase.displayName) phase.
        - Stay 100% in character. Your voice, your personality, your philosophy.
        - If Jason: aggressive, punchy, trauma as weapon, call bullshit.
        - If Matt: measured, legal, structured, intent matters.
        - If Jerry: warm but stern, cut off rambling, call by first names.
        - If Deadpool: theatrical, fourth-wall aware, mock everything equally, NPH precision.
        - Reference canon directly. Quote sources when possible.
        - Respond with 2-4 sentences maximum. Keep it punchy.
        """
    }

    // MARK: - Cinematic Frame

    private func computeCinematicFrame(speaker: Speaker, phase: DebatePhase) -> CinematicFrame {
        let angle: CameraAngle = switch phase {
        case .openingStatement: .wideShot
        case .witnessTestimony: .closeUp
        case .crossExamination: .overShoulder
        case .closingArguments: .mediumShot
        case .verdictAnnouncement: .lowAngle
        case .finisherExecution: .dutchAngle
        case .deadpoolWrapUp: .pov
        default: .mediumShot
        }

        let palette: [String] = switch speaker {
        case .jasonTodd: ["#DC143C", "#8B0000", "#FF4500"]
        case .mattMurdock: ["#DC143C", "#B22222", "#FF6347"]
        case .judgeJerry: ["#FFD700", "#FFA500", "#FF8C00"]
        case .deadpool: ["#FF1493", "#FF69B4", "#C71585"]
        case .guest: ["#00CED1", "#20B2AA", "#48D1CC"]
        }

        return CinematicFrame(
            cameraAngle: angle,
            intensity: phase == .finisherExecution ? 1.0 : 0.6,
            colorPalette: palette,
            benDayDots: [.crossExamination, .objections, .evidencePresentation].contains(phase),
            speedLines: [.finisherExecution, .deadpoolWrapUp, .crossExamination].contains(phase),
            glitch: speaker == .deadpool,
            frameRateShift: phase == .finisherExecution ? .stutter : .normal,
            sting: phase == .verdictAnnouncement ? "verdictDrumroll" : (phase == .finisherExecution ? "finisherImpact" : "")
        )
    }

    // MARK: - Phase Implementations

    private func openingStatements(grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let jasonPrompt = buildPrompt(for: .jasonTodd, phase: .openingStatement, grievance: grievance, research: research)
        let jasonResult = try await ollamaClient.dispatch(systemPrompt: jasonPrompt, debateContext: "", turnHistory: turns)
        let jasonFrame = computeCinematicFrame(speaker: .jasonTodd, phase: .openingStatement)

        let mattPrompt = buildPrompt(for: .mattMurdock, phase: .openingStatement, grievance: grievance, research: research)
        let mattResult = try await ollamaClient.dispatch(systemPrompt: mattPrompt, debateContext: "", turnHistory: turns)
        let mattFrame = computeCinematicFrame(speaker: .mattMurdock, phase: .openingStatement)

        return [
            SpeechTurn(speaker: .jasonTodd, text: jasonResult, phase: DebatePhase.openingStatement.rawValue, cinematicFrame: jasonFrame),
            SpeechTurn(speaker: .mattMurdock, text: mattResult, phase: DebatePhase.openingStatement.rawValue, cinematicFrame: mattFrame),
        ]
    }

    private func witnessTestimony(grievance: Grievance, guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        var result: [SpeechTurn] = []
        for guest in guests {
            let context = """
            CASE: \(grievance.plaintiff) vs \(grievance.defendant)
            GRIEVANCE: \(grievance.grievanceText)
            PHASE: Witness Testimony
            WITNESS: \(guest.name) from \(guest.universe), called as \(guest.role)
            """
            let prompt = """
            \(guest.personalityPrompt)

            \(context)

            INSTRUCTIONS:
            - You are speaking during the Witness Testimony phase.
            - Stay 100% in character. Your voice, your personality, your philosophy.
            - Reference canon directly. Quote sources when possible.
            - Respond with 2-4 sentences maximum. Keep it punchy.
            """
            let text = try await ollamaClient.dispatch(systemPrompt: prompt, debateContext: "", turnHistory: turns)
            let frame = computeCinematicFrame(speaker: guest.speaker, phase: .witnessTestimony)
            result.append(SpeechTurn(speaker: guest.speaker, text: text, phase: "witness_testimony", cinematicFrame: frame))
        }
        return result
    }

    private func crossExamination(grievance: Grievance, research: CanonResearchResult, guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        var result: [SpeechTurn] = []
        for guest in guests {
            let attacker: Speaker = guest.role == "plaintiff_witness" ? .mattMurdock : .jasonTodd
            let prompt = buildPrompt(for: attacker, phase: .crossExamination, grievance: grievance, research: research)
            let text = try await ollamaClient.dispatch(systemPrompt: prompt, debateContext: "", turnHistory: turns)
            let frame = computeCinematicFrame(speaker: attacker, phase: .crossExamination)
            result.append(SpeechTurn(speaker: attacker, text: text, phase: "cross_examination", cinematicFrame: frame))
        }
        return result
    }

    private func closingArguments(grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let jasonPrompt = buildPrompt(for: .jasonTodd, phase: .closingArguments, grievance: grievance, research: research)
        let jasonResult = try await ollamaClient.dispatch(systemPrompt: jasonPrompt, debateContext: "", turnHistory: turns)
        let jasonFrame = computeCinematicFrame(speaker: .jasonTodd, phase: .closingArguments)

        let mattPrompt = buildPrompt(for: .mattMurdock, phase: .closingArguments, grievance: grievance, research: research)
        let mattResult = try await ollamaClient.dispatch(systemPrompt: mattPrompt, debateContext: "", turnHistory: turns)
        let mattFrame = computeCinematicFrame(speaker: .mattMurdock, phase: .closingArguments)

        return [
            SpeechTurn(speaker: .jasonTodd, text: jasonResult, phase: "closing_arguments", cinematicFrame: jasonFrame),
            SpeechTurn(speaker: .mattMurdock, text: mattResult, phase: "closing_arguments", cinematicFrame: mattFrame),
        ]
    }

    private func verdictSpeech(grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let prompt = buildPrompt(for: .judgeJerry, phase: .verdictAnnouncement, grievance: grievance, research: research) + """

        INSTRUCTIONS:
        - Deliver the verdict as Judge Jerry Springer. Warm but authoritative.
        - Reference the evidence and key facts in your ruling.
        - End with a memorable piece of Jerry Springer wisdom.
        - 2-4 sentences maximum.
        """
        let result = try await ollamaClient.dispatch(systemPrompt: prompt, debateContext: "", turnHistory: turns)
        let frame = computeCinematicFrame(speaker: .judgeJerry, phase: .verdictAnnouncement)
        return [SpeechTurn(speaker: .judgeJerry, text: result, phase: "verdict_announcement", cinematicFrame: frame)]
    }

    private func deadpoolWrap(grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let prompt = buildPrompt(for: .deadpool, phase: .deadpoolWrapUp, grievance: grievance, research: research)
        let result = try await ollamaClient.dispatch(systemPrompt: prompt, debateContext: "", turnHistory: turns)
        let frame = computeCinematicFrame(speaker: .deadpool, phase: .deadpoolWrapUp)
        return [SpeechTurn(speaker: .deadpool, text: result, phase: "deadpool_wrap", cinematicFrame: frame)]
    }

    private func finisherExecution(grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let prompt = buildPrompt(for: .deadpool, phase: .finisherExecution, grievance: grievance, research: research) + """

        INSTRUCTIONS:
        - You are Deadpool narrating the finisher execution with NPH theatrical precision.
        - Describe the verdict being carried out in dramatic, fourth-wall-breaking style.
        - Mock the proceedings, the app, the AI, and the user equally.
        - 2-4 sentences maximum.
        """
        let result = try await ollamaClient.dispatch(systemPrompt: prompt, debateContext: "", turnHistory: turns)
        let frame = computeCinematicFrame(speaker: .deadpool, phase: .finisherExecution)
        return [SpeechTurn(speaker: .deadpool, text: result, phase: "finisher_execution", cinematicFrame: frame)]
    }

    private func genericPhase(_ phase: DebatePhase, grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let prompt = buildPrompt(for: .judgeJerry, phase: phase, grievance: grievance, research: research)
        let result = try await ollamaClient.dispatch(systemPrompt: prompt, debateContext: "", turnHistory: turns)
        let frame = computeCinematicFrame(speaker: .judgeJerry, phase: phase)
        return [SpeechTurn(speaker: .judgeJerry, text: result, phase: phase.rawValue, cinematicFrame: frame)]
    }

    // MARK: - Verdict

    private func deliberateVerdict(grievance: Grievance, research: CanonResearchResult) async throws -> Verdict {
        let staff = StaffCharacters.judgeJerry
        let context = """
        CASE: \(grievance.plaintiff) vs \(grievance.defendant)
        GRIEVANCE: \(grievance.grievanceText)
        PLAINTIFF EVIDENCE: \(research.plaintiffEvidence.joined(separator: "; "))
        DEFENDANT EVIDENCE: \(research.defendantEvidence.joined(separator: "; "))
        KEY FACTS: \(research.keyFacts.joined(separator: "; "))
        """
        let prompt = """
        \(staff.systemPrompt)

        \(context)

        INSTRUCTIONS:
        - Deliver the verdict as Judge Jerry Springer.
        - Ground your ruling in canon research, narrative ethics, and comedic value.
        - Output as JSON: { "ruling": "plaintiff_wins|defendant_wins|hug_it_out", "reasoning": "...", "judgeJerryWisdom": "...", "finisher": "crowbar_beatdown|lazarus_pit|deadpool_shooting|character_morph|gavel_of_doom|null", "punishment_or_reward": "..." }
        """
        let result = try await ollamaClient.dispatch(systemPrompt: prompt, debateContext: "", turnHistory: turns)
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
        let finisher = json.finisher.flatMap { mapFinisher(rawValue: $0) }
        return Verdict(ruling: ruling, reasoning: json.reasoning,
                       punishmentOrReward: json.punishment_or_reward,
                       judgeJerryWisdom: json.judgeJerryWisdom, finisher: finisher)
    }

    private func mapFinisher(rawValue: String) -> FinisherType? {
        switch rawValue {
        case "crowbar_beatdown": return .crowbarBeatdown
        case "lazarus_pit": return .lazarusPitDunking
        case "deadpool_shooting": return .deadpoolShooting
        case "character_morph": return .characterMorph
        case "gavel_of_doom": return .gavelOfDoom
        default: return nil
        }
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
