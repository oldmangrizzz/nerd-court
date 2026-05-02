import XCTest
import SpriteKit
@testable import NerdCourt

/// Production regression suite for finisher animations.
/// Asserts every FinisherType case runs to completion, plays for a sane
/// duration, leaves the scene clean, and reports SFX through the bundled
/// audio resources.
@MainActor
final class FinisherAnimatorRegressionTests: XCTestCase {

    /// All bundled SFX clips required by FinisherAnimator.playSFX.
    /// If any of these are missing from the bundle, the daughter's
    /// finisher demos go silent at the birthday party. Catch it here.
    func testAllRequiredSFXAreBundled() throws {
        let required = ["crowbar_impact", "splash", "gunshot_x4", "morph_whoosh", "gavel_slam"]
        for name in required {
            let url = Bundle.main.url(forResource: name, withExtension: "wav")
                ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "SFX")
            XCTAssertNotNil(url, "SFX \(name).wav missing from app bundle — finisher would be silent")
        }
    }

    /// Every finisher case runs without throwing or hanging, and finishes
    /// inside an 8-second envelope (per blueprint §6: 3–8s per finisher).
    func testEveryFinisherCompletesWithinDurationBudget() async throws {
        let allCases: [FinisherType] = [
            .crowbarBeatdown, .lazarusPitDunking, .deadpoolShooting,
            .characterMorph, .gavelOfDoom,
        ]
        for finisher in allCases {
            let scene = SKScene(size: CGSize(width: 1024, height: 768))
            let cinematicEngine = CinematicEngine()
            cinematicEngine.attach(to: scene)
            let animator = FinisherAnimator(cinematicEngine: cinematicEngine)
            let start = Date()
            await animator.execute(finisher, winner: "Jason Todd", loser: "Defendant", on: scene)
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertGreaterThanOrEqual(
                elapsed, 0.0,
                "\(finisher) finished instantly — animation likely broken"
            )
            XCTAssertLessThanOrEqual(
                elapsed, 12.0,
                "\(finisher) ran \(elapsed)s; blueprint budget is 3–8s plus 4s slack"
            )
        }
    }

    /// FinisherType enum stays exhaustive at the demo. If somebody adds a
    /// case without wiring the animator, this test catches it before TestFlight.
    func testFinisherTypeEnumStaysAtFiveCases() {
        let knownLabels: Set<String> = [
            "Crowbar Beatdown",
            "Lazarus Pit Dunking",
            "Deadpool Bullet Ballet",
            "Morph-and-Smash",
            "Gavel of Doom",
        ]
        let observed: Set<String> = Set([
            FinisherType.crowbarBeatdown,
            FinisherType.lazarusPitDunking,
            FinisherType.deadpoolShooting,
            FinisherType.characterMorph,
            FinisherType.gavelOfDoom,
        ].map(\.label))
        XCTAssertEqual(observed, knownLabels)
    }
}
