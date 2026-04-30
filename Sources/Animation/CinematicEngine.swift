import SpriteKit
import Foundation

@MainActor
final class CinematicEngine {
    private var scene: SKScene?
    private var overlayNodes: [SKNode] = []

    func attach(to scene: SKScene) {
        self.scene = scene
    }

    func triggerEffect(_ effect: CinematicEffect, duration: TimeInterval = 0.5, intensity: Double = 1.0) {
        guard let scene else { return }
        switch effect {
        case .speedLines:
            runSpeedLines(on: scene, duration: duration)
        case .benDayDots:
            runBenDayDots(on: scene, duration: duration, intensity: intensity)
        case .halftone:
            runHalftone(on: scene, duration: duration)
        case .glitch:
            runGlitch(on: scene, duration: duration)
        case .frameRateShift:
            runFrameRateShift(on: scene, duration: duration)
        case .colorShift:
            runColorShift(on: scene, duration: duration)
        case .cameraShake:
            runCameraShake(on: scene, duration: duration, intensity: intensity)
        case .comicPanel:
            runComicPanel(on: scene, duration: duration)
        }
    }

    private func runSpeedLines(on scene: SKScene, duration: TimeInterval) {
        let line = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 2, height: scene.size.height))
        line.fillColor = .white
        line.alpha = 0.3
        let moveAction = SKAction.moveBy(x: scene.size.width, y: 0, duration: duration)
        line.run(SKAction.sequence([moveAction, .removeFromParent()]))
        scene.addChild(line)
    }

    private func runBenDayDots(on scene: SKScene, duration: TimeInterval, intensity: Double) {
        let dotNode = SKSpriteNode(color: .cyan.withAlphaComponent(intensity * 0.2),
                                    size: scene.size)
        dotNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        dotNode.alpha = 0
        scene.addChild(dotNode)
        dotNode.run(SKAction.sequence([.fadeIn(withDuration: 0.1),
                                        .wait(forDuration: duration),
                                        .fadeOut(withDuration: 0.2),
                                        .removeFromParent()]))
    }

    private func runHalftone(on scene: SKScene, duration: TimeInterval) {
        let overlay = SKSpriteNode(color: .black, size: scene.size)
        overlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.alpha = 0.15
        scene.addChild(overlay)
        overlay.run(SKAction.sequence([.wait(forDuration: duration),
                                        .fadeOut(withDuration: 0.3),
                                        .removeFromParent()]))
    }

    private func runGlitch(on scene: SKScene, duration: TimeInterval) {
        guard let originalTexture = scene.view?.texture(from: scene) else { return }
        let glitchNode = SKSpriteNode(texture: originalTexture, size: scene.size)
        glitchNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        glitchNode.alpha = 0.5
        let offset = SKAction.moveBy(x: CGFloat.random(in: -20...20),
                                      y: CGFloat.random(in: -10...10), duration: 0.05)
        glitchNode.run(SKAction.sequence([offset, .removeFromParent()]))
        scene.addChild(glitchNode)
    }

    private func runFrameRateShift(on scene: SKScene, duration: TimeInterval) {
        scene.physicsWorld.speed = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            scene.physicsWorld.speed = 1.0
        }
    }

    private func runColorShift(on scene: SKScene, duration: TimeInterval) {
        let colorize = SKAction.run { scene.backgroundColor = .systemPurple }
        let revert = SKAction.run { scene.backgroundColor = .black }
        scene.run(SKAction.sequence([colorize, .wait(forDuration: duration), revert]))
    }

    private func runCameraShake(on scene: SKScene, duration: TimeInterval, intensity: Double) {
        guard let camera = scene.camera else { return }
        let shakeAmplitude = CGFloat(intensity * 10)
        let shakeAction = SKAction.repeat(SKAction.sequence([
            SKAction.moveBy(x: CGFloat.random(in: -shakeAmplitude...shakeAmplitude),
                           y: CGFloat.random(in: -shakeAmplitude...shakeAmplitude), duration: 0.03),
        ]), count: Int(duration / 0.06))
        camera.run(shakeAction)
    }

    private func runComicPanel(on scene: SKScene, duration: TimeInterval) {
        let borderW: CGFloat = 6
        let size = CGSize(width: scene.size.width - borderW * 2,
                           height: scene.size.height - borderW * 2)
        let panel = SKShapeNode(rectOf: size, cornerRadius: 12)
        panel.lineWidth = borderW
        panel.strokeColor = .white
        panel.fillColor = .clear
        panel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        panel.alpha = 0
        scene.addChild(panel)
        panel.run(SKAction.sequence([.fadeIn(withDuration: 0.2),
                                      .wait(forDuration: duration),
                                      .fadeOut(withDuration: 0.3),
                                      .removeFromParent()]))
    }

    func clearOverlays() {
        scene?.removeAllChildren()
        overlayNodes.removeAll()
    }
}

enum CinematicEffect: String, Codable, Equatable {
    case speedLines, benDayDots, halftone, glitch, frameRateShift, colorShift, cameraShake, comicPanel
}
