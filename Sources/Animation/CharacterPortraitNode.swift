import SpriteKit
import UIKit

@MainActor
final class CharacterPortraitNode: SKNode {
    private let shapeNode: SKShapeNode
    private let labelNode: SKLabelNode
    private let speaker: Speaker
    private var isActiveState: Bool = false

    // MARK: - Factory

    static func create(for speaker: Speaker, isActive: Bool = false) -> CharacterPortraitNode {
        let node = CharacterPortraitNode(speaker: speaker)
        node.isActiveState = isActive
        node.build()
        if isActive {
            node.startPulsingGlow()
        }
        return node
    }

    // MARK: - Init

    private init(speaker: Speaker) {
        self.speaker = speaker
        self.shapeNode = SKShapeNode()
        self.labelNode = SKLabelNode()
        super.init()
        self.name = speaker.avatarID
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Build

    private func build() {
        let config = PortraitConfig.config(for: speaker)

        // Shape
        shapeNode.path = config.path
        shapeNode.fillColor = config.fillColor
        shapeNode.strokeColor = .white
        shapeNode.lineWidth = 3
        shapeNode.glowWidth = 4
        shapeNode.position = .zero
        addChild(shapeNode)

        // Label
        labelNode.text = config.initials
        labelNode.fontName = "Courier-Bold"
        labelNode.fontSize = 14
        labelNode.fontColor = .white
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint(x: 0, y: 0)
        addChild(labelNode)
    }

    // MARK: - Appearance Animation

    func playAppearAnimation() {
        alpha = 0
        setScale(0.5)
        let fade = SKAction.fadeIn(withDuration: 0.2)
        let scale = SKAction.scale(to: 1.0, duration: 0.2)
        scale.timingMode = .easeOut
        let group = SKAction.group([fade, scale])
        run(group)
    }

    // MARK: - Active State

    func setActive(_ active: Bool) {
        isActiveState = active
        if active {
            startPulsingGlow()
            let pulse = SKAction.scale(to: 1.15, duration: 0.2)
            pulse.timingMode = .easeOut
            run(pulse)
        } else {
            removeAction(forKey: "pulsingGlow")
            shapeNode.glowWidth = 4
            let pulse = SKAction.scale(to: 1.0, duration: 0.2)
            pulse.timingMode = .easeOut
            run(pulse)
        }
    }

    private func startPulsingGlow() {
        let grow = SKAction.customAction(withDuration: 0.6) { [weak self] _, elapsed in
            guard let self else { return }
            let t = CGFloat(elapsed / 0.6)
            let wave = sin(t * .pi * 2)
            self.shapeNode.glowWidth = 4 + wave * 3
        }
        let loop = SKAction.repeatForever(grow)
        shapeNode.run(loop, withKey: "pulsingGlow")
    }

    // MARK: - Configurations

    private struct PortraitConfig {
        let path: CGPath
        let fillColor: SKColor
        let initials: String

        static func config(for speaker: Speaker) -> PortraitConfig {
            switch speaker {
            case .jasonTodd:
                return PortraitConfig(path: CharacterPaths.jaggedHexagon(size: 80),
                                      fillColor: SKColor(red: 0.86, green: 0.08, blue: 0.24, alpha: 1.0),
                                      initials: "JT")
            case .mattMurdock:
                return PortraitConfig(path: CharacterPaths.shield(size: 80),
                                      fillColor: SKColor(red: 0.70, green: 0.13, blue: 0.13, alpha: 1.0),
                                      initials: "MM")
            case .judgeJerry:
                return PortraitConfig(path: CharacterPaths.gavel(size: 80),
                                      fillColor: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                                      initials: "JJ")
            case .deadpool:
                return PortraitConfig(path: CharacterPaths.chaoticStar(size: 80),
                                      fillColor: SKColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 1.0),
                                      initials: "DP")
            case .guest(_, let name):
                return PortraitConfig(path: CharacterPaths.roundedDiamond(size: 80),
                                      fillColor: SKColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 1.0),
                                      initials: String(name.prefix(2)).uppercased())
            }
        }
    }
}

// MARK: - Path Builders

private enum CharacterPaths {
    static func jaggedHexagon(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let cx: CGFloat = 0
        let cy: CGFloat = 0
        let r = size / 2
        let innerR = r * 0.55
        let points = 6
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = (i % 2 == 0) ? r : innerR
            let x = cx + radius * cos(angle)
            let y = cy + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    static func shield(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let w = size
        let h = size
        let halfW = w / 2
        let halfH = h / 2
        // Top rounded arc
        let topY = -halfH + h * 0.15
        let bottomY = halfH
        let leftX = -halfW + w * 0.1
        let rightX = halfW - w * 0.1

        path.move(to: CGPoint(x: leftX, y: topY))
        path.addQuadCurve(to: CGPoint(x: rightX, y: topY),
                          control: CGPoint(x: 0, y: -halfH - h * 0.1))
        path.addLine(to: CGPoint(x: rightX, y: topY + h * 0.4))
        path.addLine(to: CGPoint(x: 0, y: bottomY))
        path.addLine(to: CGPoint(x: leftX, y: topY + h * 0.4))
        path.closeSubpath()
        return path
    }

    static func gavel(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let w = size
        let h = size * 0.65
        let corner: CGFloat = 8
        let headRect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
        // Rounded rect head
        path.addRoundedRect(in: headRect, cornerWidth: corner, cornerHeight: corner)
        // Handle protrusion on right
        let handleW: CGFloat = size * 0.3
        let handleH: CGFloat = size * 0.18
        let handleRect = CGRect(x: w / 2 - 2, y: -handleH / 2, width: handleW, height: handleH)
        path.addRoundedRect(in: handleRect, cornerWidth: 4, cornerHeight: 4)
        return path
    }

    static func chaoticStar(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let cx: CGFloat = 0
        let cy: CGFloat = 0
        let r = size / 2
        let points = 5
        let innerR = r * 0.45
        // Deterministic warps so it looks chaotic but reproducible
        let warps: [CGFloat] = [0.92, 1.08, 0.88, 1.12, 0.95, 1.05, 0.90, 1.10, 0.97, 1.03]
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let baseRadius = (i % 2 == 0) ? r : innerR
            let radius = baseRadius * warps[i % warps.count]
            let x = cx + radius * cos(angle)
            let y = cy + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    static func roundedDiamond(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let half = size / 2
        let corner: CGFloat = 12
        // Build a diamond (rotated square) with rounded corners
        let p1 = CGPoint(x: 0, y: -half)
        let p2 = CGPoint(x: half, y: 0)
        let p3 = CGPoint(x: 0, y: half)
        let p4 = CGPoint(x: -half, y: 0)

        path.move(to: midpoint(p1, p2, t: corner / size))
        path.addQuadCurve(to: midpoint(p2, p3, t: corner / size), control: p2)
        path.addQuadCurve(to: midpoint(p3, p4, t: corner / size), control: p3)
        path.addQuadCurve(to: midpoint(p4, p1, t: corner / size), control: p4)
        path.addQuadCurve(to: midpoint(p1, p2, t: corner / size), control: p1)
        path.closeSubpath()
        return path
    }

    private static func midpoint(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
        return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
