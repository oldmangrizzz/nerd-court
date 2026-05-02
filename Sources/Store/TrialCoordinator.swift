import Foundation
import SwiftUI

@MainActor
@Observable final class TrialCoordinator {
    private let ollamaClient: any LLMClient
    private let convexClient: (any ConvexPersisting)?
    private let debateEngine: any DebateEngineProtocol
    private let researchEngine: any CanonResearchServiceProtocol
    private let voiceClient: any VoiceSynthesisServiceProtocol
    private let guestGenerator: GuestCharacterGenerator

    init(ollamaClient: any LLMClient, convexClient: (any ConvexPersisting)?,
         debateEngine: any DebateEngineProtocol, researchEngine: any CanonResearchServiceProtocol,
         voiceClient: any VoiceSynthesisServiceProtocol) {
        self.ollamaClient = ollamaClient
        self.convexClient = convexClient
        self.debateEngine = debateEngine
        self.researchEngine = researchEngine
        self.voiceClient = voiceClient
        self.guestGenerator = GuestCharacterGenerator(ollamaClient: ollamaClient)
    }

    func startTrial(scene: CourtroomScene, grievance: Grievance, appState: AppState) async {
        appState.isTrialRunning = true
        defer { appState.isTrialRunning = false }

        voiceClient.preloadVoices()

        appState.currentDebatePhase = .canonResearch
        let research = try? await researchEngine.research(grievance: grievance)

        var guests: [GuestCharacter] = []
        if let plaintiffId = grievance.guestPlaintiffId, !plaintiffId.isEmpty {
            let parts = plaintiffId.components(separatedBy: "|")
            if parts.count >= 3,
               let guest = try? await guestGenerator.generate(
                    name: parts[0], universe: parts[1], role: parts[2]) {
                guests.append(guest)
            }
        }

        let researchResult = research ?? CanonResearchResult(
            sources: [],
            keyFacts: ["No canon research available."],
            plaintiffEvidence: [],
            defendantEvidence: [],
            researchedAt: .now
        )

        // Build episode incrementally so UI updates live
        var episode = Episode(id: UUID().uuidString, grievanceId: grievance.id)
        episode.transcript = []

        // Phase-by-phase execution with live UI updates
        let phases: [DebatePhase] = [.openingStatement, .witnessTestimony, .crossExamination,
                                      .evidencePresentation, .objections, .closingArguments,
                                      .juryDeliberation, .verdictAnnouncement, .finisherExecution,
                                      .postTrialCommentary, .deadpoolWrapUp]

        for phase in phases {
            appState.currentDebatePhase = phase
            scene.transitionToPhase(phase)

            if let phaseTurns = try? await runPhase(phase, grievance: grievance,
                                                       research: researchResult, guests: guests) {
                episode.transcript.append(contentsOf: phaseTurns)
                appState.activeEpisode = episode
                // Small delay so UI renders each phase
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }

        // Final verdict
        if let verdict = try? await deliberateVerdict(grievance: grievance, research: researchResult) {
            episode.verdict = verdict
            appState.activeEpisode = episode
        }

        saveEpisode(episode)
        appState.currentDebatePhase = .complete
    }

    // MARK: - Phase execution (bypasses DebateEngine to update AppState live)

    private func runPhase(_ phase: DebatePhase, grievance: Grievance,
                          research: CanonResearchResult,
                          guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        switch phase {
        case .openingStatement:
            return try await scriptedOpening(grievance: grievance)
        case .witnessTestimony:
            return try await scriptedWitnesses(grievance: grievance, guests: guests)
        case .crossExamination:
            return try await scriptedCross(grievance: grievance, guests: guests)
        case .closingArguments:
            return try await scriptedClosing(grievance: grievance, research: research)
        case .verdictAnnouncement:
            return try await scriptedVerdictIntro()
        case .deadpoolWrapUp:
            return try await scriptedDeadpoolWrap(grievance: grievance)
        default:
            return [SpeechTurn(speaker: .judgeJerry,
                               text: "Moving to \(phase.displayName)...",
                               phase: phase.rawValue)]
        }
    }

    private func scriptedOpening(grievance: Grievance) async throws -> [SpeechTurn] {
        let jason = try await ollamaClient.dispatch(
            systemPrompt: "You are JASON TODD — aggressive, trauma-driven plaintiff's lawyer.",
            debateContext: "Case: \(grievance.plaintiff) vs \(grievance.defendant). Claim: \(grievance.grievanceText)",
            turnHistory: [])
        let matt = try await ollamaClient.dispatch(
            systemPrompt: "You are MATT MURDOCK — measured, principled defense lawyer.",
            debateContext: "Case: \(grievance.plaintiff) vs \(grievance.defendant). Defend \(grievance.defendant).",
            turnHistory: [])
        return [
            SpeechTurn(speaker: .jasonTodd, text: jason, phase: "opening_statement"),
            SpeechTurn(speaker: .mattMurdock, text: matt, phase: "opening_statement"),
        ]
    }

    private func scriptedWitnesses(grievance: Grievance, guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        var turns: [SpeechTurn] = []
        for guest in guests {
            let text = try await ollamaClient.dispatch(
                systemPrompt: "You are \(guest.name) from \(guest.universe). Personality: \(guest.personalityPrompt)",
                debateContext: "Witness testimony for \(grievance.plaintiff) vs \(grievance.defendant).",
                turnHistory: [])
            turns.append(SpeechTurn(speaker: guest.speaker, text: text, phase: "witness_testimony"))
        }
        return turns.isEmpty ? [SpeechTurn(speaker: .judgeJerry, text: "No witnesses called.", phase: "witness_testimony")] : turns
    }

    private func scriptedCross(grievance: Grievance, guests: [GuestCharacter]) async throws -> [SpeechTurn] {
        var turns: [SpeechTurn] = []
        for guest in guests {
            let attacker: Speaker = guest.role == "plaintiff_witness" ? .mattMurdock : .jasonTodd
            let text = try await ollamaClient.dispatch(
                systemPrompt: "You are \(attacker.displayName) conducting cross-examination.",
                debateContext: "Cross-examining \(guest.name). Case: \(grievance.grievanceText)",
                turnHistory: [])
            turns.append(SpeechTurn(speaker: attacker, text: text, phase: "cross_examination"))
        }
        return turns
    }

    private func scriptedClosing(grievance: Grievance, research: CanonResearchResult) async throws -> [SpeechTurn] {
        let jason = try await ollamaClient.dispatch(
            systemPrompt: "You are JASON TODD — closing argument. Make them FEEL the canon violation.",
            debateContext: "Plaintiff evidence: \(research.plaintiffEvidence.joined(separator: "; "))",
            turnHistory: [])
        let matt = try await ollamaClient.dispatch(
            systemPrompt: "You are MATT MURDOCK — closing argument. Appeal to narrative ethics.",
            debateContext: "Defense evidence: \(research.defendantEvidence.joined(separator: "; "))",
            turnHistory: [])
        return [
            SpeechTurn(speaker: .jasonTodd, text: jason, phase: "closing_arguments"),
            SpeechTurn(speaker: .mattMurdock, text: matt, phase: "closing_arguments"),
        ]
    }

    private func scriptedVerdictIntro() async throws -> [SpeechTurn] {
        let text = try await ollamaClient.dispatch(
            systemPrompt: "You are DEADPOOL (Neil Patrick Harris theatrical flair). Build dramatic tension before announcing verdict.",
            debateContext: "Nerd Court verdict moment.",
            turnHistory: [])
        return [SpeechTurn(speaker: .deadpool, text: text, phase: "verdict_announcement")]
    }

    private func scriptedDeadpoolWrap(grievance: Grievance) async throws -> [SpeechTurn] {
        let text = try await ollamaClient.dispatch(
            systemPrompt: "You are DEADPOOL wrapping Nerd Court. Mock everything. End with warmth.",
            debateContext: "Case: \(grievance.plaintiff) vs \(grievance.defendant)",
            turnHistory: [])
        return [SpeechTurn(speaker: .deadpool, text: text, phase: "deadpool_wrap")]
    }

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
        let result = try await ollamaClient.dispatch(
            systemPrompt: "You are JUDGE JERRY. Deliver a verdict with wisdom and humor.",
            debateContext: prompt,
            turnHistory: [])
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

    // MARK: - Persistence

    private func saveEpisode(_ episode: Episode) {
        let episodeToSave = episode
        let store = EpisodeStore.shared
        let saveTask: Task<Void, Never> = Task { [episodeToSave, store] in
            await store.addEpisode(episodeToSave)
            if let convex = self.convexClient {
                let turns = episodeToSave.transcript.map { turn in
                    ["speaker": turn.speaker.displayName, "text": turn.text, "phase": turn.phase]
                }
                _ = try? await convex.mutation("episodes:insert", args: [
                    "grievanceId": episodeToSave.grievanceId,
                    "transcript": turns,
                    "finisherType": episodeToSave.finisherType?.rawValue ?? NSNull(),
                ])
            }
        }
        _ = saveTask
    }
}
