import Foundation

struct SpeechTurn: Codable, Identifiable, Equatable, Hashable {
    var id: String
    let speaker: Speaker
    let text: String
    let timestamp: Date
    let phase: String
    let isObjection: Bool
    var audioURL: String?
    
    /// Audio data for this speech turn (computed from audioURL or cached)
    var audioData: Data? {
        // TODO: Implement audio loading from URL or cache
        return nil
    }

    init(id: String = UUID().uuidString, speaker: Speaker, text: String,
         timestamp: Date = .now, phase: String = "opening", isObjection: Bool = false) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
        self.phase = phase
        self.isObjection = isObjection
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
