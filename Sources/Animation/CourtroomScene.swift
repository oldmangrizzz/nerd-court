import SpriteKit

final class CourtroomScene: SKScene {
    let cinematicEngine = CinematicEngine()
    lazy var finisherAnimator = FinisherAnimator(cinematicEngine: cinematicEngine)
    // Default cinematic frame for SpriteKit overlay
    private var cinematicFrame: CinematicFrame = CinematicFrame(
        cameraAngle: .mediumShot,
        intensity: 0.5,
        colorPalette: [],
        benDayDots: true,
        speedLines: false,
        glitch: false,
        frameRateShift: .normal,
        sting: ""
    )
    
    func updateCinematicFrame(_ frame: CinematicFrame) {
        self.cinematicFrame = frame
    }
    
    private var comicBeatOverlay: ComicBeatOverlay {
        ComicBeatOverlay(cinematicFrame: cinematicFrame)
    }

    // Ambient layers
    private var backgroundLayer: SKNode?
    private var midgroundLayer: SKNode?
    private var characterLayer: SKNode?
    private var fxLayer: SKNode?
    private var bubbleLayer: SKNode?

    // Active comic-panel speech bubble (one at a time, replaces previous).
    private weak var activeBubble: SKNode?

    // Character slot positions (courtroom layout)
    private var characterSlots: [Speaker: CGPoint] = [:]

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.02, blue: 0.08, alpha: 1.0) // deep purple-black
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupLayers()
        setupCamera()
        setupCharacterSlots()
        cinematicEngine.attach(to: self)

        // Start ambient effects
        runAmbientParticles()
    }

    // MARK: - Layer Setup

    private func setupLayers() {
        backgroundLayer = SKNode(); backgroundLayer?.zPosition = -30
        midgroundLayer = SKNode();   midgroundLayer?.zPosition = -10
        characterLayer = SKNode();   characterLayer?.zPosition = 0
        fxLayer = SKNode();          fxLayer?.zPosition = 20
        bubbleLayer = SKNode();      bubbleLayer?.zPosition = 30

        for layer in [backgroundLayer, midgroundLayer, characterLayer, fxLayer, bubbleLayer] {
            if let layer { addChild(layer) }
        }

        buildParallaxBackground()
        buildCourtroomGeometry()
    }

    private func buildParallaxBackground() {
        guard let bg = backgroundLayer else { return }

        // Deep space / comic void gradient
        let gradientSize = CGSize(width: size.width * 2, height: size.height * 2)
        let gradientNode = SKSpriteNode(color: SKColor(red: 0.08, green: 0.03, blue: 0.12, alpha: 1.0),
                                          size: gradientSize)
        gradientNode.position = .zero
        bg.addChild(gradientNode)

        // Subtle grid lines (comic book panel gutters)
        let gridSpacing: CGFloat = 60
        for x in stride(from: -size.width, through: size.width, by: gridSpacing) {
            let line = SKShapeNode(rect: CGRect(x: x, y: -size.height, width: 0.5, height: size.height * 2))
            line.fillColor = .white.withAlphaComponent(0.03)
            line.strokeColor = .clear
            bg.addChild(line)
        }
        for y in stride(from: -size.height, through: size.height, by: gridSpacing) {
            let line = SKShapeNode(rect: CGRect(x: -size.width, y: y, width: size.width * 2, height: 0.5))
            line.fillColor = .white.withAlphaComponent(0.03)
            line.strokeColor = .clear
            bg.addChild(line)
        }
    }

    private func setupCamera() {
        let cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }

    private func setupCharacterSlots() {
        // Courtroom layout: 4 positions
        let midY: CGFloat = 0
        characterSlots = [
            .jasonTodd:  CGPoint(x: -size.width * 0.25, y: midY + 40),
            .mattMurdock: CGPoint(x: size.width * 0.25, y: midY + 40),
            .judgeJerry:  CGPoint(x: 0, y: size.height * 0.3),
            .deadpool:    CGPoint(x: size.width * 0.35, y: midY - 100),
        ]
    }

    // MARK: - Ambient Effects

    private func runAmbientParticles() {
        guard let fx = fxLayer else { return }

        // Floating dust / comic ink motes
        let moteEmitter = SKEmitterNode()
        moteEmitter.particleBirthRate = 8
        moteEmitter.particleLifetime = 8
        moteEmitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        moteEmitter.position = .zero
        moteEmitter.particleAlpha = 0.15
        moteEmitter.particleAlphaSpeed = -0.02
        moteEmitter.particleScale = 0.1
        moteEmitter.particleScaleSpeed = 0.02
        moteEmitter.particleSpeed = 5
        moteEmitter.particleColor = .white
        moteEmitter.particleColorBlendFactor = 0.4
        moteEmitter.particleBlendMode = .add
        moteEmitter.particleTexture = buildMoteTexture()
        fx.addChild(moteEmitter)
    }

    private func buildMoteTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return SKTexture(image: image ?? UIImage())
    }

    // MARK: - Public API

    func showCharacter(_ speaker: Speaker, emotion: String = "neutral") {
        highlightSpeaker(speaker)
        addCharacterSprite(for: speaker)
    }

    // MARK: - Highlight Speaker

    func highlightSpeaker(_ speaker: Speaker) {
        guard let slot = characterSlots[speaker] else { return }

        // 1. Pan camera toward that character's slot
        if let cam = camera {
            let target = CGPoint(x: slot.x * 0.15, y: slot.y * 0.1)
            let pan = SKAction.move(to: target, duration: 0.4)
            pan.timingMode = .easeInEaseOut
            cam.run(pan)
        }

        // 2. Comic panel effect on that slot
        cinematicEngine.triggerEffect(.comicPanel, duration: 0.3)

        // 3. Pulsing glow on that character's portrait
        if let existing = characterLayer?.children.first(where: { $0.name == speaker.avatarID }) as? CharacterPortraitNode {
            existing.setActive(true)
            // Auto-deactivate others
            characterLayer?.children.compactMap { $0 as? CharacterPortraitNode }.forEach { node in
                if node.name != speaker.avatarID {
                    node.setActive(false)
                }
            }
        }

        // 4. Speed lines if it's Jason or cross-examination phase
        if speaker == .jasonTodd || speaker == .mattMurdock {
            cinematicEngine.triggerEffect(.speedLines, duration: 0.5, intensity: 0.5)
        }
    }

    private func addCharacterSprite(for speaker: Speaker) {
        guard let characterLayer else { return }
        let slot = characterSlots[speaker] ?? .zero

        // Remove any previous portrait for this speaker
        characterLayer.children.filter { $0.name == speaker.avatarID }.forEach { $0.removeFromParent() }

        let portrait = CharacterPortraitNode.create(for: speaker, isActive: false)
        portrait.position = slot
        portrait.playAppearAnimation()
        characterLayer.addChild(portrait)
    }

    func transitionToPhase(_ phase: DebatePhase) {
        cinematicEngine.triggerEffect(.comicPanel, duration: 0.0, intensity: 1.0)

        switch phase {
        case .openingStatement:
            cinematicEngine.triggerEffect(.benDayDots, duration: 0.5, intensity: 0.4)
            cinematicEngine.triggerEffect(.comicPanel, duration: 0.4)
            cinematicEngine.triggerEffect(.dramaticZoom, duration: 0.8, intensity: 0.2)
            // Medium shot pan + character appear animation handled by showCharacter calls
        case .witnessTestimony:
            cinematicEngine.triggerEffect(.dramaticZoom, duration: 0.6, intensity: 0.35)
            cinematicEngine.triggerEffect(.benDayDots, duration: 0.3, intensity: 0.25)
            // Close-up zoom on witness + soft glow handled by highlightSpeaker
        case .crossExamination:
            cinematicEngine.triggerEffect(.speedLines, duration: 0.6, intensity: 0.5)
            cinematicEngine.triggerEffect(.chromaticAberration, duration: 0.5)
            // Over-shoulder angle handled by camera pan in highlightSpeaker
        case .closingArguments:
            cinematicEngine.triggerEffect(.benDayDots, duration: 0.5, intensity: 0.4)
            cinematicEngine.triggerEffect(.comicPanel, duration: 0.4)
            cinematicEngine.triggerEffect(.dramaticZoom, duration: 0.6, intensity: 0.2)
            // Wide shot + both lawyers visible + dramatic lighting
            resetCamera()
            camera?.run(SKAction.scale(to: 0.9, duration: 0.5))
        case .verdictAnnouncement:
            cinematicEngine.triggerEffect(.dramaticZoom, duration: 1.0, intensity: 0.4)
            cinematicEngine.triggerEffect(.cameraShake, duration: 0.3, intensity: 0.5)
            cinematicEngine.triggerEffect(.impactFlash, duration: 0.2)
            // Low angle on Jerry + dramatic zoom + impact sting
            if let jerrySlot = characterSlots[.judgeJerry], let cam = camera {
                let target = CGPoint(x: jerrySlot.x * 0.15, y: (jerrySlot.y - 40) * 0.1)
                let pan = SKAction.move(to: target, duration: 0.5)
                pan.timingMode = .easeInEaseOut
                cam.run(pan)
                cam.run(SKAction.scale(to: 1.15, duration: 0.5))
            }
        case .finisherExecution:
            cinematicEngine.triggerEffect(.vignettePulse, duration: 0.6)
            cinematicEngine.triggerEffect(.speedLines, duration: 1.0, intensity: 1.0)
            cinematicEngine.triggerEffect(.cameraShake, duration: 0.8, intensity: 1.5)
            cinematicEngine.triggerEffect(.colorShift, duration: 2.0)
            cinematicEngine.triggerEffect(.chromaticAberration, duration: 1.0)
            // Dutch angle + red color shift + heavy speed lines + impact flash + vignette pulse
            camera?.run(SKAction.rotate(byAngle: .pi / 24, duration: 0.3))
        case .deadpoolWrapUp:
            cinematicEngine.triggerEffect(.glitch, duration: 0.6)
            cinematicEngine.triggerEffect(.frameRateShift, duration: 0.5)
            // Glitch + frame rate stutter + pov angle
            if let deadpoolSlot = characterSlots[.deadpool], let cam = camera {
                let target = CGPoint(x: deadpoolSlot.x * 0.2, y: deadpoolSlot.y * 0.15)
                let pan = SKAction.move(to: target, duration: 0.3)
                pan.timingMode = .easeOut
                cam.run(pan)
            }
        default:
            cinematicEngine.triggerEffect(.benDayDots, duration: 0.4, intensity: 0.3)
        }
    }

    func resetCamera() {
        camera?.run(SKAction.move(to: .zero, duration: 0.5))
    }

    func cleanup() {
        cinematicEngine.clearOverlays()
        resetCamera()
        removeAllActions()
        physicsWorld.speed = 1.0
    }

    // MARK: - Courtroom Geometry (Spider-Verse stylized)

    /// Builds the static courtroom set: judge's bench (Jerry's elevated platform),
    /// counsel podiums for prosecution / defense, witness stand, jury box, and
    /// gallery silhouettes. Stylized — bold ink outlines, flat color fills, no
    /// gradients or photoreal textures, per the comic-panel aesthetic.
    private func buildCourtroomGeometry() {
        guard let mid = midgroundLayer else { return }

        let w = size.width
        let h = size.height
        let floorY = -h * 0.45
        let ink = SKColor.black.withAlphaComponent(0.92)

        // Floor — single dark band with ink horizon.
        let floor = SKShapeNode(rect: CGRect(x: -w, y: floorY - h, width: w * 2, height: h))
        floor.fillColor = SKColor(red: 0.12, green: 0.07, blue: 0.18, alpha: 1.0)
        floor.strokeColor = .clear
        floor.zPosition = -1
        mid.addChild(floor)

        let horizon = SKShapeNode(rect: CGRect(x: -w, y: floorY, width: w * 2, height: 2))
        horizon.fillColor = ink; horizon.strokeColor = .clear
        mid.addChild(horizon)

        // Back wall — comic-panel slats.
        for i in 0..<8 {
            let slatX = -w * 0.5 + CGFloat(i) * (w / 8)
            let slat = SKShapeNode(rect: CGRect(x: slatX, y: floorY, width: 2, height: h * 0.55))
            slat.fillColor = SKColor.white.withAlphaComponent(0.05)
            slat.strokeColor = .clear
            mid.addChild(slat)
        }

        // Judge's bench — elevated platform with raised desk in front.
        let benchY = h * 0.18
        let benchTop = SKShapeNode(rect: CGRect(x: -w * 0.20, y: benchY, width: w * 0.40, height: 14), cornerRadius: 3)
        benchTop.fillColor = SKColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1.0)
        benchTop.strokeColor = ink; benchTop.lineWidth = 2.5
        mid.addChild(benchTop)

        let benchFront = SKShapeNode(rect: CGRect(x: -w * 0.22, y: benchY - 90, width: w * 0.44, height: 90), cornerRadius: 4)
        benchFront.fillColor = SKColor(red: 0.22, green: 0.13, blue: 0.08, alpha: 1.0)
        benchFront.strokeColor = ink; benchFront.lineWidth = 2.5
        mid.addChild(benchFront)

        // Bench wood grain — three vertical ink strokes for comic shorthand.
        for offset in [-w * 0.10, CGFloat(0), w * 0.10] {
            let grain = SKShapeNode(rect: CGRect(x: offset - 1, y: benchY - 80, width: 2, height: 70))
            grain.fillColor = SKColor.black.withAlphaComponent(0.55)
            grain.strokeColor = .clear
            mid.addChild(grain)
        }

        // Court seal hanging behind/above the bench.
        let seal = SKShapeNode(circleOfRadius: 32)
        seal.position = CGPoint(x: 0, y: benchY + 90)
        seal.fillColor = SKColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 1.0)
        seal.strokeColor = SKColor.white; seal.lineWidth = 3
        seal.glowWidth = 4
        mid.addChild(seal)

        let sealLabel = SKLabelNode(text: "NC")
        sealLabel.fontName = "AvenirNext-Heavy"
        sealLabel.fontSize = 22
        sealLabel.fontColor = .white
        sealLabel.horizontalAlignmentMode = .center
        sealLabel.verticalAlignmentMode = .center
        sealLabel.position = seal.position
        mid.addChild(sealLabel)

        // Counsel podiums — left (prosecution / Jason) and right (defense / Matt).
        addPodium(into: mid, centerX: -w * 0.25, baseY: floorY, accent: .systemRed)
        addPodium(into: mid, centerX:  w * 0.25, baseY: floorY, accent: .systemBlue)

        // Witness stand — small box to the front-right of the bench.
        let standX = -w * 0.04
        let standY = benchY - 130
        let stand = SKShapeNode(rect: CGRect(x: standX, y: standY, width: 80, height: 50), cornerRadius: 4)
        stand.fillColor = SKColor(red: 0.28, green: 0.16, blue: 0.10, alpha: 1.0)
        stand.strokeColor = ink; stand.lineWidth = 2.0
        mid.addChild(stand)
        let standRail = SKShapeNode(rect: CGRect(x: standX, y: standY + 50, width: 80, height: 4))
        standRail.fillColor = ink; standRail.strokeColor = .clear
        mid.addChild(standRail)

        // Jury box — six silhouette heads behind a low rail, far right.
        let juryX = w * 0.40
        let juryY = floorY + 60
        let juryRail = SKShapeNode(rect: CGRect(x: juryX - 70, y: juryY, width: 140, height: 6))
        juryRail.fillColor = SKColor(red: 0.25, green: 0.15, blue: 0.08, alpha: 1.0)
        juryRail.strokeColor = ink; juryRail.lineWidth = 1.5
        mid.addChild(juryRail)
        for col in 0..<3 {
            for row in 0..<2 {
                let head = SKShapeNode(circleOfRadius: 8)
                head.fillColor = SKColor(white: 0.18 + CGFloat(col) * 0.04, alpha: 1.0)
                head.strokeColor = ink; head.lineWidth = 1.0
                head.position = CGPoint(
                    x: juryX - 55 + CGFloat(col) * 50,
                    y: juryY + 14 + CGFloat(row) * 14
                )
                mid.addChild(head)
            }
        }
        let juryLabel = SKLabelNode(text: "JURY")
        juryLabel.fontName = "AvenirNext-Heavy"
        juryLabel.fontSize = 9
        juryLabel.fontColor = .white.withAlphaComponent(0.65)
        juryLabel.position = CGPoint(x: juryX, y: juryY - 14)
        mid.addChild(juryLabel)

        // Gallery — silhouette crowd row across the bottom front.
        for i in 0..<14 {
            let gx = -w * 0.5 + CGFloat(i) * (w / 14) + CGFloat.random(in: -6...6)
            let head = SKShapeNode(circleOfRadius: 7 + CGFloat.random(in: -1...2))
            head.fillColor = SKColor(white: 0.06, alpha: 1.0)
            head.strokeColor = SKColor(white: 0.0, alpha: 1.0)
            head.lineWidth = 1.0
            head.position = CGPoint(x: gx, y: floorY - 40)
            mid.addChild(head)

            let shoulders = SKShapeNode(rect: CGRect(x: gx - 12, y: floorY - 60, width: 24, height: 18), cornerRadius: 3)
            shoulders.fillColor = SKColor(white: 0.04, alpha: 1.0)
            shoulders.strokeColor = SKColor(white: 0.0, alpha: 1.0)
            shoulders.lineWidth = 1.0
            mid.addChild(shoulders)
        }

        // Comic-panel border — thin ink rectangle around the whole stage.
        let border = SKShapeNode(rect: CGRect(x: -w * 0.5 + 8, y: -h * 0.5 + 8, width: w - 16, height: h - 16))
        border.fillColor = .clear
        border.strokeColor = ink
        border.lineWidth = 4
        border.zPosition = 25
        mid.addChild(border)
    }

    private func addPodium(into parent: SKNode, centerX: CGFloat, baseY: CGFloat, accent: SKColor) {
        let ink = SKColor.black.withAlphaComponent(0.92)
        let body = SKShapeNode(rect: CGRect(x: centerX - 50, y: baseY + 40, width: 100, height: 70), cornerRadius: 5)
        body.fillColor = SKColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1.0)
        body.strokeColor = ink; body.lineWidth = 2.5
        parent.addChild(body)

        let topPlate = SKShapeNode(rect: CGRect(x: centerX - 56, y: baseY + 108, width: 112, height: 8), cornerRadius: 2)
        topPlate.fillColor = SKColor(red: 0.42, green: 0.26, blue: 0.14, alpha: 1.0)
        topPlate.strokeColor = ink; topPlate.lineWidth = 2.0
        parent.addChild(topPlate)

        let stripe = SKShapeNode(rect: CGRect(x: centerX - 40, y: baseY + 60, width: 80, height: 6), cornerRadius: 1)
        stripe.fillColor = accent
        stripe.strokeColor = ink; stripe.lineWidth = 1.5
        parent.addChild(stripe)
    }

    // MARK: - Comic-panel Speech Bubbles (SpriteKit, character-tinted, typewriter)

    /// Shows a comic-panel speech bubble pinned to the speaker's portrait.
    /// Text animates in character-by-character (typewriter) tinted to the speaker.
    /// Replaces any active bubble. `duration` is how long the bubble stays after
    /// the text finishes typing; pass nil to leave it up until the next call.
    func showSpeechBubble(text: String,
                          for speaker: Speaker,
                          duration: TimeInterval? = nil,
                          typingCharsPerSecond: Double = 28.0) {
        guard let bubbleLayer else { return }

        // Replace prior bubble with a quick fade.
        if let prior = activeBubble {
            prior.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.12),
                SKAction.removeFromParent()
            ]))
            activeBubble = nil
        }

        let slot = characterSlots[speaker] ?? .zero
        let onLeft = slot.x < 0
        let tint = PortraitPalette.tint(for: speaker)
        let bubble = ComicSpeechBubble.build(text: text, tint: tint, leadingTail: onLeft, maxWidth: min(size.width * 0.42, 320))

        // Anchor bubble above the portrait, offset toward screen center so it
        // doesn't wander off the edges. Tail points back at the speaker.
        let bubbleX = slot.x + (onLeft ? bubble.size.width * 0.30 : -bubble.size.width * 0.30)
        let bubbleY = slot.y + 110
        bubble.node.position = CGPoint(x: bubbleX, y: bubbleY)
        bubble.node.alpha = 0
        bubble.node.setScale(0.6)
        bubbleLayer.addChild(bubble.node)
        activeBubble = bubble.node

        // Pop-in: scale + fade.
        let pop = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.18)
        ])
        pop.timingMode = .easeOut
        bubble.node.run(pop)

        // Typewriter: reveal characters by mutating the underlying label.
        bubble.startTyping(charsPerSecond: typingCharsPerSecond)

        // Optional auto-dismiss.
        if let duration {
            let totalTypingTime = Double(text.count) / max(1.0, typingCharsPerSecond)
            let hold = SKAction.wait(forDuration: max(0.0, duration) + totalTypingTime)
            let fade = SKAction.fadeOut(withDuration: 0.18)
            let kill = SKAction.removeFromParent()
            bubble.node.run(SKAction.sequence([hold, fade, kill])) { [weak self] in
                if self?.activeBubble === bubble.node { self?.activeBubble = nil }
            }
        }
    }

    /// Clears any visible speech bubble immediately.
    func clearSpeechBubble() {
        guard let prior = activeBubble else { return }
        prior.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.12),
            SKAction.removeFromParent()
        ]))
        activeBubble = nil
    }
}

// MARK: - ComicSpeechBubble (SpriteKit comic balloon w/ typewriter)

/// A SpriteKit comic-style speech bubble: rounded rectangle + tail, ink outline,
/// soft white fill, character-tinted text rendered with `AvenirNextCondensed-Heavy`,
/// revealed character-by-character.
@MainActor
final class ComicSpeechBubble {
    let node: SKNode
    let size: CGSize
    private let label: SKLabelNode
    private let fullText: String

    init(node: SKNode, size: CGSize, label: SKLabelNode, fullText: String) {
        self.node = node
        self.size = size
        self.label = label
        self.fullText = fullText
    }

    static func build(text: String, tint: SKColor, leadingTail: Bool, maxWidth: CGFloat) -> ComicSpeechBubble {
        let container = SKNode()

        // Wrap text via SKLabelNode multiline. Estimate height from char count.
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        label.fontSize = 16
        label.fontColor = tint
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = maxWidth - 28
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.text = "" // typewriter starts empty

        // Estimate visible bubble bounds from the *full* text so the balloon
        // doesn't grow during typing.
        let probe = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        probe.fontSize = 16
        probe.numberOfLines = 0
        probe.preferredMaxLayoutWidth = maxWidth - 28
        probe.horizontalAlignmentMode = .center
        probe.verticalAlignmentMode = .center
        probe.text = text
        let probeBounds = probe.calculateAccumulatedFrame()
        let textW = max(80, min(maxWidth - 28, probeBounds.width))
        let textH = max(24, probeBounds.height)
        let bubbleSize = CGSize(width: textW + 28, height: textH + 24)

        // Bubble body — rounded rect, white fill, ink stroke.
        let body = SKShapeNode(rectOf: bubbleSize, cornerRadius: 14)
        body.fillColor = .white
        body.strokeColor = SKColor.black.withAlphaComponent(0.92)
        body.lineWidth = 2.5
        body.glowWidth = 0
        container.addChild(body)

        // Inner tinted accent — thin colored line just inside the ink stroke.
        let accent = SKShapeNode(rectOf: CGSize(width: bubbleSize.width - 6, height: bubbleSize.height - 6), cornerRadius: 12)
        accent.fillColor = .clear
        accent.strokeColor = tint.withAlphaComponent(0.55)
        accent.lineWidth = 1.5
        container.addChild(accent)

        // Tail — small triangle pointing toward the speaker.
        let tailPath = UIBezierPath()
        let tailY = -bubbleSize.height / 2 + 2
        let tailX: CGFloat = leadingTail ? -bubbleSize.width / 2 + 30 : bubbleSize.width / 2 - 30
        let tipX: CGFloat = leadingTail ? tailX - 18 : tailX + 18
        let tipY: CGFloat = tailY - 18
        tailPath.move(to: CGPoint(x: tailX - 8, y: tailY))
        tailPath.addLine(to: CGPoint(x: tipX, y: tipY))
        tailPath.addLine(to: CGPoint(x: tailX + 8, y: tailY))
        tailPath.close()
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.fillColor = .white
        tail.strokeColor = SKColor.black.withAlphaComponent(0.92)
        tail.lineWidth = 2.5
        container.addChild(tail)

        // Position label centered.
        label.position = .zero
        container.addChild(label)

        return ComicSpeechBubble(node: container, size: bubbleSize, label: label, fullText: text)
    }

    /// Reveal the text one character at a time via SKAction sequence on the label.
    func startTyping(charsPerSecond: Double) {
        let chars = Array(fullText)
        guard !chars.isEmpty else { return }
        let interval = 1.0 / max(1.0, charsPerSecond)
        var actions: [SKAction] = []
        for i in 1...chars.count {
            let revealed = String(chars.prefix(i))
            let set = SKAction.run { [weak label] in label?.text = revealed }
            actions.append(set)
            if i < chars.count { actions.append(SKAction.wait(forDuration: interval)) }
        }
        label.run(SKAction.sequence(actions), withKey: "typing")
    }
}
