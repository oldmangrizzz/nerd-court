import Foundation

/// Camera angle for the cinematic frame.
public enum CameraAngle: String, Codable, Equatable, Hashable, Sendable {
    case lowAngle
    case highAngle
    case dutchAngle
    case closeUp
    case mediumShot
    case wideShot
    case overShoulder
    case pov
    case birdsEye
    case wormsEye
}

/// Frame rate shift applied to the cinematic frame.
public enum FrameRateShift: String, Codable, Equatable, Hashable, Sendable {
    case normal
    case slowMotion
    case fastMotion
    case stutter
    case freezeFrame
}

/// Per-turn visual parameters that define the cinematic presentation of a speech turn.
public struct CinematicFrame: Codable, Equatable, Hashable, Sendable {
    /// The camera angle for this frame.
    public let cameraAngle: CameraAngle
    
    /// Intensity of the scene, from 0 (calm) to 1 (maximum drama).
    public let intensity: Double
    
    /// Hex color palette for the frame's visual style.
    public let colorPalette: [String]
    
    /// Whether to apply Ben-Day dots (comic book style).
    public let benDayDots: Bool
    
    /// Whether to show speed lines.
    public let speedLines: Bool
    
    /// Whether to apply a reality-breaking glitch effect (Deadpool special).
    public let glitch: Bool
    
    /// Frame rate shift for this turn.
    public let frameRateShift: FrameRateShift
    
    /// Audio accent cue identifier (e.g., "dramatic-sting-01").
    public let sting: String
    
    public init(
        cameraAngle: CameraAngle,
        intensity: Double,
        colorPalette: [String],
        benDayDots: Bool,
        speedLines: Bool,
        glitch: Bool,
        frameRateShift: FrameRateShift,
        sting: String
    ) {
        self.cameraAngle = cameraAngle
        self.intensity = min(max(intensity, 0), 1)
        self.colorPalette = colorPalette
        self.benDayDots = benDayDots
        self.speedLines = speedLines
        self.glitch = glitch
        self.frameRateShift = frameRateShift
        self.sting = sting
    }
}