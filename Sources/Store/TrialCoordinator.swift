import Foundation
import SwiftUI

@MainActor
@Observable final class TrialCoordinator {
    private let voiceClient: any VoiceSynthesisServiceProtocol
    private let guestGenerator: GuestCharacterGenerator

    init(voiceClient: any VoiceSynthesisServiceProtocol,
         guestGenerator: GuestCharacterGenerator) {
        self.voiceClient = voiceClient
        self.guestGenerator = guestGenerator
    }

    func startTrial(scene: CourtroomScene, grievance: Grievance, appState: AppState) async {
        appState.isTrialRunning = true
        defer { appState.isTrialRunning = false }

        voiceClient.preloadVoices()

        let workflow = TrialWorkflowFactory.build(
            grievance: grievance,
            scene: scene,
            voiceClient: voiceClient,
            guestGenerator: guestGenerator,
            appState: appState
        )
        let (resultTask, events) = workflow.run(grievance)

        // Drain the event stream into a structured trace for debugging /
        // future replay. Fire-and-forget; the workflow drives playback.
        Task { @MainActor in
            for await event in events {
                Self.log(event: event)
            }
        }

        do {
            _ = try await resultTask.value
        } catch {
            // Workflow runner already emitted the failure event. Nothing more
            // to do — the playback node was the last user-visible stage and
            // either ran a real or fallback episode.
            #if DEBUG
            print("[TrialCoordinator] workflow failed: \(error.localizedDescription)")
            #endif
        }
    }

    private static func log(event: WorkflowEvent) {
        #if DEBUG
        switch event {
        case .workflowStarted(let n):
            print("[trial] ▶︎ \(n)")
        case .nodeStarted(let n):
            print("[trial]  · start  \(n)")
        case .nodeCompleted(let n, let ms):
            print("[trial]  ✓ \(n) (\(ms)ms)")
        case .nodeRetry(let n, let attempt, let err):
            print("[trial]  ↻ retry \(n) #\(attempt) — \(err)")
        case .nodeFallback(let n, let err):
            print("[trial]  ⤵︎ fallback \(n) — \(err)")
        case .workflowCompleted(let n, let ms):
            print("[trial] ✓ \(n) total \(ms)ms")
        case .workflowFailed(let n, let node, let err):
            print("[trial] ✗ \(n) at \(node) — \(err)")
        case .workflowCancelled(let n):
            print("[trial] ⦸ \(n) cancelled")
        }
        #endif
    }

    private func fallbackEpisode(grievance: Grievance, research: CanonResearchResult, guests: [GuestCharacter]) -> Episode {
        var episode = Episode(id: UUID().uuidString, grievanceId: grievance.id)
        let phases: [DebatePhase] = [.openingStatement, .witnessTestimony, .crossExamination,
                                      .evidencePresentation, .objections, .closingArguments,
                                      .juryDeliberation, .verdictAnnouncement, .finisherExecution,
                                      .postTrialCommentary, .deadpoolWrapUp]
        for phase in phases {
            let turns = ScriptedDialogueEngine.dialogueForPhase(phase, grievance: grievance, research: research, guests: guests)
            episode.transcript.append(contentsOf: turns)
        }
        episode.verdict = ScriptedDialogueEngine.judgeVerdict(plaintiff: grievance.plaintiff,
                                                               defendant: grievance.defendant,
                                                               grievance: grievance.grievanceText,
                                                               plaintiffEvidence: research.plaintiffEvidence,
                                                               defendantEvidence: research.defendantEvidence)
        return episode
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

    private func saveEpisode(_ episode: Episode) {
        let episodeToSave = episode
        let store = EpisodeStore.shared
        let saveTask: Task<Void, Never> = Task { [episodeToSave, store] in
            await store.addEpisode(episodeToSave)
        }
        _ = saveTask
    }
}

// MARK: — Phase stings

extension DebatePhase {
    var sting: CourtroomSting {
        switch self {
        case .openingStatement:      return .gavelStrike
        case .witnessTestimony:     return .objection
        case .crossExamination:     return .crowdGasp
        case .evidencePresentation: return .phaseTransition
        case .objections:           return .objection
        case .closingArguments:     return .verdictDrumroll
        case .verdictAnnouncement:  return .dramaticReveal
        case .finisherExecution:    return .finisherImpact
        case .postTrialCommentary:  return .crowdLaugh
        case .deadpoolWrapUp:       return .deadpoolEntrance
        default:                    return .phaseTransition
        }
    }
}
