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

        // Real canon research from embedded database
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

        // Build episode incrementally with live UI updates
        var episode = Episode(id: UUID().uuidString, grievanceId: grievance.id)
        episode.transcript = []

        let phases: [DebatePhase] = [.openingStatement, .witnessTestimony, .crossExamination,
                                      .evidencePresentation, .objections, .closingArguments,
                                      .juryDeliberation, .verdictAnnouncement, .finisherExecution,
                                      .postTrialCommentary, .deadpoolWrapUp]

        for phase in phases {
            appState.currentDebatePhase = phase
            scene.transitionToPhase(phase)
            voiceClient.playSting(phase.sting)

            let turns = ScriptedDialogueEngine.dialogueForPhase(phase, grievance: grievance, research: research, guests: guests)
            for turn in turns {
                episode.transcript.append(turn)
                appState.activeEpisode = episode
                scene.showCharacter(turn.speaker)
                // Each turn gets half-second render time on device
                try? await Task.sleep(nanoseconds: 600_000_000)
            }
        }

        // Final verdict
        let verdict = ScriptedDialogueEngine.judgeVerdict(plaintiff: grievance.plaintiff,
                                                           defendant: grievance.defendant,
                                                           grievance: grievance.grievanceText,
                                                           plaintiffEvidence: research.plaintiffEvidence,
                                                           defendantEvidence: research.defendantEvidence)
        episode.verdict = verdict
        appState.activeEpisode = episode

        saveEpisode(episode)
        appState.currentDebatePhase = .complete
        voiceClient.playSting(.dramaticReveal)
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
