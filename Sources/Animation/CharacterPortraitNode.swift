import SpriteKit
import UIKit

@MainActor
final class CharacterPortraitNode: SKNode {
    private let bodyNode: SKNode
    private let glowNode: SKShapeNode
    private let nameplateNode: SKLabelNode
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
        self.bodyNode = SKNode()
        self.glowNode = SKShapeNode(circleOfRadius: 52)
        self.nameplateNode = SKLabelNode()
        super.init()
        self.name = speaker.avatarID
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Build

    private func build() {
        // Backplate glow — character-tinted halo behind the portrait.
        glowNode.fillColor = PortraitPalette.tint(for: speaker).withAlphaComponent(0.22)
        glowNode.strokeColor = PortraitPalette.tint(for: speaker)
        glowNode.lineWidth = 2.5
        glowNode.glowWidth = 6
        glowNode.zPosition = -1
        addChild(glowNode)

        // Layered character body — actually looks like the character at glance.
        switch speaker {
        case .jasonTodd:
            buildJasonTodd(into: bodyNode)
        case .mattMurdock:
            buildMattMurdock(into: bodyNode)
        case .judgeJerry:
            buildJerrySpringer(into: bodyNode)
        case .deadpool:
            buildDeadpool(into: bodyNode)
        case .guest(_, let name):
            buildGuestSilhouette(into: bodyNode, initials: String(name.prefix(2)).uppercased())
        }
        addChild(bodyNode)

        // Nameplate beneath the portrait.
        nameplateNode.text = speaker.displayName.uppercased()
        nameplateNode.fontName = "AvenirNext-Heavy"
        nameplateNode.fontSize = 9
        nameplateNode.fontColor = .white
        nameplateNode.horizontalAlignmentMode = .center
        nameplateNode.verticalAlignmentMode = .center
        nameplateNode.position = CGPoint(x: 0, y: -64)
        addChild(nameplateNode)
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
            glowNode.glowWidth = 6
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
            self.glowNode.glowWidth = 6 + wave * 4
        }
        let loop = SKAction.repeatForever(grow)
        glowNode.run(loop, withKey: "pulsingGlow")
    }
}

// MARK: - Palette

private enum PortraitPalette {
    static func tint(for speaker: Speaker) -> SKColor {
        switch speaker {
        case .jasonTodd:   return SKColor(red: 0.86, green: 0.08, blue: 0.10, alpha: 1.0)  // Red Hood crimson
        case .mattMurdock: return SKColor(red: 0.70, green: 0.10, blue: 0.10, alpha: 1.0)  // DD red
        case .judgeJerry:  return SKColor(red: 1.00, green: 0.84, blue: 0.20, alpha: 1.0)  // gavel gold
        case .deadpool:    return SKColor(red: 1.00, green: 0.18, blue: 0.20, alpha: 1.0)  // DP red
        case .guest:       return SKColor(red: 0.20, green: 0.78, blue: 0.86, alpha: 1.0)
        }
    }
}

// MARK: - Character Compositions

private extension CharacterPortraitNode {

    /// Jason Todd — Red Hood helmet silhouette: red dome, dark visor band, single
    /// "R" hood bat emblem suggestion. Reads as "guy in a red helmet."
    func buildJasonTodd(into parent: SKNode) {
        // Helmet dome (rounded square, slightly elongated).
        let helmet = SKShapeNode(ellipseOf: CGSize(width: 70, height: 80))
        helmet.fillColor = SKColor(red: 0.78, green: 0.06, blue: 0.08, alpha: 1.0)
        helmet.strokeColor = .black
        helmet.lineWidth = 2
        parent.addChild(helmet)

        // Highlight rim
        let rim = SKShapeNode(ellipseOf: CGSize(width: 56, height: 66))
        rim.fillColor = .clear
        rim.strokeColor = SKColor(red: 1.0, green: 0.30, blue: 0.30, alpha: 0.8)
        rim.lineWidth = 1.5
        rim.position = CGPoint(x: -2, y: 4)
        parent.addChild(rim)

        // Visor band — horizontal black slit across the eyes.
        let visor = SKShapeNode(rect: CGRect(x: -32, y: -4, width: 64, height: 14), cornerRadius: 3)
        visor.fillColor = .black
        visor.strokeColor = SKColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.0)
        visor.lineWidth = 1.5
        parent.addChild(visor)

        // Visor glow inset (Spider-Verse highlight).
        let visorGlow = SKShapeNode(rect: CGRect(x: -28, y: 0, width: 56, height: 4), cornerRadius: 2)
        visorGlow.fillColor = SKColor(red: 1.0, green: 0.20, blue: 0.20, alpha: 0.7)
        visorGlow.strokeColor = .clear
        parent.addChild(visorGlow)

        // Jaw shadow
        let jaw = SKShapeNode(ellipseOf: CGSize(width: 40, height: 10))
        jaw.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.55)
        jaw.strokeColor = .clear
        jaw.position = CGPoint(x: 0, y: -28)
        parent.addChild(jaw)
    }

    /// Matt Murdock — court attire: face oval, dark glasses, suit collar with red tie.
    /// Reads as "blind lawyer in a suit."
    func buildMattMurdock(into parent: SKNode) {
        // Face oval (warm skin tone).
        let face = SKShapeNode(ellipseOf: CGSize(width: 60, height: 72))
        face.fillColor = SKColor(red: 0.95, green: 0.78, blue: 0.65, alpha: 1.0)
        face.strokeColor = .black
        face.lineWidth = 1.5
        parent.addChild(face)

        // Hair (auburn).
        let hair = SKShapeNode(ellipseOf: CGSize(width: 64, height: 30))
        hair.fillColor = SKColor(red: 0.45, green: 0.20, blue: 0.10, alpha: 1.0)
        hair.strokeColor = .black
        hair.lineWidth = 1.5
        hair.position = CGPoint(x: 0, y: 28)
        parent.addChild(hair)

        // Round dark glasses — two circles connected by a bridge.
        let leftLens = SKShapeNode(circleOfRadius: 11)
        leftLens.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        leftLens.strokeColor = .black
        leftLens.lineWidth = 1.5
        leftLens.position = CGPoint(x: -14, y: 4)
        parent.addChild(leftLens)

        let rightLens = SKShapeNode(circleOfRadius: 11)
        rightLens.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        rightLens.strokeColor = .black
        rightLens.lineWidth = 1.5
        rightLens.position = CGPoint(x: 14, y: 4)
        parent.addChild(rightLens)

        let bridge = SKShapeNode(rect: CGRect(x: -3, y: 3, width: 6, height: 2), cornerRadius: 1)
        bridge.fillColor = .black
        bridge.strokeColor = .clear
        parent.addChild(bridge)

        // Suit collar shoulders.
        let collar = SKShapeNode(rect: CGRect(x: -34, y: -52, width: 68, height: 26), cornerRadius: 4)
        collar.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
        collar.strokeColor = .black
        collar.lineWidth = 1.5
        parent.addChild(collar)

        // Red tie.
        let tie = SKShapeNode(rect: CGRect(x: -4, y: -50, width: 8, height: 22), cornerRadius: 1)
        tie.fillColor = SKColor(red: 0.78, green: 0.08, blue: 0.08, alpha: 1.0)
        tie.strokeColor = .black
        tie.lineWidth = 1
        parent.addChild(tie)
    }

    /// Jerry Springer — TV host: face, white hair, blue suit, microphone hint.
    /// Reads as "older talk-show host."
    func buildJerrySpringer(into parent: SKNode) {
        // Face oval.
        let face = SKShapeNode(ellipseOf: CGSize(width: 58, height: 68))
        face.fillColor = SKColor(red: 0.96, green: 0.80, blue: 0.66, alpha: 1.0)
        face.strokeColor = .black
        face.lineWidth = 1.5
        parent.addChild(face)

        // Iconic white hair — wide cap shape.
        let hairBase = SKShapeNode(ellipseOf: CGSize(width: 72, height: 34))
        hairBase.fillColor = SKColor.white
        hairBase.strokeColor = .black
        hairBase.lineWidth = 1.5
        hairBase.position = CGPoint(x: 0, y: 26)
        parent.addChild(hairBase)

        // Hair shadow detail.
        let hairShadow = SKShapeNode(ellipseOf: CGSize(width: 64, height: 16))
        hairShadow.fillColor = SKColor(white: 0.85, alpha: 1.0)
        hairShadow.strokeColor = .clear
        hairShadow.position = CGPoint(x: 0, y: 30)
        parent.addChild(hairShadow)

        // Glasses (rectangular, modern).
        let leftLens = SKShapeNode(rect: CGRect(x: -22, y: -2, width: 16, height: 10), cornerRadius: 2)
        leftLens.fillColor = SKColor(white: 0.95, alpha: 0.85)
        leftLens.strokeColor = .black
        leftLens.lineWidth = 1.5
        parent.addChild(leftLens)

        let rightLens = SKShapeNode(rect: CGRect(x: 6, y: -2, width: 16, height: 10), cornerRadius: 2)
        rightLens.fillColor = SKColor(white: 0.95, alpha: 0.85)
        rightLens.strokeColor = .black
        rightLens.lineWidth = 1.5
        parent.addChild(rightLens)

        // Mouth — neutral talk-show smile.
        let mouth = SKShapeNode(rect: CGRect(x: -8, y: -22, width: 16, height: 4), cornerRadius: 2)
        mouth.fillColor = SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0)
        mouth.strokeColor = .black
        mouth.lineWidth = 1
        parent.addChild(mouth)

        // Navy suit shoulders.
        let suit = SKShapeNode(rect: CGRect(x: -36, y: -54, width: 72, height: 26), cornerRadius: 4)
        suit.fillColor = SKColor(red: 0.10, green: 0.18, blue: 0.32, alpha: 1.0)
        suit.strokeColor = .black
        suit.lineWidth = 1.5
        parent.addChild(suit)

        // Yellow tie (host energy).
        let tie = SKShapeNode(rect: CGRect(x: -4, y: -52, width: 8, height: 22), cornerRadius: 1)
        tie.fillColor = SKColor(red: 0.95, green: 0.80, blue: 0.20, alpha: 1.0)
        tie.strokeColor = .black
        tie.lineWidth = 1
        parent.addChild(tie)
    }

    /// Deadpool — red mask with two large white-rimmed eye patches.
    /// Reads as "guy in a red mask."
    func buildDeadpool(into parent: SKNode) {
        // Mask base — ovoid red.
        let mask = SKShapeNode(ellipseOf: CGSize(width: 64, height: 78))
        mask.fillColor = SKColor(red: 0.85, green: 0.08, blue: 0.10, alpha: 1.0)
        mask.strokeColor = .black
        mask.lineWidth = 2
        parent.addChild(mask)

        // Mask seam center.
        let seam = SKShapeNode(rect: CGRect(x: -1, y: -36, width: 2, height: 72), cornerRadius: 1)
        seam.fillColor = SKColor(red: 0.50, green: 0.04, blue: 0.06, alpha: 1.0)
        seam.strokeColor = .clear
        parent.addChild(seam)

        // Eye patches — almond, black-outlined, white inset.
        let leftEye = SKShapeNode(ellipseOf: CGSize(width: 22, height: 16))
        leftEye.fillColor = .white
        leftEye.strokeColor = .black
        leftEye.lineWidth = 2.5
        leftEye.position = CGPoint(x: -14, y: 6)
        leftEye.zRotation = .pi / 18  // slight tilt
        parent.addChild(leftEye)

        let rightEye = SKShapeNode(ellipseOf: CGSize(width: 22, height: 16))
        rightEye.fillColor = .white
        rightEye.strokeColor = .black
        rightEye.lineWidth = 2.5
        rightEye.position = CGPoint(x: 14, y: 6)
        rightEye.zRotation = -.pi / 18
        parent.addChild(rightEye)

        // Eye dark inner accents — tiny pupils for menace/comedy beat.
        let leftPupil = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        leftPupil.fillColor = .black
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: -16, y: 6)
        parent.addChild(leftPupil)

        let rightPupil = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        rightPupil.fillColor = .black
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 12, y: 6)
        parent.addChild(rightPupil)

        // Katana hilt suggestion peeking from behind shoulder (hint, not literal).
        let hilt = SKShapeNode(rect: CGRect(x: 22, y: -38, width: 6, height: 18), cornerRadius: 1)
        hilt.fillColor = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1.0)
        hilt.strokeColor = .black
        hilt.lineWidth = 1
        hilt.zRotation = .pi / 6
        parent.addChild(hilt)
    }

    /// Generic guest silhouette + initials — used for grievance-specific witnesses
    /// until per-grievance portrait generation is wired in.
    func buildGuestSilhouette(into parent: SKNode, initials: String) {
        // Silhouette head.
        let head = SKShapeNode(ellipseOf: CGSize(width: 58, height: 68))
        head.fillColor = SKColor(red: 0.18, green: 0.32, blue: 0.40, alpha: 1.0)
        head.strokeColor = .white
        head.lineWidth = 1.5
        parent.addChild(head)

        // Shoulders.
        let shoulders = SKShapeNode(rect: CGRect(x: -34, y: -54, width: 68, height: 24), cornerRadius: 4)
        shoulders.fillColor = SKColor(red: 0.10, green: 0.20, blue: 0.28, alpha: 1.0)
        shoulders.strokeColor = .white
        shoulders.lineWidth = 1.5
        parent.addChild(shoulders)

        // Initials.
        let initialsLabel = SKLabelNode(text: initials)
        initialsLabel.fontName = "AvenirNext-Heavy"
        initialsLabel.fontSize = 22
        initialsLabel.fontColor = .white
        initialsLabel.horizontalAlignmentMode = .center
        initialsLabel.verticalAlignmentMode = .center
        parent.addChild(initialsLabel)
    }
}

