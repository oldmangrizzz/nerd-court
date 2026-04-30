import AVFoundation
import Foundation

@MainActor
final class VoiceSynthesisClient {
    private var voiceBank: [Speaker: String] = [:]

    func preloadVoices() {
        voiceBank[.jasonTodd] = "jason_todd_red_hood_v1"
        voiceBank[.mattMurdock] = "matt_murdock_daredevil_v1"
        voiceBank[.judgeJerry] = "judge_jerry_springer_v1"
        voiceBank[.deadpool] = "deadpool_nph_v1"
    }

    func synthesize(speaker: Speaker, text: String) async -> URL {
        let voiceID = voiceBank[speaker] ?? "default_voice"
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("\(voiceID)_\(UUID().uuidString).wav")
    }
}
