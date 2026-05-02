import SpriteKit
import UIKit

// MARK: - SpiderVerseEffects

/// Applies comic-book visual effects to a SpriteKit scene based on a CinematicFrame.
@MainActor
final class SpiderVerseEffects {
    
    /// Apply all effects described by the frame for a given duration.
    /// - Parameters:
    ///   - frame: The cinematic frame specifying which effects to use.
    ///   - scene: The SpriteKit scene to modify.
    ///   - duration: How long the effects should remain active (seconds).
    static func apply(frame: CinematicFrame, to scene: SKScene, duration: TimeInterval) async {
        // Save original state to restore later
        let originalSpeed = scene.speed
        let originalPhysicsSpeed = scene.physicsWorld.speed
        var originalCameraPosition: CGPoint?
        var originalCameraRotation: CGFloat = 0
        if let camera = scene.camera {
            originalCameraPosition = camera.position
            originalCameraRotation = camera.zRotation
        }
        
        // Root node for all temporary effect nodes
        let effectNode = SKNode()
        effectNode.zPosition = 1000
        scene.addChild(effectNode)
        
        // Apply each effect based on frame properties
        if frame.benDayDots {
            addBenDayDots(to: effectNode, intensity: frame.intensity, palette: frame.colorPalette)
        }
        if frame.speedLines {
            addSpeedLines(to: effectNode, intensity: frame.intensity)
        }
        if frame.glitch {
            addGlitch(to: effectNode, intensity: frame.intensity)
        }
        applyCameraAngle(frame.cameraAngle, to: scene.camera)
        applyFrameRateShift(frame.frameRateShift, scene: scene)
        applyColorPalette(frame.colorPalette, to: effectNode, intensity: frame.intensity)
        
        // Wait for the specified duration
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        // Cleanup: remove all effect nodes and restore original scene state
        effectNode.removeFromParent()
        scene.speed = originalSpeed
        scene.physicsWorld.speed = originalPhysicsSpeed
        if let camera = scene.camera, let originalPos = originalCameraPosition {
            camera.position = originalPos
            camera.zRotation = originalCameraRotation
        }
    }
    
    // MARK: - Private Effect Methods
    
    /// Adds a Ben-Day dots overlay.
    private static func addBenDayDots(to parent: SKNode, intensity: Double, palette: [String]) {
        guard let scene = parent.scene else { return }
        let size = scene.size
        
        // Generate dot pattern texture
        let dotTexture = generateBenDayDotTexture(
            size: size,
            dotRadius: CGFloat(2.0 + intensity * 4.0),
            spacing: CGFloat(8.0 + (1.0 - intensity) * 8.0),
            color: UIColor(hex: palette.first ?? "#000000") ?? .black
        )
        
        let dotsNode = SKSpriteNode(texture: dotTexture, size: size)
        dotsNode.alpha = CGFloat(intensity * 0.6)
        dotsNode.blendMode = .multiply
        dotsNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        parent.addChild(dotsNode)
    }
    
    /// Adds animated speed lines.
    private static func addSpeedLines(to parent: SKNode, intensity: Double) {
        guard let scene = parent.scene else { return }
        let size = scene.size
        let lineCount = Int(5 + intensity * 15)
        
        for _ in 0..<lineCount {
            let line = SKSpriteNode(color: .white, size: CGSize(width: 2, height: CGFloat.random(in: 20...80)))
            line.alpha = CGFloat.random(in: 0.3...0.8) * CGFloat(intensity)
            line.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            line.zRotation = CGFloat.random(in: -0.2...0.2)
            parent.addChild(line)
            
            let moveAction = SKAction.moveBy(
                x: CGFloat.random(in: -size.width...size.width) * CGFloat(intensity),
                y: CGFloat.random(in: -size.height...size.height) * CGFloat(intensity),
                duration: TimeInterval(0.5 + Double.random(in: 0...1.0) / intensity)
            )
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let remove = SKAction.removeFromParent()
            line.run(SKAction.sequence([moveAction, fadeOut, remove]))
        }
    }
    
    /// Adds a glitch effect using rapid random transformations.
    private static func addGlitch(to parent: SKNode, intensity: Double) {
        guard let scene = parent.scene else { return }
        let size = scene.size
        
        let glitchNode = SKSpriteNode(color: .magenta, size: size)
        glitchNode.alpha = 0.0
        glitchNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        glitchNode.blendMode = .screen
        parent.addChild(glitchNode)
        
        let glitchAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run {
                    glitchNode.alpha = CGFloat.random(in: 0.0...0.3) * CGFloat(intensity)
                    glitchNode.position = CGPoint(
                        x: size.width / 2 + CGFloat.random(in: -20...20) * CGFloat(intensity),
                        y: size.height / 2 + CGFloat.random(in: -20...20) * CGFloat(intensity)
                    )
                },
                SKAction.wait(forDuration: 0.05 / max(intensity, 0.1)),
                SKAction.run {
                    glitchNode.alpha = 0.0
                },
                SKAction.wait(forDuration: 0.1 / max(intensity, 0.1))
            ])
        )
        glitchNode.run(glitchAction)
    }
    
    /// Simulates a camera angle by transforming the scene's camera.
    /// Note: Some cases map from the main CinematicFrame CameraAngle to sprite-kit-friendly transforms.
    private static func applyCameraAngle(_ angle: CameraAngle, to camera: SKCameraNode?) {
        guard let camera = camera else { return }
        switch angle {
        case .closeUp:
            camera.setScale(1.5)
        case .mediumShot:
            camera.setScale(1.0)
        case .wideShot:
            camera.setScale(0.7)
        case .dutchAngle:
            camera.zRotation = CGFloat.pi / 12
        case .lowAngle, .wormsEye:
            camera.position = CGPoint(x: camera.position.x, y: camera.position.y - 150)
        case .highAngle, .birdsEye, .overShoulder:
            camera.position = CGPoint(x: camera.position.x, y: camera.position.y + 200)
        case .pov:
            camera.setScale(1.2)
        case .wormsEye:
            camera.position = CGPoint(x: camera.position.x, y: camera.position.y - 200)
        }
    }
    
    /// Adjusts the scene's speed to simulate frame rate shifts.
    /// Maps from CinematicFrame FrameRateShift to SpriteKit scene speed.
    private static func applyFrameRateShift(_ shift: FrameRateShift, scene: SKScene) {
        switch shift {
        case .normal:
            scene.speed = 1.0
            scene.physicsWorld.speed = 1.0
        case .slowMotion:
            scene.speed = 0.3
            scene.physicsWorld.speed = 0.3
        case .fastMotion:
            scene.speed = 2.0
            scene.physicsWorld.speed = 2.0
        case .freezeFrame:
            scene.speed = 0.0
            scene.physicsWorld.speed = 0.0
        case .stutter:
            // Stutter: rapid frame toggling approximated by slowing significantly
            scene.speed = 0.1
            scene.physicsWorld.speed = 0.1
        }
    }
    
    /// Applies a color palette as a tinted overlay.
    private static func applyColorPalette(_ palette: [String], to parent: SKNode, intensity: Double) {
        guard let scene = parent.scene, let firstColor = palette.first else { return }
        let size = scene.size
        
        let colorNode = SKSpriteNode(color: UIColor(hex: firstColor) ?? .white, size: size)
        colorNode.alpha = CGFloat(intensity * 0.3)
        colorNode.blendMode = .alpha
        colorNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        parent.addChild(colorNode)
    }
    
    // MARK: - Texture Generation
    
    /// Creates a Ben-Day dot pattern texture.
    private static func generateBenDayDotTexture(
        size: CGSize,
        dotRadius: CGFloat,
        spacing: CGFloat,
        color: UIColor
    ) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            let step = spacing + dotRadius * 2
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let dotRect = CGRect(x: x, y: y, width: dotRadius * 2, height: dotRadius * 2)
                    ctx.cgContext.fillEllipse(in: dotRect)
                    x += step
                }
                y += step
            }
        }
        return SKTexture(image: image)
    }
}

// MARK: - UIColor Hex Helper

private extension UIColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6 else { return nil }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}