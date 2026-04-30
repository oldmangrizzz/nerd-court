import SpriteKit

final class CourtroomScene: SKScene {
    let cinematicEngine = CinematicEngine()
    let comicBeatOverlay = ComicBeatOverlay()

    // Ambient layers
    private var backgroundLayer: SKNode?
    private var midgroundLayer: SKNode?
    private var characterLayer: SKNode?
    private var fxLayer: SKNode?

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

        for layer in [backgroundLayer, midgroundLayer, characterLayer, fxLayer] {
            if let layer { addChild(layer) }
        }

        buildParallaxBackground()
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
        cinematicEngine.triggerEffect(.comicPanel, duration: 0.3)

        // Pan camera toward speaking character
        if let slot = characterSlots[speaker], let cam = camera {
            let target = CGPoint(x: slot.x * 0.15, y: slot.y * 0.1)
            let pan = SKAction.move(to: target, duration: 0.4)
            pan.timingMode = .easeInEaseOut
            cam.run(pan)
        }
    }

    func transitionToPhase(_ phase: DebatePhase) {
        cinematicEngine.triggerEffect(.comicPanel, duration: 0.0, intensity: 1.0)

        switch phase {
        case .finisherExecution:
            cinematicEngine.triggerEffect(.vignettePulse, duration: 0.6)
            cinematicEngine.triggerEffect(.speedLines, duration: 1.0, intensity: 1.0)
            cinematicEngine.triggerEffect(.cameraShake, duration: 0.8, intensity: 1.5)
            cinematicEngine.triggerEffect(.colorShift, duration: 2.0)
            cinematicEngine.triggerEffect(.chromaticAberration, duration: 1.0)
        case .verdictAnnouncement:
            cinematicEngine.triggerEffect(.dramaticZoom, duration: 1.0, intensity: 0.4)
            cinematicEngine.triggerEffect(.cameraShake, duration: 0.3, intensity: 0.5)
            cinematicEngine.triggerEffect(.impactFlash, duration: 0.2)
        case .openingStatement, .closingArguments:
            cinematicEngine.triggerEffect(.benDayDots, duration: 0.5, intensity: 0.4)
            cinematicEngine.triggerEffect(.comicPanel, duration: 0.4)
        case .crossExamination:
            cinematicEngine.triggerEffect(.speedLines, duration: 0.4, intensity: 0.3)
        case .deadpoolWrapUp:
            cinematicEngine.triggerEffect(.glitch, duration: 0.6)
            cinematicEngine.triggerEffect(.frameRateShift, duration: 0.5)
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
}
