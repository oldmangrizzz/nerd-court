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

        let research = CanonDatabase.research(plaintiff: grievance.plaintiff,
                                               defendant: grievance.defendant,
                                               grievance: grievance.grievanceText)

        var guests: [GuestCharacter] = []
        if let plaintiffId = grievance.guestPlaintiffId, !plaintiffId.isEmpty {
            let parts = plaintiffId.components(separatedBy: "|")
            if parts.count >= 3,
               let guest = try? await guestGenerator.generate(
                    name: parts[0], universe: parts[1], role: parts[2]) {
                guests.append(guest)
            }
        }

        let llmClient: any LLMClient = DeltaDispatchClient(deltaHost: AppConfig.deltaHost)
        let debateEngine = DebateEngine(ollamaClient: llmClient)
        var episode = Episode(id: UUID().uuidString, grievanceId: grievance.id)
        do {
            episode = try await debateEngine.runDebate(grievance: grievance, research: research, guests: guests)
        } catch {
            episode = fallbackEpisode(grievance: grievance, research: research, guests: guests)
        }

        saveEpisode(episode)

        for (index, turn) in episode.transcript.enumerated() {
            let phase = phaseForTurn(turn)
            appState.currentDebatePhase = phase

            scene.showCharacter(turn.speaker)

            var runningEpisode = Episode(id: episode.id, grievanceId: episode.grievanceId)
            runningEpisode.transcript = Array(episode.transcript.prefix(index + 1))
            runningEpisode.verdict = episode.verdict
            appState.activeEpisode = runningEpisode

            if let frame = turn.cinematicFrame {
                scene.updateCinematicFrame(frame)
                let sting = stingFromString(frame.sting)
                voiceClient.playSting(sting)
            } else {
                voiceClient.playSting(phase.sting)
            }

            let audioURL = await voiceClient.synthesize(speaker: turn.speaker, text: turn.text)
            await voiceClient.playSync(url: audioURL, speaker: turn.speaker)

            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        appState.currentDebatePhase = .complete
        appState.activeEpisode = episode

        if let finisher = episode.verdict?.finisher {
            await scene.finisherAnimator.execute(finisher, winner: grievance.plaintiff, loser: grievance.defendant, on: scene)
        }
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
