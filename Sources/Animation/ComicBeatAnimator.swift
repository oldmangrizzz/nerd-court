import SpriteKit

@MainActor
final class ComicBeatAnimator {
    private var labelNode: SKLabelNode?

    func showBeat(text: String, on scene: SKScene, duration: TimeInterval = 3.0) {
        labelNode?.removeFromParent()
        let label = SKLabelNode(text: text)
        label.fontSize = 28
        label.fontColor = .yellow
        label.fontName = "AvenirNext-Bold"
        label.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 60)
        label.alpha = 0
        label.setScale(0.5)

        let show = SKAction.group([.fadeIn(withDuration: 0.3), .scale(to: 1.0, duration: 0.3)])
        let hide = SKAction.group([.fadeOut(withDuration: 0.3), .scale(to: 1.5, duration: 0.3)])
        let sequence = SKAction.sequence([show, .wait(forDuration: duration), hide, .removeFromParent()])

        scene.addChild(label)
        label.run(sequence)
        labelNode = label
    }
}
