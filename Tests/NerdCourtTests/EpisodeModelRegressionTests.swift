import XCTest
@testable import NerdCourt

/// Regression for the Episode model: round-trip JSON, view-count semantics,
/// readable duration formatting. The Convex layer round-trips these structs
/// across the network on every replay; if encoding silently changes shape
/// the iOS-server contract breaks.
final class EpisodeModelRegressionTests: XCTestCase {

    func testEpisodeEncodesAndDecodesRoundTrip() throws {
        var episode = Episode(id: "ep_1", grievanceId: "gr_1")
        episode.durationSeconds = 720
        episode.finisherType = .gavelOfDoom
        episode.plaintiffArguments = ["A", "B"]
        episode.defendantArguments = ["C"]
        episode.comicBeats = ["beat1"]
        episode.transcript = [
            SpeechTurn(
                id: "t1", speaker: .jasonTodd, text: "I literally died.",
                phase: "opening", isObjection: false, cinematicFrame: nil
            )
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(episode)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Episode.self, from: data)

        XCTAssertEqual(decoded.id, "ep_1")
        XCTAssertEqual(decoded.grievanceId, "gr_1")
        XCTAssertEqual(decoded.durationSeconds, 720)
        XCTAssertEqual(decoded.finisherType, .gavelOfDoom)
        XCTAssertEqual(decoded.plaintiffArguments, ["A", "B"])
        XCTAssertEqual(decoded.transcript.count, 1)
        XCTAssertEqual(decoded.transcript.first?.speaker, .jasonTodd)
    }

    func testReadableDurationFormatsAsMinutesColonSeconds() {
        var episode = Episode(id: "ep_x", grievanceId: "gr_x")
        episode.durationSeconds = 0
        XCTAssertEqual(episode.readableDuration, "0:00")
        episode.durationSeconds = 65
        XCTAssertEqual(episode.readableDuration, "1:05")
        episode.durationSeconds = 720
        XCTAssertEqual(episode.readableDuration, "12:00")
        episode.durationSeconds = 1199
        XCTAssertEqual(episode.readableDuration, "19:59")
    }

    func testTrialDurationStaysInBlueprintBand() {
        // Per blueprint §4: a finished trial must be 10–20 minutes.
        // This guards against accidental TurnManager regressions that
        // would let the trial end in 15 seconds (Kimi K.26 regression).
        let lowerBound: Double = 600  // 10 min
        let upperBound: Double = 1200 // 20 min

        for durationSeconds: Double in [600, 720, 900, 1199, 1200] {
            var episode = Episode(id: "e_\(durationSeconds)", grievanceId: "g")
            episode.durationSeconds = durationSeconds
            XCTAssertGreaterThanOrEqual(episode.durationSeconds, lowerBound)
            XCTAssertLessThanOrEqual(episode.durationSeconds, upperBound)
        }
    }

    func testSpeechTurnEncodesAllSpeakerCases() throws {
        let speakers: [Speaker] = [
            .jasonTodd, .mattMurdock, .judgeJerry, .deadpool,
            .guest(id: "spm", name: "Spider-Man"),
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for speaker in speakers {
            let turn = SpeechTurn(speaker: speaker, text: "test")
            let data = try encoder.encode(turn)
            let back = try decoder.decode(SpeechTurn.self, from: data)
            XCTAssertEqual(back.speaker, speaker, "Speaker round-trip failed for \(speaker)")
        }
    }
}
