import SpriteKit
import Foundation

@MainActor
final class CinematicEngine {
    private weak var scene: SKScene?
    private var effectNodes: [SKNode] = []
    private let effectsQueue = DispatchQueue(label: "cinematic.effects", qos: .userInteractive)

    // MARK: - Lifecycle

    func attach(to scene: SKScene) {
        self.scene = scene
        setupPostProcessing(on: scene)
    }

    private func setupPostProcessing(on scene: SKScene) {
        guard let effectNode = SKEffectNode() as SKEffectNode? else { return }
        effectNode.name = "post_processing"
        effectNode.shouldRasterize = true
        effectNode.shouldEnableEffects = true

        let bloom = CIFilter(name: "CIBloom", parameters: [
            kCIInputRadiusKey: 3.0,
            kCIInputIntensityKey: 0.15,
        ])
        effectNode.filter = bloom

        scene.addChild(effectNode)
        effectNodes.append(effectNode)
    }

    // MARK: - Public API

    func triggerEffect(_ effect: CinematicEffect, duration: TimeInterval = 0.5, intensity: Double = 1.0) {
        guard let scene else { return }
        switch effect {
        case .speedLines:       runSpeedLines(on: scene, duration: duration, intensity: intensity)
        case .benDayDots:       runBenDayDots(on: scene, duration: duration, intensity: intensity)
        case .halftone:         runHalftone(on: scene, duration: duration)
        case .glitch:           runGlitch(on: scene, duration: duration)
        case .frameRateShift:   runFrameRateShift(on: scene, duration: duration)
        case .colorShift:       runColorShift(on: scene, duration: duration)
        case .cameraShake:      runCameraShake(on: scene, duration: duration, intensity: intensity)
        case .comicPanel:       runComicPanel(on: scene, duration: duration)
        case .impactFlash:      runImpactFlash(on: scene, duration: duration)
        case .dramaticZoom:     runDramaticZoom(on: scene, duration: duration, intensity: intensity)
        case .vignettePulse:    runVignettePulse(on: scene, duration: duration)
        case .chromaticAberration: runChromaticAberration(on: scene, duration: duration)
        }
    }

    func triggerEffectGroup(_ effects: [(CinematicEffect, TimeInterval, Double)]) {
        for (effect, duration, intensity) in effects {
            triggerEffect(effect, duration: duration, intensity: intensity)
        }
    }

    func clearOverlays() {
        for node in effectNodes where node.name != "post_processing" {
            node.removeAllChildren()
            node.removeFromParent()
        }
        effectNodes.removeAll { $0.name != "post_processing" }
    }

    // MARK: - Speed Lines (multi-layered parallax)

    private func runSpeedLines(on scene: SKScene, duration: TimeInterval, intensity: Double) {
        let lineCount = Int(12 * intensity)
        for i in 0..<lineCount {
            let delay = Double(i) * (duration / Double(lineCount))
            let y = CGFloat.random(in: 0...scene.size.height)
            let lineHeight: CGFloat = CGFloat.random(in: 80...scene.size.height * 0.6)
            let lineWidth: CGFloat = CGFloat.random(in: 1.5...4.0)

            let line = SKShapeNode(rect: CGRect(x: -20, y: y, width: lineWidth, height: lineHeight))
            line.fillColor = .white
            line.alpha = CGFloat.random(in: 0.1...0.4) * CGFloat(intensity)
            line.strokeColor = .clear

            let moveAction = SKAction.moveBy(x: scene.size.width + 40, y: 0, duration: duration)
            line.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                moveAction,
                .removeFromParent(),
            ]))
            scene.addChild(line)
        }
    }

    // MARK: - Ben-Day Dots (programmatic)

    private func runBenDayDots(on scene: SKScene, duration: TimeInterval, intensity: Double) {
        let container = SKNode()
        container.name = "benday_overlay"

        let dotRadius: CGFloat = 3.0
        let spacing: CGFloat = 8.0
        let cols = Int(scene.size.width / spacing)
        let rows = Int(scene.size.height / spacing)
        let alpha = CGFloat(intensity) * 0.15

        for row in 0..<min(rows, 30) {
            for col in 0..<min(cols, 30) {
                let dot = SKShapeNode(circleOfRadius: dotRadius)
                dot.fillColor = .cyan
                dot.alpha = alpha
                dot.position = CGPoint(x: CGFloat(col) * spacing, y: CGFloat(row) * spacing)
                dot.strokeColor = .clear
                container.addChild(dot)
            }
        }

        container.position = CGPoint(x: (scene.size.width - CGFloat(min(cols, 30)) * spacing) / 2,
                                       y: (scene.size.height - CGFloat(min(rows, 30)) * spacing) / 2)
        container.alpha = 0
        scene.addChild(container)
        effectNodes.append(container)

        container.run(SKAction.sequence([
            .fadeIn(withDuration: 0.15),
            .wait(forDuration: duration),
            .fadeOut(withDuration: 0.25),
            .removeFromParent(),
        ]))
    }

    // MARK: - Halftone

    private func runHalftone(on scene: SKScene, duration: TimeInterval) {
        let overlay = SKSpriteNode(color: .black, size: scene.size)
        overlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.alpha = 0
        overlay.blendMode = .multiply
        scene.addChild(overlay)
        effectNodes.append(overlay)

        overlay.run(SKAction.sequence([
            .fadeAlpha(to: 0.2, duration: 0.1),
            .wait(forDuration: duration),
            .fadeOut(withDuration: 0.4),
            .removeFromParent(),
        ]))
    }

    // MARK: - Glitch (multi-pass)

    private func runGlitch(on scene: SKScene, duration: TimeInterval) {
        let passes = Int(duration / 0.06)
        for i in 0..<min(passes, 12) {
            let delay = Double(i) * 0.06

            let glitchNode = SKSpriteNode(color: .magenta.withAlphaComponent(0.3),
                                             size: CGSize(width: scene.size.width,
                                                          height: CGFloat.random(in: 20...80)))
            glitchNode.position = CGPoint(
                x: scene.size.width / 2 + CGFloat.random(in: -30...30),
                y: CGFloat.random(in: 0...scene.size.height)
            )
            glitchNode.alpha = 0
            scene.addChild(glitchNode)

            glitchNode.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                .fadeAlpha(to: CGFloat.random(in: 0.2...0.5), duration: 0.02),
                .fadeOut(withDuration: 0.08),
                .removeFromParent(),
            ]))
        }
    }

    // MARK: - Frame Rate Shift

    private func runFrameRateShift(on scene: SKScene, duration: TimeInterval) {
        scene.physicsWorld.speed = 0.25
        scene.run(SKAction.sequence([
            .wait(forDuration: duration * 0.6),
            .run { scene.physicsWorld.speed = 0.5 },
            .wait(forDuration: duration * 0.3),
            .run { scene.physicsWorld.speed = 1.0 },
        ]))
    }

    // MARK: - Color Shift (eased)

    private func runColorShift(on scene: SKScene, duration: TimeInterval) {
        let originalColor = scene.backgroundColor
        let targetColor = SKColor(
            hue: CGFloat.random(in: 0.7...0.85),
            saturation: 0.8,
            brightness: 0.3,
            alpha: 1.0
        )

        let steps = 6
        let stepDuration = duration / Double(steps) / 2

        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let color = lerpColor(from: originalColor, to: targetColor, t: t)
            let delay = Double(i) * stepDuration
            scene.run(SKAction.sequence([
                .wait(forDuration: delay),
                .run { scene.backgroundColor = color },
            ]))
        }

        scene.run(SKAction.sequence([
            .wait(forDuration: duration * 0.7),
            .run { scene.backgroundColor = originalColor },
        ]))
    }

    private func lerpColor(from: SKColor, to: SKColor, t: Double) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return SKColor(
            red: r1 + CGFloat(t) * (r2 - r1),
            green: g1 + CGFloat(t) * (g2 - g1),
            blue: b1 + CGFloat(t) * (b2 - b1),
            alpha: a1 + CGFloat(t) * (a2 - a1)
        )
    }

    // MARK: - Camera Shake (decaying)

    private func runCameraShake(on scene: SKScene, duration: TimeInterval, intensity: Double) {
        guard let camera = scene.camera else {
            // Shake the scene itself if no camera
            shakeNode(scene, duration: duration, intensity: intensity)
            return
        }
        shakeNode(camera, duration: duration, intensity: intensity)
    }

    private func shakeNode(_ node: SKNode, duration: TimeInterval, intensity: Double) {
        let originalPosition = node.position
        let shakeCount = Int(duration / 0.016) // ~60fps
        let baseAmplitude = CGFloat(intensity * 12)

        var actions: [SKAction] = []
        for i in 0..<shakeCount {
            let decay = 1.0 - (Double(i) / Double(shakeCount))
            let amplitude = baseAmplitude * CGFloat(decay)
            let offsetX = CGFloat.random(in: -amplitude...amplitude)
            let offsetY = CGFloat.random(in: -amplitude...amplitude)
            actions.append(.move(to: CGPoint(x: originalPosition.x + offsetX,
                                              y: originalPosition.y + offsetY), duration: 0.016))
        }
        actions.append(.move(to: originalPosition, duration: 0.05))

        node.run(SKAction.sequence(actions))
    }

    // MARK: - Comic Panel Border

    private func runComicPanel(on scene: SKScene, duration: TimeInterval) {
        let borderW: CGFloat = 8
        let size = CGSize(width: scene.size.width - borderW * 2,
                           height: scene.size.height - borderW * 2)
        let panel = SKShapeNode(rectOf: size, cornerRadius: 16)
        panel.lineWidth = borderW
        panel.strokeColor = .white
        panel.fillColor = .clear
        panel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        panel.alpha = 0
        panel.glowWidth = 2
        scene.addChild(panel)

        panel.run(SKAction.sequence([
            .fadeIn(withDuration: 0.15),
            .wait(forDuration: duration),
            .fadeOut(withDuration: 0.3),
            .removeFromParent(),
        ]))
    }

    // MARK: - Impact Flash

    private func runImpactFlash(on scene: SKScene, duration: TimeInterval) {
        let flash = SKSpriteNode(color: .white, size: scene.size)
        flash.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        flash.alpha = 0
        flash.blendMode = .add
        scene.addChild(flash)

        flash.run(SKAction.sequence([
            .fadeAlpha(to: 1.0, duration: 0.03),
            .fadeOut(withDuration: duration),
            .removeFromParent(),
        ]))
    }

    // MARK: - Dramatic Zoom

    private func runDramaticZoom(on scene: SKScene, duration: TimeInterval, intensity: Double) {
        guard let camera = scene.camera else { return }
        let targetScale = 1.0 + CGFloat(intensity) * 0.3
        let zoomIn = SKAction.scale(to: targetScale, duration: duration * 0.4)
        let hold = SKAction.wait(forDuration: duration * 0.2)
        let zoomOut = SKAction.scale(to: 1.0, duration: duration * 0.4)
        zoomIn.timingMode = .easeInEaseOut
        zoomOut.timingMode = .easeInEaseOut
        camera.run(SKAction.sequence([zoomIn, hold, zoomOut]))
    }

    // MARK: - Vignette Pulse

    private func runVignettePulse(on scene: SKScene, duration: TimeInterval) {
        let vignette = SKShapeNode(circleOfRadius: max(scene.size.width, scene.size.height))
        vignette.fillColor = .black
        vignette.strokeColor = .clear
        vignette.alpha = 0
        vignette.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scene.addChild(vignette)
        effectNodes.append(vignette)

        vignette.run(SKAction.sequence([
            .fadeAlpha(to: 0.5, duration: 0.2),
            .wait(forDuration: duration),
            .fadeAlpha(to: 0.05, duration: 0.5),
            .removeFromParent(),
        ]))
    }

    // MARK: - Chromatic Aberration

    private func runChromaticAberration(on scene: SKScene, duration: TimeInterval) {
        guard let view = scene.view, let texture = view.texture(from: scene) else { return }

        let offsets: [(CGFloat, CGFloat, SKColor)] = [
            (-4, 0, .red.withAlphaComponent(0.3)),
            (4, 0, .cyan.withAlphaComponent(0.3)),
            (0, 2, .blue.withAlphaComponent(0.3)),
        ]

        for (dx, dy, color) in offsets {
            let channel = SKSpriteNode(texture: texture, size: scene.size)
            channel.position = CGPoint(x: scene.size.width / 2 + dx,
                                         y: scene.size.height / 2 + dy)
            channel.color = color
            channel.colorBlendFactor = 1.0
            channel.alpha = 0.4
            channel.blendMode = .add
            scene.addChild(channel)

            channel.run(SKAction.sequence([
                .wait(forDuration: duration * 0.8),
                .fadeOut(withDuration: duration * 0.2),
                .removeFromParent(),
            ]))
        }
    }
}

// MARK: - Effect Enum

enum CinematicEffect: String, Codable, Equatable {
    case speedLines
    case benDayDots
    case halftone
    case glitch
    case frameRateShift
    case colorShift
    case cameraShake
    case comicPanel
    case impactFlash
    case dramaticZoom
    case vignettePulse
    case chromaticAberration
}
