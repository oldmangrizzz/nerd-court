import Foundation

struct Episode: Identifiable, Codable, Sendable {
    var id: String
    var grievanceId: String
    var transcript: [SpeechTurn] = []
    var verdict: Verdict?
    var plaintiffArguments: [String] = []
    var defendantArguments: [String] = []
    var comicBeats: [String] = []
    var generatedAt: Date
    var durationSeconds: Double = 0
    var viewCount: Int = 0
    var finisherType: FinisherType?

    var readableDuration: String {
        let mins = Int(durationSeconds) / 60
        let secs = Int(durationSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    init(id: String, grievanceId: String, generatedAt: Date = .now) {
        self.id = id
        self.grievanceId = grievanceId
        self.generatedAt = generatedAt
    }
}
