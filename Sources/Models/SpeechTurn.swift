import Foundation

struct SpeechTurn: Codable, Identifiable, Equatable, Hashable {
    var id: String
    let speaker: Speaker
    let text: String
    let timestamp: Date
    let phase: String
    let isObjection: Bool
    var audioURL: String?
    var cinematicFrame: CinematicFrame?

    /// Audio data for this speech turn (computed from audioURL or cached)
    var audioData: Data? {
        guard let urlString = audioURL, let url = URL(string: urlString) else { return nil }
        return try? Data(contentsOf: url)
    }

    init(id: String = UUID().uuidString, speaker: Speaker, text: String,
         timestamp: Date = .now, phase: String = "opening", isObjection: Bool = false,
         cinematicFrame: CinematicFrame? = nil) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
        self.phase = phase
        self.isObjection = isObjection
        self.cinematicFrame = cinematicFrame
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
