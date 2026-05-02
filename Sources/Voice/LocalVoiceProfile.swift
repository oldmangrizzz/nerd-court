@preconcurrency import AVFoundation
import Foundation

/// On-device voice profile for `AVSpeechSynthesizer`. Used as the audible
/// fallback when remote F5-TTS synthesis is unavailable. Each profile selects
/// a distinct iOS voice plus a pitch/rate offset so the four staff
/// characters remain audibly distinguishable in a trial.
///
/// Voice identifiers are matched by preference order: enhanced-quality voice if
/// installed, otherwise the matching default voice, otherwise any en-US voice.
/// This keeps the output consistent across iOS minor versions where the
/// installed voice catalog varies.
struct LocalVoiceProfile {
    /// Preferred voice identifier list, tried in order. The first one available
    /// on the device is selected. Identifiers are stable across iOS releases for
    /// the system voices listed in `AVSpeechSynthesisVoice.speechVoices()`.
    let preferredIdentifiers: [String]
    /// Fallback to a `language` lookup if no preferred identifier is installed.
    let language: String
    /// Speech rate, in `AVSpeechUtterance` units (0.0 ... 1.0; default `0.5`).
    let rate: Float
    /// Pitch multiplier (0.5 ... 2.0; default 1.0).
    let pitch: Float

    func preferredVoice() -> AVSpeechSynthesisVoice? {
        for identifier in preferredIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                return voice
            }
        }
        return AVSpeechSynthesisVoice(language: language)
    }

    /// Profile mapping for the four staff voices and the guest fallback.
    static func profile(for speaker: Speaker) -> LocalVoiceProfile {
        switch speaker {
        case .jasonTodd:
            // Jason Todd: gravel/intense male, mid-30s. Fred has the harshest US male
            // timbre available in the system voices; pitch dropped, rate slightly slow.
            return LocalVoiceProfile(
                preferredIdentifiers: [
                    "com.apple.voice.compact.en-US.Fred",
                    "com.apple.eloquence.en-US.Reed",
                    "com.apple.voice.enhanced.en-US.Aaron",
                ],
                language: "en-US",
                rate: AVSpeechUtteranceDefaultSpeechRate * 0.95,
                pitch: 0.85
            )
        case .mattMurdock:
            // Matt Murdock: measured, lawyerly, even tone. Daniel (en-GB) has the
            // calm cadence; falls back to an enhanced US voice if Daniel isn't installed.
            return LocalVoiceProfile(
                preferredIdentifiers: [
                    "com.apple.voice.compact.en-GB.Daniel",
                    "com.apple.voice.enhanced.en-US.Evan",
                    "com.apple.voice.compact.en-US.Aaron",
                ],
                language: "en-US",
                rate: AVSpeechUtteranceDefaultSpeechRate * 0.92,
                pitch: 1.0
            )
        case .judgeJerry:
            // Jerry Springer: TV-host energy. Rishi or Rocko deliver the higher pitch;
            // rate bumped for talk-show pacing.
            return LocalVoiceProfile(
                preferredIdentifiers: [
                    "com.apple.eloquence.en-US.Rocko",
                    "com.apple.voice.enhanced.en-US.Tom",
                    "com.apple.voice.compact.en-AU.Lee",
                ],
                language: "en-US",
                rate: AVSpeechUtteranceDefaultSpeechRate * 1.05,
                pitch: 1.10
            )
        case .deadpool:
            // Deadpool-as-NPH: theatrical, fast, slightly higher pitch.
            return LocalVoiceProfile(
                preferredIdentifiers: [
                    "com.apple.eloquence.en-US.Shelley",
                    "com.apple.voice.enhanced.en-US.Aaron",
                    "com.apple.voice.compact.en-US.Aaron",
                ],
                language: "en-US",
                rate: AVSpeechUtteranceDefaultSpeechRate * 1.10,
                pitch: 1.15
            )
        case .guest:
            // Generic guest profile until per-grievance voice generation lands.
            return LocalVoiceProfile(
                preferredIdentifiers: [
                    "com.apple.voice.compact.en-US.Samantha",
                    "com.apple.voice.enhanced.en-US.Allison",
                ],
                language: "en-US",
                rate: AVSpeechUtteranceDefaultSpeechRate,
                pitch: 1.0
            )
        }
    }
}
