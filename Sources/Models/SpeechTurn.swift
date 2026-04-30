import Foundation

struct SpeechTurn: Codable, Identifiable, Equatable {
    var id: String
    let speaker: Speaker
    let text: String
    let timestamp: Date
    let phase: String
    let isObjection: Bool

    init(id: String = UUID().uuidString, speaker: Speaker, text: String,
         timestamp: Date = .now, phase: String = "opening", isObjection: Bool = false) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
        self.phase = phase
        self.isObjection = isObjection
    }
}

struct CinematicFrame: Codable, Equatable {
    let effectType: CinematicEffect
    let duration: Double
    let intensity: Double
}
