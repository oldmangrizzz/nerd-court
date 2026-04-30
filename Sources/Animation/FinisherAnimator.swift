import SpriteKit

@MainActor
final class FinisherAnimator {
    private let cinematicEngine: CinematicEngine

    init(cinematicEngine: CinematicEngine) {
        self.cinematicEngine = cinematicEngine
    }

    func execute(_ finisher: FinisherType, winner: String, loser: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.vignettePulse, duration: 0.4)
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

        // Post-finisher cleanup
        cinematicEngine.triggerEffect(.glitch, duration: 0.5)
        cinematicEngine.triggerEffect(.impactFlash, duration: 0.3)
    }

    // MARK: - Crowbar Beatdown

    private func crowbarBeatdown(attacker: String, victim: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.speedLines, duration: 2.0, intensity: 1.0)
        cinematicEngine.triggerEffect(.chromaticAberration, duration: 1.5)

        // Impact particles
        spawnImpactParticles(at: CGPoint(x: scene.size.width * 0.55, y: scene.size.height * 0.45),
                               on: scene, count: 20, color: .yellow)

        let crowbar = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 8, height: 80), cornerRadius: 4)
        crowbar.fillColor = .darkGray
        crowbar.strokeColor = .lightGray
        crowbar.glowWidth = 1
        crowbar.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.7)
        scene.addChild(crowbar)

        // Camera shake on each swing impact
        cinematicEngine.triggerEffect(.cameraShake, duration: 0.3, intensity: 2.5)
        cinematicEngine.triggerEffect(.impactFlash, duration: 0.15)

        let swing = SKAction.sequence([
            .rotate(toAngle: -.pi / 3, duration: 0.12),
            .rotate(toAngle: .pi / 4, duration: 0.08),
            .rotate(toAngle: -.pi / 2, duration: 0.08),
            .rotate(toAngle: 0, duration: 0.15),
        ])

        // Spawn particles on each beat
        let beatParticles = SKAction.run { [weak self] in
            self?.spawnImpactParticles(
                at: CGPoint(x: scene.size.width * 0.55, y: scene.size.height * 0.5),
                on: scene, count: 8, color: .red
            )
        }

        let fullSequence = SKAction.sequence([
            swing,
            beatParticles,
            .fadeOut(withDuration: 0.3),
            .removeFromParent(),
        ])

        await crowbar.run(fullSequence)
        try? await Task.sleep(nanoseconds: 1_800_000_000)
    }

    // MARK: - Lazarus Pit Dunking

    private func lazarusPitDunking(victim: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.colorShift, duration: 2.0)
        cinematicEngine.triggerEffect(.dramaticZoom, duration: 1.5, intensity: 0.6)

        // Glowing pit
        let pit = SKShapeNode(ellipseOf: CGSize(width: scene.size.width * 0.8, height: 60))
        pit.fillColor = .green
        pit.strokeColor = .yellow
        pit.glowWidth = 8
        pit.position = CGPoint(x: scene.size.width / 2, y: -30)
        pit.alpha = 0
        scene.addChild(pit)

        // Bubbling particles from pit
        let bubbleEmitter = buildEmitter(
            at: CGPoint(x: scene.size.width / 2, y: 10),
            birthRate: 60, lifetime: 1.5, color: .green,
            acceleration: CGVector(dx: 0, dy: 80), scale: 0.3
        )
        pit.addChild(bubbleEmitter)

        // Steam rising
        let steamEmitter = buildEmitter(
            at: CGPoint(x: scene.size.width / 2, y: 30),
            birthRate: 30, lifetime: 2.0, color: .white,
            acceleration: CGVector(dx: 0, dy: 40), scale: 0.2
        )
        steamEmitter.particleAlpha = 0.3
        pit.addChild(steamEmitter)

        await pit.run(SKAction.sequence([
            .fadeIn(withDuration: 0.5),
            .wait(forDuration: 1.5),
            .fadeOut(withDuration: 0.5),
            .removeFromParent(),
        ]))

        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }

    // MARK: - Deadpool Shooting

    private func deadpoolShooting(target: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.speedLines, duration: 1.5, intensity: 0.8)

        for i in 0..<8 {
            let delay = Double(i) * 0.1

            let bullet = SKShapeNode(circleOfRadius: 4)
            bullet.fillColor = .yellow
            bullet.strokeColor = .orange
            bullet.glowWidth = 2
            bullet.position = CGPoint(x: scene.size.width * 0.15,
                                      y: scene.size.height * CGFloat(0.55 + Double(i) * 0.04))
            scene.addChild(bullet)

            let trail = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 20, height: 2))
            trail.fillColor = .yellow.withAlphaComponent(0.5)
            trail.position = CGPoint(x: bullet.position.x - 20, y: bullet.position.y)
            scene.addChild(trail)

            let flyBullet = SKAction.moveBy(x: scene.size.width * 0.7,
                                              y: CGFloat.random(in: -40...40), duration: 0.25)
            let flyTrail = SKAction.moveBy(x: scene.size.width * 0.7,
                                             y: CGFloat.random(in: -40...40), duration: 0.25)

            Task {
                await bullet.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    flyBullet,
                    .removeFromParent(),
                ]))
            }
            Task {
                await trail.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    flyTrail,
                    .removeFromParent(),
                ]))
            }
        }

        cinematicEngine.triggerEffect(.cameraShake, duration: 0.4, intensity: 1.0)
        cinematicEngine.triggerEffect(.impactFlash, duration: 0.2)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
    }

    // MARK: - Character Morph

    private func characterMorph(attacker: String, victim: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.glitch, duration: 1.5)
        cinematicEngine.triggerEffect(.halftone, duration: 1.5)
        cinematicEngine.triggerEffect(.colorShift, duration: 2.0)
        cinematicEngine.triggerEffect(.chromaticAberration, duration: 1.0)

        // Morph distortion particles
        for _ in 0..<3 {
            spawnDistortionRing(
                at: CGPoint(x: scene.size.width / 2, y: scene.size.height / 2),
                on: scene
            )
            try? await Task.sleep(nanoseconds: 400_000_000)
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        await crowbarBeatdown(attacker: attacker, victim: victim, on: scene)
    }

    // MARK: - Gavel of Doom

    private func gavelOfDoom(target: String, on scene: SKScene) async {
        cinematicEngine.triggerEffect(.cameraShake, duration: 1.0, intensity: 3.0)
        cinematicEngine.triggerEffect(.dramaticZoom, duration: 1.2, intensity: 0.8)

        let gavel = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 60, height: 40), cornerRadius: 3)
        gavel.fillColor = .brown
        gavel.strokeColor = .darkGray
        gavel.glowWidth = 2
        gavel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height + 40)

        let handle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 12, height: 50))
        handle.fillColor = .darkGray
        handle.strokeColor = .black
        handle.position = CGPoint(x: gavel.position.x + 24, y: gavel.position.y - 50)

        scene.addChild(gavel)
        scene.addChild(handle)

        // Slam down
        let targetY = scene.size.height * 0.3
        let slam = SKAction.moveTo(y: targetY, duration: 0.35)
        slam.timingMode = .easeIn

        await gavel.run(slam)
        await handle.run(slam)

        // Impact effects
        cinematicEngine.triggerEffect(.cameraShake, duration: 0.8, intensity: 4.0)
        cinematicEngine.triggerEffect(.impactFlash, duration: 0.4)
        cinematicEngine.triggerEffect(.chromaticAberration, duration: 0.5)
        cinematicEngine.triggerEffect(.vignettePulse, duration: 0.6)

        spawnImpactParticles(at: CGPoint(x: gavel.position.x, y: targetY),
                               on: scene, count: 30, color: .yellow)
        spawnShockwave(at: CGPoint(x: gavel.position.x, y: targetY), on: scene)

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        gavel.removeFromParent()
        handle.removeFromParent()
    }

    // MARK: - Particle Helpers

    private func spawnImpactParticles(at position: CGPoint, on scene: SKScene,
                                        count: Int, color: SKColor) {
        for _ in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...4))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.alpha = CGFloat.random(in: 0.6...1.0)
            scene.addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...200)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed - 30

            Task {
                await particle.run(SKAction.sequence([
                    .group([
                        .move(by: CGVector(dx: dx, dy: dy), duration: CGFloat.random(in: 0.3...0.8)),
                        .fadeOut(withDuration: CGFloat.random(in: 0.4...0.8)),
                    ]),
                    .removeFromParent(),
                ]))
            }
        }
    }

    private func spawnShockwave(at position: CGPoint, on scene: SKScene) {
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = .white
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.glowWidth = 4
        ring.position = position
        ring.alpha = 0.8
        scene.addChild(ring)

        let expand = SKAction.scale(to: 8.0, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        Task {
            await ring.run(SKAction.sequence([
                .group([expand, fade]),
                .removeFromParent(),
            ]))
        }
    }

    private func spawnDistortionRing(at position: CGPoint, on scene: SKScene) {
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.strokeColor = .magenta
        ring.fillColor = .clear
        ring.lineWidth = 2
        ring.glowWidth = 6
        ring.position = position
        ring.alpha = 0.7
        scene.addChild(ring)

        let expand = SKAction.scale(to: 5.0, duration: 0.6)
        let fade = SKAction.fadeOut(withDuration: 0.6)
        let wobble = SKAction.sequence([
            .scale(to: 1.3, duration: 0.1),
            .scale(to: 0.8, duration: 0.1),
            .scale(to: 1.1, duration: 0.1),
        ])
        Task {
            await ring.run(SKAction.sequence([
                .group([expand, fade, wobble]),
                .removeFromParent(),
            ]))
        }
    }

    private func buildEmitter(at position: CGPoint, birthRate: CGFloat, lifetime: CGFloat,
                                color: SKColor, acceleration: CGVector, scale: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.particleBirthRate = birthRate
        emitter.particleLifetime = lifetime
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 0.8
        emitter.particleAlpha = 0.6
        emitter.particleAlphaSpeed = -0.3
        emitter.particleScale = scale
        emitter.particleScaleSpeed = -0.1
        emitter.particleSpeed = 10
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.particlePositionRange = CGVector(dx: 40, dy: 5)
        emitter.particleTexture = buildSoftCircleTexture()
        emitter.particleBlendMode = .add
        return emitter
    }

    private func buildSoftCircleTexture() -> SKTexture {
        let size = CGSize(width: 16, height: 16)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }

        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: locations
        ) else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }

        ctx.drawRadialGradient(gradient,
                               startCenter: CGPoint(x: 8, y: 8), startRadius: 0,
                               endCenter: CGPoint(x: 8, y: 8), endRadius: 8,
                               options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return SKTexture(image: image ?? UIImage())
    }
}
