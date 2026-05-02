import Foundation
import Observation

@MainActor
@Observable final class AppState {
    var grievances: [Grievance] = []
    var episodes: [Episode] = []
    var activeEpisode: Episode?
    var activeGrievance: Grievance?
    var isTrialRunning = false
    var currentDebatePhase: DebatePhase = .intake
    var guests: [GuestCharacter] = []
    var courtScene: CGRect = .zero
    var selectedTab: Int = 0

    var decidedEpisodes: [Episode] {
        episodes.filter { $0.verdict != nil }
    }
}
