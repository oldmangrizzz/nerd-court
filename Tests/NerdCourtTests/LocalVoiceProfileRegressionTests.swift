import XCTest
@testable import NerdCourt

/// Production regression for `LocalVoiceProfile`. The daughter's birthday demo
/// runs entirely on local TTS until F5-TTS is plumbed; if profiles collapse,
/// every character sounds the same. These tests guarantee distinctness and
/// resolution.
final class LocalVoiceProfileRegressionTests: XCTestCase {

    private let staffSpeakers: [Speaker] = [
        .jasonTodd, .mattMurdock, .judgeJerry, .deadpool,
    ]

    func testEveryStaffSpeakerHasAProfile() {
        for speaker in staffSpeakers {
            let profile = LocalVoiceProfile.profile(for: speaker)
            XCTAssertFalse(profile.preferredIdentifiers.isEmpty, "\(speaker) has no preferred voices")
            XCTAssertFalse(profile.language.isEmpty)
        }
    }

    func testStaffProfilesAreAudiblyDistinctByPitchOrRate() {
        let signatures = staffSpeakers.map { speaker -> String in
            let p = LocalVoiceProfile.profile(for: speaker)
            return "\(p.preferredIdentifiers.first ?? "?")|\(p.rate)|\(p.pitch)"
        }
        XCTAssertEqual(
            Set(signatures).count, staffSpeakers.count,
            "Two staff speakers share an identical voice signature; trial would sound monotone"
        )
    }

    func testGuestProfileResolves() {
        let profile = LocalVoiceProfile.profile(for: .guest(id: "abc", name: "Spider-Man"))
        XCTAssertEqual(profile.language, "en-US")
        XCTAssertFalse(profile.preferredIdentifiers.isEmpty)
    }

    func testEveryProfileResolvesToAnInstalledVoice() {
        // Use language fallback path; this confirms the simulator at least has
        // an en-US voice for every speaker — the contract `preferredVoice()` upholds.
        for speaker in staffSpeakers + [.guest(id: "x", name: "Test Guest")] {
            let profile = LocalVoiceProfile.profile(for: speaker)
            XCTAssertNotNil(
                profile.preferredVoice(),
                "\(speaker): no installed voice could be resolved — TTS would fail at runtime"
            )
        }
    }

    func testRateAndPitchWithinSafeBounds() {
        for speaker in staffSpeakers {
            let p = LocalVoiceProfile.profile(for: speaker)
            XCTAssertGreaterThan(p.rate, 0.0)
            XCTAssertLessThan(p.rate, 1.0)
            XCTAssertGreaterThanOrEqual(p.pitch, 0.5)
            XCTAssertLessThanOrEqual(p.pitch, 2.0)
        }
    }
}
