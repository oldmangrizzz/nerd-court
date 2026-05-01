import Foundation
import RealityKit

/// Represents the camera angle for cinematic framing.
/// Defined in sibling file; used here for dynamic camera control.
/// enum CameraAngle { ... }

/// Dynamic camera controller for Phase 2 3D courtroom scenes.
/// Manages a RealityKit camera entity and applies cinematic framing
/// based on `CinematicFrame` data, animating transitions smoothly.
@MainActor
@Observable
final class CameraController {
    /// The RealityKit camera entity being controlled.
    private(set) var cameraEntity: Entity?

    /// Current camera angle, updated after each transition.
    private(set) var currentAngle: CameraAngle = .wideShot

    /// Current intensity (0–1), affecting field of view or depth of field.
    private(set) var currentIntensity: Double = 0.5

    /// Default transform for resetting.
    private var defaultTransform: Transform = .identity

    /// Sets up the camera in the given RealityKit scene.
    /// - Parameter scene: The RealityKit scene to add the camera to.
    /// - Returns: The created camera entity.
    @discardableResult
    func setupCamera(in scene: RealityKit.Scene) -> Entity {
        let camera = PerspectiveCamera()
        cameraEntity = camera
        // Position camera at a default wide shot location
        camera.transform = Transform(
            scale: .one,
            rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
            translation: [0, 1.5, 5]
        )
        defaultTransform = camera.transform
        scene.addAnchor(camera)
        return camera
    }

    /// Applies a cinematic frame to the camera, animating to the new angle and intensity.
    /// - Parameters:
    ///   - frame: The cinematic frame describing desired camera settings.
    ///   - duration: Animation duration in seconds.
    func applyFrame(_ frame: CinematicFrame, duration: TimeInterval = 0.5) async {
        guard let camera = cameraEntity else {
            preconditionFailure("Camera not set up. Call setupCamera(in:) first.")
        }

        let targetTransform = transform(for: frame.cameraAngle, intensity: frame.intensity)
        let targetIntensity = frame.intensity

        // Animate camera transform
        await withCheckedContinuation { continuation in
            camera.move(
                to: targetTransform,
                relativeTo: camera.parent,
                duration: duration,
                timingFunction: .easeInOut
            ).completionHandler = { _ in
                continuation.resume()
            }
        }

        // Update observable state
        currentAngle = frame.cameraAngle
        currentIntensity = targetIntensity

        // Additional cinematic effects (e.g., depth of field) could be applied here
        // using intensity to adjust camera parameters.
        applyDepthOfField(intensity: targetIntensity)
    }

    /// Resets the camera to its default wide shot.
    func resetToDefault(duration: TimeInterval = 0.3) async {
        guard let camera = cameraEntity else { return }
        await withCheckedContinuation { continuation in
            camera.move(
                to: defaultTransform,
                relativeTo: camera.parent,
                duration: duration,
                timingFunction: .easeInOut
            ).completionHandler = { _ in
                continuation.resume()
            }
        }
        currentAngle = .wideShot
        currentIntensity = 0.5
        applyDepthOfField(intensity: 0.5)
    }

    // MARK: - Private Helpers

    /// Calculates the RealityKit Transform for a given camera angle and intensity.
    private func transform(for angle: CameraAngle, intensity: Double) -> Transform {
        // Base position and rotation based on angle
        let basePosition: SIMD3<Float>
        let baseRotation: simd_quatf

        switch angle {
        case .wideShot:
            basePosition = [0, 1.5, 5]
            baseRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
        case .closeUp:
            basePosition = [0, 1.2, 1.5]
            baseRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
        case .overShoulder:
            basePosition = [1.2, 1.4, 2.5]
            baseRotation = simd_quatf(angle: -0.3, axis: [0, 1, 0])
        case .lowAngle:
            basePosition = [0, 0.5, 3]
            baseRotation = simd_quatf(angle: 0.2, axis: [1, 0, 0])
        case .dutchAngle:
            basePosition = [0, 1.5, 4]
            baseRotation = simd_quatf(angle: 0.15, axis: [0, 0, 1])
        case .pov:
            basePosition = [0, 1.6, 0.8]
            baseRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
        }

        // Adjust field of view based on intensity (closer = higher intensity)
        let fov: Float = Float(60.0 - (intensity * 20.0)) // 60° to 40°
        var transform = Transform(
            scale: .one,
            rotation: baseRotation,
            translation: basePosition
        )
        // Apply FOV to the camera component if it's a PerspectiveCamera
        if let cameraComponent = cameraEntity?.components[PerspectiveCameraComponent.self] {
            var updated = cameraComponent
            updated.fieldOfViewInDegrees = fov
            cameraEntity?.components.set(updated)
        }
        return transform
    }

    /// Adjusts depth of field or other camera effects based on intensity.
    private func applyDepthOfField(intensity: Double) {
        guard let camera = cameraEntity else { return }
        // Example: adjust aperture or focus distance via a custom component.
        // RealityKit does not have built-in depth of field, but we can simulate
        // by adjusting a custom component or post-processing later.
        // For now, we store intensity for potential use.
    }
}

// MARK: - CameraAngle Enum (if not defined elsewhere, but assumed to exist)
// This is a placeholder definition; the actual enum is in a sibling file.
// We include it here for compilation completeness, but it will be overridden by the project's definition.
enum CameraAngle: String, Codable, CaseIterable {
    case wideShot
    case closeUp
    case overShoulder
    case lowAngle
    case dutchAngle
    case pov
}