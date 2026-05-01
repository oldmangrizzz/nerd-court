import SpriteKit
import Foundation

// MARK: - Result Type

/// The result of a finisher animation sequence.
struct SKAnimateResult {
    let success: Bool
    let duration: TimeInterval
}

// MARK: - Finisher Executor

/// Executes SpriteKit-based finisher animations for Nerd Court verdicts.
@MainActor
final class FinisherExecutor {

    // MARK: - Public API

    /// Runs the specified finisher animation on the given scene.
    /// - Parameters:
    ///   - finisher: The type of finisher to animate.
    ///   - target: The character receiving the finisher.
    ///   - executor: The character delivering the finisher.
    ///   - scene: The SpriteKit scene where the animation will play.
    /// - Returns: An `SKAnimateResult` indicating success and duration.
    func execute(
        finisher: FinisherType,
        target: Speaker,
        executor: Speaker,
        in scene: SKScene
    ) async throws -> SKAnimateResult {
        let startTime = Date()

        // Build the animation sequence
        let sequence = try buildSequence(for: finisher, target: target, executor: executor, in: scene)

        // Run the sequence and wait for completion
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            scene.run(sequence) {
                continuation.resume()
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        return SKAnimateResult(success: true, duration: duration)
    }

    // MARK: - Sequence Builders

    private func buildSequence(
        for finisher: FinisherType,
        target: Speaker,
        executor: Speaker,
        in scene: SKScene
    ) throws -> SKAction {
        // Remove any previous finisher nodes (clean slate)
        scene.childNode(withName: "finisherRoot")?.removeFromParent()

        let root = SKNode()
        root.name = "finisherRoot"
        scene.addChild(root)

        switch finisher {
        case .crowbarBeatdown:
            return crowbarBeatdown(target: target, executor: executor, root: root, scene: scene)
        case .lazarusPitDunking:
            return lazarusPitDunking(target: target, executor: executor, root: root, scene: scene)
        case .deadpoolShooting:
            return deadpoolShooting(target: target, executor: executor, root: root, scene: scene)
        case .characterMorph:
            return characterMorph(target: target, executor: executor, root: root, scene: scene)
        case .gavelOfDoom:
            return gavelOfDoom(target: target, executor: executor, root: root, scene: scene)
        }
    }

    // MARK: - Individual Finisher Animations

    private func crowbarBeatdown(
        target: Speaker,
        executor: Speaker,
        root: SKNode,
        scene: SKScene
    ) -> SKAction {
        // Create character representations
        let executorNode = characterNode(for: executor, at: CGPoint(x: -150, y: 0))
        let targetNode = characterNode(for: target, at: CGPoint(x: 150, y: 0))
        root.addChild(executorNode)
        root.addChild(targetNode)

        // Crowbar node
        let crowbar = SKShapeNode(rectOf: CGSize(width: 10, height: 80), cornerRadius: 4)
        crowbar.fillColor = .darkGray
        crowbar.position = CGPoint(x: -150, y: 40)
        root.addChild(crowbar)

        // Impact star
        let impactStar = SKLabelNode(text: "💥")
        impactStar.fontSize = 40
        impactStar.alpha = 0
        impactStar.position = CGPoint(x: 150, y: 20)
        root.addChild(impactStar)

        // Sound actions
        let swingSound = SKAction.playSoundFileNamed("crowbar_swing.wav", waitForCompletion: false)
        let hitSound = SKAction.playSoundFileNamed("crowbar_hit.wav", waitForCompletion: false)
        let targetOuch = SKAction.playSoundFileNamed("pain_grunt.wav", waitForCompletion: false)

        // Animation sequence
        let moveCrowbarBack = SKAction.moveTo(x: -180, duration: 0.2)
        let swingForward = SKAction.moveTo(x: 150, duration: 0.15)
        let resetCrowbar = SKAction.moveTo(x: -150, duration: 0.1)

        let swingSequence = SKAction.sequence([
            moveCrowbarBack,
            swingSound,
            swingForward,
            hitSound,
            SKAction.run { impactStar.alpha = 1.0 },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { impactStar.alpha = 0.0 },
            targetOuch,
            SKAction.run { [weak targetNode] in
                targetNode?.run(SKAction.sequence([
                    SKAction.moveBy(x: 0, y: -10, duration: 0.05),
                    SKAction.moveBy(x: 0, y: 10, duration: 0.05)
                ]))
            },
            resetCrowbar
        ])

        // Repeat the swing a few times
        let repeatedSwings = SKAction.repeat(swingSequence, count: 3)

        // Final dramatic pause and cleanup
        let finalPose = SKAction.run { [weak executorNode] in
            executorNode?.run(SKAction.rotate(byAngle: -.pi / 8, duration: 0.3))
        }

        return SKAction.sequence([
            repeatedSwings,
            finalPose,
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent() // remove root
        ])
    }

    private func lazarusPitDunking(
        target: Speaker,
        executor: Speaker,
        root: SKNode,
        scene: SKScene
    ) -> SKAction {
        let executorNode = characterNode(for: executor, at: CGPoint(x: -120, y: 0))
        let targetNode = characterNode(for: target, at: CGPoint(x: 120, y: 0))
        root.addChild(executorNode)
        root.addChild(targetNode)

        // Lazarus Pit (green glowing circle)
        let pit = SKShapeNode(circleOfRadius: 60)
        pit.fillColor = .green
        pit.alpha = 0.6
        pit.position = CGPoint(x: 120, y: -80)
        root.addChild(pit)

        // Bubbles
        let bubble = SKLabelNode(text: "🫧")
        bubble.fontSize = 30
        bubble.alpha = 0
        bubble.position = CGPoint(x: 120, y: -80)
        root.addChild(bubble)

        // Sounds
        let grabSound = SKAction.playSoundFileNamed("grab.wav", waitForCompletion: false)
        let splashSound = SKAction.playSoundFileNamed("splash.wav", waitForCompletion: false)
        let glugSound = SKAction.playSoundFileNamed("glug.wav", waitForCompletion: false)

        // Animation
        let executorGrab = SKAction.moveTo(x: 120, duration: 0.3)
        let liftTarget = SKAction.run { [weak targetNode] in
            targetNode?.run(SKAction.moveBy(x: 0, y: 20, duration: 0.2))
        }
        let dunkDown = SKAction.moveTo(y: -80, duration: 0.4)
        let sink = SKAction.fadeOut(withDuration: 0.5)
        let bubbleAppear = SKAction.run { bubble.alpha = 1.0 }
        let bubbleRise = SKAction.moveBy(x: 0, y: 40, duration: 0.5)

        return SKAction.sequence([
            executorGrab,
            grabSound,
            liftTarget,
            SKAction.wait(forDuration: 0.2),
            SKAction.group([
                SKAction.sequence([
                    dunkDown,
                    splashSound,
                    sink,
                    glugSound
                ]),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.3),
                    bubbleAppear,
                    bubbleRise,
                    SKAction.fadeOut(withDuration: 0.3)
                ])
            ]),
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
    }

    private func deadpoolShooting(
        target: Speaker,
        executor: Speaker,
        root: SKNode,
        scene: SKScene
    ) -> SKAction {
        let executorNode = characterNode(for: executor, at: CGPoint(x: -150, y: 0))
        let targetNode = characterNode(for: target, at: CGPoint(x: 150, y: 0))
        root.addChild(executorNode)
        root.addChild(targetNode)

        // Gun (simple rectangle)
        let gun = SKShapeNode(rectOf: CGSize(width: 8, height: 30))
        gun.fillColor = .black
        gun.position = CGPoint(x: -140, y: 20)
        root.addChild(gun)

        // Muzzle flash
        let flash = SKShapeNode(circleOfRadius: 15)
        flash.fillColor = .yellow
        flash.alpha = 0
        flash.position = CGPoint(x: -130, y: 30)
        root.addChild(flash)

        // Bullet hole on target
        let hole = SKShapeNode(circleOfRadius: 5)
        hole.fillColor = .red
        hole.alpha = 0
        hole.position = CGPoint(x: 150, y: 10)
        root.addChild(hole)

        // Sounds
        let gunshot = SKAction.playSoundFileNamed("gunshot.wav", waitForCompletion: false)
        let deadpoolLaugh = SKAction.playSoundFileNamed("deadpool_laugh.wav", waitForCompletion: false)
        let targetFall = SKAction.playSoundFileNamed("body_fall.wav", waitForCompletion: false)

        // Animation
        let aimGun = SKAction.rotate(toAngle: 0.2, duration: 0.1)
        let fire = SKAction.sequence([
            SKAction.run { flash.alpha = 1.0 },
            SKAction.wait(forDuration: 0.05),
            SKAction.run { flash.alpha = 0.0 }
        ])
        let showHole = SKAction.run { hole.alpha = 1.0 }
        let targetReaction = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 0.05),
            SKAction.moveBy(x: 0, y: -20, duration: 0.2),
            SKAction.fadeOut(withDuration: 0.3)
        ])

        return SKAction.sequence([
            aimGun,
            SKAction.wait(forDuration: 0.1),
            fire,
            gunshot,
            showHole,
            targetReaction,
            targetFall,
            deadpoolLaugh,
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
    }

    private func characterMorph(
        target: Speaker,
        executor: Speaker,
        root: SKNode,
        scene: SKScene
    ) -> SKAction {
        // The "winner" morphs into an iconic villain. We'll represent this with a transformation effect.
        let winnerNode = characterNode(for: executor, at: .zero)
        root.addChild(winnerNode)

        // Transformation swirl
        let swirl = SKShapeNode(circleOfRadius: 40)
        swirl.fillColor = .purple
        swirl.alpha = 0
        swirl.position = .zero
        root.addChild(swirl)

        // New form label
        let newForm = SKLabelNode(text: "👹")
        newForm.fontSize = 60
        newForm.alpha = 0
        newForm.position = .zero
        root.addChild(newForm)

        // Sounds
        let morphSound = SKAction.playSoundFileNamed("morph.wav", waitForCompletion: false)
        let evilLaugh = SKAction.playSoundFileNamed("evil_laugh.wav", waitForCompletion: false)

        // Animation
        let shrink = SKAction.scale(to: 0.1, duration: 0.3)
        let swirlGrow = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 2.0, duration: 0.3)
        ])
        let reveal = SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])

        return SKAction.sequence([
            morphSound,
            SKAction.group([
                shrink,
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.1),
                    swirlGrow
                ])
            ]),
            SKAction.run { winnerNode.removeFromParent() },
            SKAction.wait(forDuration: 0.1),
            reveal,
            evilLaugh,
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
    }

    private func gavelOfDoom(
        target: Speaker,
        executor: Speaker,
        root: SKNode,
        scene: SKScene
    ) -> SKAction {
        // Judge Jerry's gavel grows huge and smashes the target.
        let judgeNode = characterNode(for: executor, at: CGPoint(x: -120, y: 0))
        let targetNode = characterNode(for: target, at: CGPoint(x: 120, y: 0))
        root.addChild(judgeNode)
        root.addChild(targetNode)

        // Gavel
        let gavelHandle = SKShapeNode(rectOf: CGSize(width: 8, height: 40))
        gavelHandle.fillColor = .brown
        let gavelHead = SKShapeNode(rectOf: CGSize(width: 30, height: 15), cornerRadius: 3)
        gavelHead.fillColor = .brown
        gavelHead.position = CGPoint(x: 0, y: 20)
        let gavel = SKNode()
        gavel.addChild(gavelHandle)
        gavel.addChild(gavelHead)
        gavel.position = CGPoint(x: -120, y: 30)
        root.addChild(gavel)

        // Impact effect
        let impact = SKShapeNode(circleOfRadius: 20)
        impact.fillColor = .orange
        impact.alpha = 0
        impact.position = CGPoint(x: 120, y: 0)
        root.addChild(impact)

        // Sounds
        let gavelSwing = SKAction.playSoundFileNamed("whoosh.wav", waitForCompletion: false)
        let smashSound = SKAction.playSoundFileNamed("gavel_smash.wav", waitForCompletion: false)
        let targetSquish = SKAction.playSoundFileNamed("squish.wav", waitForCompletion: false)

        // Animation
        let raiseGavel = SKAction.moveBy(x: 0, y: 60, duration: 0.2)
        let enlargeGavel = SKAction.scale(to: 2.5, duration: 0.3)
        let slamDown = SKAction.moveTo(y: -20, duration: 0.2)
        let shakeTarget = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -10, duration: 0.05),
            SKAction.moveBy(x: 0, y: 5, duration: 0.05)
        ])
        let squishTarget = SKAction.scaleY(to: 0.3, duration: 0.2)

        return SKAction.sequence([
            raiseGavel,
            gavelSwing,
            enlargeGavel,
            SKAction.wait(forDuration: 0.1),
            slamDown,
            smashSound,
            SKAction.run { impact.alpha = 1.0 },
            SKAction.group([
                shakeTarget,
                squishTarget
            ]),
            targetSquish,
            SKAction.wait(forDuration: 0.3),
            SKAction.run { impact.alpha = 0.0 },
            SKAction.wait(forDuration: 0.3),
            SKAction.removeFromParent()
        ])
    }

    // MARK: - Helper Nodes

    /// Creates a simple visual representation for a speaker.
    private func characterNode(for speaker: Speaker, at position: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = position

        // Body circle
        let body = SKShapeNode(circleOfRadius: 25)
        body.fillColor = color(for: speaker)
        body.strokeColor = .white
        node.addChild(body)

        // Label with speaker name
        let label = SKLabelNode(text: displayName(for: speaker))
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        node.addChild(label)

        return node
    }

    private func color(for speaker: Speaker) -> SKColor {
        switch speaker {
        case .jasonTodd: return .red
        case .mattMurdock: return .darkGray
        case .judgeJerry: return .brown
        case .deadpool: return .black
        case .guest: return .blue
        }
    }

    private func displayName(for speaker: Speaker) -> String {
        switch speaker {
        case .jasonTodd: return "Jason"
        case .mattMurdock: return "Matt"
        case .judgeJerry: return "Jerry"
        case .deadpool: return "DP"
        case .guest(_, let name): return name
        }
    }
}