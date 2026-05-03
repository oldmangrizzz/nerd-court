import XCTest
@testable import NerdCourt

final class VoiceRegistryReplayTests: XCTestCase {

    func testStaffCastCoversFourCanonicalVoices() {
        let ids = Set(VoiceRegistryReplay.staff.map { $0.voiceID })
        XCTAssertEqual(ids, ["jason_todd", "matt_murdock", "jerry_springer", "deadpool_nph"])
    }

    func testStaffEntriesAreFullyPopulated() {
        for voice in VoiceRegistryReplay.staff {
            XCTAssertFalse(voice.voiceID.isEmpty)
            XCTAssertFalse(voice.displayName.isEmpty)
            XCTAssertTrue(voice.source.hasPrefix("ytsearch1:"),
                          "Replay manifest must use deterministic yt-search sources, got \(voice.source)")
            XCTAssertFalse(voice.warmupLine.isEmpty)
        }
    }

    func testFromInfoPlistResolvesWhenEndpointConfigured() {
        // RuntimeConfig.plist is shipped as a bundle resource for both app and
        // test targets; if the value is present, the helper must return a real
        // replay instance, otherwise nil.
        let result = VoiceRegistryReplay.fromInfoPlist()
        if AppConfig.f5ttsEndpoint.isEmpty {
            XCTAssertNil(result)
        } else {
            XCTAssertNotNil(result)
        }
    }
}
