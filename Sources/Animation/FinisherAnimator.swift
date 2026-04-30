import SpriteKit

@MainActor
final class FinisherAnimator {
    private let cinematicEngine: CinematicEngine

    init(cinematicEngine: CinematicEngine) {
        self.cinematicEngine = cinematicEngine
    }

    func execute(_ finisher: FinisherType, winner: String, loser: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.cameraShake, duration: 0.5, intensity: 2.0)

        switch finisher {
        case .crowbarBeatdown:
            await crowbarBeatdown(attacker: winner, victim: loser, on: scene)
        case .lazarusPitDunking:
            await lazarusPitDunking(victim: loser, on: scene)
        case .deadpoolShooting:
            await deadpoolShooting(target: loser, on: scene)
        case .characterMorph:
            await characterMorph(attacker: winner, victim: loser, on: scene)
        case .gavelOfDoom:
            await gavelOfDoom(target: loser, on: scene)
        }

        cinematicEngine.triggerEffect(.glitch, duration: 0.5)
    }

    private func crowbarBeatdown(attacker: String, victim: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.speedLines, duration: 2.0, intensity: 1.0)
        cinematicEngine.triggerEffect(.cameraShake, duration: 1.5, intensity: 2.0)

        let crowbar = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 8, height: 80), cornerRadius: 4)
        crowbar.fillColor = .darkGray
        crowbar.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.7)
        scene.addChild(crowbar)

        let swing = SKAction.sequence([
            .rotate(toAngle: -.pi / 3, duration: 0.15),
            .rotate(toAngle: .pi / 4, duration: 0.1),
            .rotate(toAngle: -.pi / 2, duration: 0.1),
            .rotate(toAngle: 0, duration: 0.2),
        ])
        await crowbar.run(SKAction.sequence([swing, .fadeOut(withDuration: 0.3), .removeFromParent()]))
        try? await Task.sleep(nanoseconds: 1_800_000_000)
    }

    private func lazarusPitDunking(victim: String, on scene: SKScene) async {
        let pit = SKShapeNode(ellipseOf: CGSize(width: scene.size.width * 0.8, height: 60))
        pit.fillColor = .green
        pit.strokeColor = .yellow
        pit.glowWidth = 4
        pit.position = CGPoint(x: scene.size.width / 2, y: -30)
        pit.alpha = 0
        scene.addChild(pit)

        cinematicEngine.triggerEffect(.colorShift, duration: 1.5)
        await pit.run(SKAction.sequence([.fadeIn(withDuration: 0.5),
                                    .wait(forDuration: 1.0),
                                    .fadeOut(withDuration: 0.5),
                                    .removeFromParent()]))
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }

    private func deadpoolShooting(target: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.speedLines, duration: 1.0, intensity: 0.8)
        for i in 0..<6 {
            let bullet = SKShapeNode(circleOfRadius: 4)
            bullet.fillColor = .yellow
            bullet.position = CGPoint(x: scene.size.width * 0.2,
                                      y: scene.size.height * CGFloat(0.6 + Double(i) * 0.05))
            scene.addChild(bullet)
            let fly = SKAction.moveBy(x: scene.size.width * 0.6, y: CGFloat.random(in: -30...30),
                                       duration: 0.3)
            await bullet.run(SKAction.sequence([fly, .removeFromParent()]))
        }
        cinematicEngine.triggerEffect(.cameraShake, duration: 0.4, intensity: 1.0)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
    }

    private func characterMorph(attacker: String, victim: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.glitch, duration: 1.0)
        cinematicEngine.triggerEffect(.halftone, duration: 1.0)
        cinematicEngine.triggerEffect(.colorShift, duration: 1.5)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await crowbarBeatdown(attacker: attacker, victim: victim, on: scene)
    }

    private func gavelOfDoom(target: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.cameraShake, duration: 1.0, intensity: 3.0)
        let gavel = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 60, height: 40), cornerRadius: 3)
        gavel.fillColor = .brown
        gavel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height + 40)

        let handle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 12, height: 50))
        handle.fillColor = .darkGray
        handle.position = CGPoint(x: gavel.position.x + 24, y: gavel.position.y - 50)
        scene.addChild(gavel)
        scene.addChild(handle)

        let slam = SKAction.moveTo(y: scene.size.height * 0.3, duration: 0.4)
        await gavel.run(slam)
        await handle.run(slam)
        cinematicEngine.triggerEffect(.cameraShake, duration: 0.8, intensity: 3.0)

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        gavel.removeFromParent()
        handle.removeFromParent()
    }
}
