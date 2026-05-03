import Foundation

// MARK: - ResearchNode

/// Builds the structured `CaseFile` from a raw `Grievance`.
///
/// Decoupling research from the debate engine is the point: when the LLM
/// later has to "stay in voice", every fact it could ever need is already
/// in the brief. The model isn't doing knowledge work; it's doing acting.
struct ResearchNode: PipelineNode {
    let name = "research"
    var retryPolicy: RetryPolicy { .standard }

    private let guestGenerator: GuestCharacterGenerator

    init(guestGenerator: GuestCharacterGenerator) {
        self.guestGenerator = guestGenerator
    }

    func execute(_ input: Grievance, context: PipelineContext) async throws -> CaseFile {
        let research = CanonDatabase.research(plaintiff: input.plaintiff,
                                                defendant: input.defendant,
                                                grievance: input.grievanceText)

        var guests: [GuestCharacter] = []
        if let plaintiffId = input.guestPlaintiffId, !plaintiffId.isEmpty {
            let parts = plaintiffId.components(separatedBy: "|")
            if parts.count >= 3,
               let guest = try? await guestGenerator.generate(
                    name: parts[0], universe: parts[1], role: parts[2]) {
                guests.append(guest)
            }
        }
        if let defendantId = input.guestDefendantId, !defendantId.isEmpty {
            let parts = defendantId.components(separatedBy: "|")
            if parts.count >= 3,
               let guest = try? await guestGenerator.generate(
                    name: parts[0], universe: parts[1], role: parts[2]) {
                guests.append(guest)
            }
        }

        let briefs: [PersonaBrief] = [
            PersonaBrief(
                speaker: .jasonTodd,
                role: .plaintiffLawyer,
                argumentLadder: research.plaintiffEvidence,
                counterPoints: research.defendantEvidence,
                voiceCues: ["short, kinetic sentences", "occasional Red Hood gallows humor",
                            "never apologize, never hedge"]
            ),
            PersonaBrief(
                speaker: .mattMurdock,
                role: .defenseLawyer,
                argumentLadder: research.defendantEvidence,
                counterPoints: research.plaintiffEvidence,
                voiceCues: ["measured, precise diction", "Catholic moral framing",
                            "rebuts evidence on its own terms"]
            ),
            PersonaBrief(
                speaker: .judgeJerry,
                role: .judge,
                argumentLadder: research.keyFacts,
                counterPoints: [],
                voiceCues: ["folksy talk-show cadence", "calls out absurdity",
                            "ends every speech with a tag line"]
            ),
            PersonaBrief(
                speaker: .deadpool,
                role: .announcer,
                argumentLadder: [],
                counterPoints: [],
                voiceCues: ["fourth-wall breaks", "Neil Patrick Harris stage warmth",
                            "musical-theatre patter"]
            )
        ]

        return CaseFile(grievance: input,
                        research: research,
                        guests: guests,
                        personaBriefs: briefs)
    }
}

// MARK: - DebateNode

/// Runs the LLM-driven debate. Falls back to the scripted engine when the
/// LLM isn't available — guaranteeing a non-empty `Episode`.
struct DebateNode: PipelineNode {
    let name = "debate"
    var retryPolicy: RetryPolicy { .llm }

    private let llmFactory: @Sendable () -> (any LLMClient)?

    init(llmFactory: @escaping @Sendable () -> (any LLMClient)?) {
        self.llmFactory = llmFactory
    }

    func execute(_ input: CaseFile, context: PipelineContext) async throws -> Episode {
        if let llm = llmFactory() {
            let engine = DebateEngine(ollamaClient: llm)
            do {
                return try await engine.runDebate(grievance: input.grievance,
                                                    research: input.research,
                                                    guests: input.guests)
            } catch {
                // Retry policy will get one more shot; if the upstream fails
                // again, fallback() below produces a scripted episode.
                throw error
            }
        }
        return scriptedEpisode(for: input)
    }

    func fallback(for input: CaseFile, error: Error, context: PipelineContext) async -> Episode? {
        scriptedEpisode(for: input)
    }

    private func scriptedEpisode(for caseFile: CaseFile) -> Episode {
        var episode = Episode(id: UUID().uuidString, grievanceId: caseFile.grievance.id)
        let phases: [DebatePhase] = [.openingStatement, .witnessTestimony, .crossExamination,
                                       .evidencePresentation, .objections, .closingArguments,
                                       .juryDeliberation, .verdictAnnouncement, .finisherExecution,
                                       .postTrialCommentary, .deadpoolWrapUp]
        for phase in phases {
            let turns = ScriptedDialogueEngine.dialogueForPhase(phase,
                                                                 grievance: caseFile.grievance,
                                                                 research: caseFile.research,
                                                                 guests: caseFile.guests)
            episode.transcript.append(contentsOf: turns)
        }
        episode.verdict = ScriptedDialogueEngine.judgeVerdict(
            plaintiff: caseFile.grievance.plaintiff,
            defendant: caseFile.grievance.defendant,
            grievance: caseFile.grievance.grievanceText,
            plaintiffEvidence: caseFile.research.plaintiffEvidence,
            defendantEvidence: caseFile.research.defendantEvidence
        )
        return episode
    }
}

// MARK: - PersistenceNode

/// Persists the episode to the local store. Network persistence (Convex)
/// is a separate background concern handled by `EpisodeStore`. Returns the
/// episode unchanged so the next stage can keep using it.
struct PersistenceNode: PipelineNode {
    let name = "persistence"
    var retryPolicy: RetryPolicy { .none }

    init() {}

    func execute(_ input: Episode, context: PipelineContext) async throws -> Episode {
        await EpisodeStore.shared.addEpisode(input)
        return input
    }

    func fallback(for input: Episode, error: Error, context: PipelineContext) async -> Episode? {
        // Persistence failure is non-fatal — UI playback should still proceed.
        input
    }
}

// MARK: - PlaybackNode

/// Drives `CourtroomScene` + `VoiceSynthesisClient` for every turn in the
/// episode. Reads cancellation from the context so the user can stop the
/// trial mid-playback.
final class PlaybackNode: PipelineNode, @unchecked Sendable {
    let name = "playback"
    var retryPolicy: RetryPolicy { .none }

    private let scene: CourtroomScene
    private let voiceClient: any VoiceSynthesisServiceProtocol
    private let appState: AppState

    @MainActor
    init(scene: CourtroomScene,
                voiceClient: any VoiceSynthesisServiceProtocol,
                appState: AppState) {
        self.scene = scene
        self.voiceClient = voiceClient
        self.appState = appState
    }

    func execute(_ input: Episode, context: PipelineContext) async throws -> Episode {
        await runOnMain(input, context: context)
        return input
    }

    @MainActor
    private func runOnMain(_ episode: Episode, context: PipelineContext) async {
        for (index, turn) in episode.transcript.enumerated() {
            if context.isCancelled { return }
            let phase = phaseForTurn(turn)
            appState.currentDebatePhase = phase

            scene.showCharacter(turn.speaker)
            scene.showSpeechBubble(text: turn.text, for: turn.speaker)

            var running = Episode(id: episode.id, grievanceId: episode.grievanceId)
            running.transcript = Array(episode.transcript.prefix(index + 1))
            running.verdict = episode.verdict
            appState.activeEpisode = running

            if let frame = turn.cinematicFrame {
                scene.updateCinematicFrame(frame)
                voiceClient.playSting(stingFromString(frame.sting))
            } else {
                voiceClient.playSting(phase.sting)
            }

            let audioURL = await voiceClient.synthesize(speaker: turn.speaker, text: turn.text)
            await voiceClient.playSync(url: audioURL, speaker: turn.speaker)

            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        appState.currentDebatePhase = .complete
        appState.activeEpisode = episode
    }

    private func phaseForTurn(_ turn: SpeechTurn) -> DebatePhase {
        switch turn.phase {
        case "opening_statement": return .openingStatement
        case "witness_testimony": return .witnessTestimony
        case "cross_examination": return .crossExamination
        case "closing_arguments": return .closingArguments
        case "verdict_announcement": return .verdictAnnouncement
        case "deadpool_wrap": return .deadpoolWrapUp
        case "finisher_execution": return .finisherExecution
        case "post_trial_commentary": return .postTrialCommentary
        default: return .complete
        }
    }

    private func stingFromString(_ value: String) -> CourtroomSting {
        switch value {
        case "verdictDrumroll": return .verdictDrumroll
        case "finisherImpact": return .finisherImpact
        default: return .phaseTransition
        }
    }
}

// MARK: - FinisherNode

/// Plays the verdict's signature finisher animation, if one was selected.
final class FinisherNode: PipelineNode, @unchecked Sendable {
    let name = "finisher"
    var retryPolicy: RetryPolicy { .none }

    private let scene: CourtroomScene
    private let plaintiff: String
    private let defendant: String

    @MainActor
    init(scene: CourtroomScene, plaintiff: String, defendant: String) {
        self.scene = scene
        self.plaintiff = plaintiff
        self.defendant = defendant
    }

    func execute(_ input: Episode, context: PipelineContext) async throws -> Episode {
        await runOnMain(input)
        return input
    }

    @MainActor
    private func runOnMain(_ episode: Episode) async {
        guard let finisher = episode.verdict?.finisher else { return }
        await scene.finisherAnimator.execute(finisher,
                                               winner: plaintiff,
                                               loser: defendant,
                                               on: scene)
    }
}
