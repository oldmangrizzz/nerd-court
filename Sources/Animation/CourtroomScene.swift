import SpriteKit

final class CourtroomScene: SKScene {
    let cinematicEngine = CinematicEngine()
    let comicBeatOverlay = ComicBeatOverlay()

    override func didMove(to view: SKView) {
        backgroundColor = .black
        scaleMode = .resizeFill
        cinematicEngine.attach(to: self)
    }

    func showCharacter(_ speaker: Speaker, emotion: String = "neutral") {
        cinematicEngine.triggerEffect(.comicPanel, duration: 0.3)
    }

    func transitionToPhase(_ phase: DebatePhase) {
        switch phase {
        case .finisherExecution:
            cinematicEngine.triggerEffect(.speedLines, duration: 1.0, intensity: 1.0)
            cinematicEngine.triggerEffect(.cameraShake, duration: 0.8, intensity: 1.5)
            cinematicEngine.triggerEffect(.colorShift, duration: 1.5)
        case .verdictAnnouncement:
            cinematicEngine.triggerEffect(.cameraShake, duration: 0.3, intensity: 0.5)
        default:
            cinematicEngine.triggerEffect(.benDayDots, duration: 0.4, intensity: 0.5)
        }
    }
}
