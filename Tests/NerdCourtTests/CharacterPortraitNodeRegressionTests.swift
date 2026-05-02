import XCTest
import SpriteKit
@testable import NerdCourt

/// Regression for `CharacterPortraitNode`. Build #9 specifically fixed the
/// "JERRY/JASON/MATT/DP colored circles" regression. These tests fail loudly
/// if portraits silently collapse back to flat shapes.
@MainActor
final class CharacterPortraitNodeRegressionTests: XCTestCase {

    func testEveryStaffSpeakerProducesLayeredPortrait() {
        let staff: [Speaker] = [.jasonTodd, .mattMurdock, .judgeJerry, .deadpool]
        for speaker in staff {
            let node = CharacterPortraitNode.create(for: speaker)
            // Layered portrait must have at least 4 child shapes (halo, body, accents, nameplate).
            // Flat-circle regression had ≤2.
            XCTAssertGreaterThanOrEqual(
                node.children.count, 3,
                "\(speaker.displayName) portrait has only \(node.children.count) layers — regression to colored circles"
            )
            // Body subtree must itself contain multiple sub-shapes.
            let bodyChildCount = node.children.flatMap { $0.children }.count
            XCTAssertGreaterThanOrEqual(
                bodyChildCount, 3,
                "\(speaker.displayName) body subtree has only \(bodyChildCount) sub-shapes"
            )
        }
    }

    func testGuestPortraitRendersInitialsBadge() {
        let node = CharacterPortraitNode.create(
            for: .guest(id: "spm", name: "Spider-Man")
        )
        let allLabels = node.children.flatMap { [$0] + $0.children }.compactMap { $0 as? SKLabelNode }
        XCTAssertFalse(allLabels.isEmpty, "Guest portrait missing initials/name label")
    }

    func testPortraitsHaveDistinctTints() {
        let staff: [Speaker] = [.jasonTodd, .mattMurdock, .judgeJerry, .deadpool]
        var observedFills: Set<String> = []
        for speaker in staff {
            let node = CharacterPortraitNode.create(for: speaker)
            // Walk the whole subtree, hash union of SKShapeNode fill colors.
            let fingerprint = collectShapes(in: node)
                .map { $0.fillColor.description }
                .sorted()
                .joined(separator: ",")
            observedFills.insert(fingerprint)
        }
        XCTAssertEqual(
            observedFills.count, staff.count,
            "Two staff portraits collapsed to identical color fingerprints"
        )
    }

    private func collectShapes(in node: SKNode) -> [SKShapeNode] {
        var out: [SKShapeNode] = []
        if let s = node as? SKShapeNode { out.append(s) }
        for child in node.children { out.append(contentsOf: collectShapes(in: child)) }
        return out
    }
}
