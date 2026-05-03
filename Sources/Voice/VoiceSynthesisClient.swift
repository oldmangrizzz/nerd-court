@preconcurrency import AVFoundation
import Foundation

// MARK: - Voice Synthesis Service Protocol

@preconcurrency protocol VoiceSynthesisServiceProtocol: Sendable {
    func synthesize(speaker: Speaker, text: String) async -> URL
    @MainActor func preloadVoices()
    @MainActor func playSting(_ sting: CourtroomSting)
    @MainActor func playSync(url: URL, speaker: Speaker) async
}


// MARK: - Voice Synthesis Client

@MainActor
final class VoiceSynthesisClient: NSObject, VoiceSynthesisServiceProtocol, AVSpeechSynthesizerDelegate {
    private var voiceBank: [Speaker: CharacterVoiceID] = [:]
    private var audioCache: [String: URL] = [:]
    private let session: URLSession
    private let engine: AVAudioEngine
    private var playerNodes: [AVAudioPlayerNode] = []
    private let maxConcurrentVoices = 3

    /// Optional remote synthesis endpoint (e.g., F5-TTS Cloud Run). Read from
    /// `F5TTSEndpoint` Info.plist key when nil. When unset or unreachable,
    /// playback transparently falls back to on-device `AVSpeechSynthesizer`
    /// so the trial always has audio.
    private let synthesisEndpoint: URL?

    /// Shared-secret API key sent as `X-API-Key`. Read from `F5TTSApiKey`
    /// Info.plist value (set via xcconfig at build time).
    private let apiKey: String?

    /// Sentinel URLs returned by `synthesize` when remote TTS is unavailable.
    /// `play` recognizes these and dispatches to `AVSpeechSynthesizer` instead
    /// of attempting file playback.
    private var pendingLocalSpeech: [URL: (Speaker, String)] = [:]

    /// Single shared synthesizer; iOS handles utterance queueing.
    private let speechSynthesizer = AVSpeechSynthesizer()
    /// Per-utterance completion callbacks, keyed by `AVSpeechUtterance` identity.
    private var speechContinuations: [ObjectIdentifier: CheckedContinuation<Void, Never>] = [:]

    // MARK: - Init

    init(synthesisEndpoint: URL? = nil, apiKey: String? = nil, session: URLSession? = nil) {
        // Resolve endpoint: explicit > AppConfig (RuntimeConfig.plist > env > Info.plist) > nil.
        if let synthesisEndpoint {
            self.synthesisEndpoint = synthesisEndpoint
        } else {
            let configured = AppConfig.f5ttsEndpoint
            if !configured.isEmpty,
               let url = URL(string: configured),
               url.scheme != nil {
                self.synthesisEndpoint = url
            } else {
                self.synthesisEndpoint = nil
            }
        }

        if let apiKey, !apiKey.isEmpty {
            self.apiKey = apiKey
        } else {
            let configured = AppConfig.f5ttsApiKey
            self.apiKey = configured.isEmpty ? nil : configured
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = session ?? URLSession(configuration: config)
        self.engine = AVAudioEngine()
        super.init()
        speechSynthesizer.delegate = self
        setupAudioSession()
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio,
                                       options: [.mixWithOthers, .duckOthers])
        try? audioSession.setActive(true)
    }

    // MARK: - Voice Bank

    func preloadVoices() {
        voiceBank[.jasonTodd] = .jasonTodd
        voiceBank[.mattMurdock] = .mattMurdock
        voiceBank[.judgeJerry] = .judgeJerry
        voiceBank[.deadpool] = .deadpoolNPH
    }

    // MARK: - Synthesis

    func synthesize(speaker: Speaker, text: String) async -> URL {
        let voiceID = voiceBank[speaker] ?? .jasonTodd
        let cacheKey = "\(voiceID.rawValue)_\(text.hashValue)"

        if let cached = audioCache[cacheKey] {
            return cached
        }

        // If a remote endpoint is configured, try it; otherwise go straight to local fallback.
        if let endpoint = synthesisEndpoint {
            if let remoteURL = await synthesizeViaProxy(endpoint: endpoint, voiceID: voiceID, text: text, cacheKey: cacheKey) {
                return remoteURL
            }
        }
        return registerLocalSpeech(speaker: speaker, text: text)
    }

    private func synthesizeViaProxy(endpoint: URL, voiceID: CharacterVoiceID, text: String, cacheKey: String) async -> URL? {
        let body: [String: Any] = [
            "voice_profile": voiceID.rawValue,
            "voice_id": voiceID.rawValue,
            "text": text,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }

        // Endpoint may be the F5-TTS service base (e.g. https://host/) or already
        // include `/v1/synthesize`. Normalize so we always POST to the synth path.
        let postURL: URL = {
            if endpoint.path.contains("/v1/synthesize") { return endpoint }
            return endpoint.appendingPathComponent("v1/synthesize")
        }()

        var request = URLRequest(url: postURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/wav, application/json", forHTTPHeaderField: "Accept")
        if let apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        request.httpBody = jsonData

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // Two acceptable response shapes:
            //   1. raw audio/wav body (F5-TTS server wraps inference in audio response)
            //   2. JSON body { "audio": <base64 wav> } or { "response": <base64 wav> }
            let audioData: Data
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
            if contentType.contains("audio/") {
                audioData = data
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let audioB64 = (json["audio"] as? String) ?? (json["response"] as? String),
                      let decoded = Data(base64Encoded: audioB64) {
                audioData = decoded
            } else {
                return nil
            }

            guard !audioData.isEmpty else { return nil }
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(voiceID.rawValue)_\(UUID().uuidString).wav")
            try audioData.write(to: outputURL)
            audioCache[cacheKey] = outputURL
            return outputURL
        } catch {
            return nil
        }
    }

    /// Registers a sentinel URL whose later playback will be served by
    /// `AVSpeechSynthesizer` rather than the audio engine. The URL is unique
    /// per call so the cache map can dispatch correctly.
    private func registerLocalSpeech(speaker: Speaker, text: String) -> URL {
        let url = URL(fileURLWithPath: "/dev/null/local-speech-\(UUID().uuidString)")
        pendingLocalSpeech[url] = (speaker, text)
        return url
    }

    // MARK: - Playback

    func play(url: URL, speaker: Speaker, completion: @escaping @Sendable () -> Void = {}) {
        // If the URL is a sentinel for local TTS, dispatch through AVSpeechSynthesizer.
        if let pending = pendingLocalSpeech.removeValue(forKey: url) {
            speakLocally(speaker: pending.0, text: pending.1, completion: completion)
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            completion()
            return
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let player = AVAudioPlayerNode()
            engine.attach(player)

            let format = file.processingFormat
            engine.connect(player, to: engine.mainMixerNode, format: format)

            player.scheduleFile(file, at: nil) {
                DispatchQueue.main.async {
                    self.engine.detach(player)
                    self.playerNodes.removeAll { $0 === player }
                    completion()
                }
            }

            if !engine.isRunning {
                try engine.start()
            }

            player.play()
            playerNodes.append(player)

            // Limit concurrent voices
            while playerNodes.count > maxConcurrentVoices {
                playerNodes.first?.stop()
                engine.detach(playerNodes.removeFirst())
            }
        } catch {
            completion()
        }
    }

    func playSync(url: URL, speaker: Speaker) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            play(url: url, speaker: speaker) {
                continuation.resume()
            }
        }
    }

    // MARK: - Local Speech (AVSpeechSynthesizer)

    /// Speaks `text` through `AVSpeechSynthesizer` using a per-character voice profile.
    /// Used as a fallback when remote F5-TTS is unavailable, ensuring the trial always
    /// produces audible speech.
    private func speakLocally(speaker: Speaker, text: String, completion: @escaping @Sendable () -> Void) {
        let utterance = AVSpeechUtterance(string: text)
        let profile = LocalVoiceProfile.profile(for: speaker)
        utterance.voice = profile.preferredVoice()
        utterance.rate = profile.rate
        utterance.pitchMultiplier = profile.pitch
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0.05

        // Wrap @escaping Sendable completion in a continuation keyed by utterance identity.
        let key = ObjectIdentifier(utterance)
        // AVSpeechSynthesizer.speak triggers delegate callbacks asynchronously.
        // Bridge into a continuation we can resume from the delegate methods.
        let continuationBox = ContinuationBox(completion: completion)
        speechCompletions[key] = continuationBox

        speechSynthesizer.speak(utterance)
    }

    /// Continuation storage for in-flight utterances. `ContinuationBox` lets us
    /// store `@Sendable` callbacks in a non-Sendable dictionary on the main actor.
    private var speechCompletions: [ObjectIdentifier: ContinuationBox] = [:]

    private final class ContinuationBox {
        let completion: @Sendable () -> Void
        init(completion: @escaping @Sendable () -> Void) {
            self.completion = completion
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            self?.completeSpeech(key: key)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            self?.completeSpeech(key: key)
        }
    }

    private func completeSpeech(key: ObjectIdentifier) {
        guard let box = speechCompletions.removeValue(forKey: key) else { return }
        box.completion()
    }

    // MARK: - Sound Design

    func playSting(_ sting: CourtroomSting) {
        let stingName = sting.rawValue
        guard let url = Bundle.main.url(forResource: stingName,
                                          withExtension: "wav",
                                          subdirectory: "Sounds") else { return }

        do {
            let file = try AVAudioFile(forReading: url)
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)

            player.scheduleFile(file, at: nil) {
                DispatchQueue.main.async {
                    self.engine.detach(player)
                }
            }

            if !engine.isRunning {
                try engine.start()
            }
            player.play()
        } catch {}
    }

    func stopAll() {
        for player in playerNodes {
            player.stop()
            engine.detach(player)
        }
        playerNodes.removeAll()
    }
}

// MARK: - Courtroom Stings

enum CourtroomSting: String {
    case objection = "objection_sting"
    case gavelStrike = "gavel_strike"
    case finisherImpact = "finisher_impact"
    case dramaticReveal = "dramatic_reveal"
    case deadpoolEntrance = "deadpool_entrance"
    case phaseTransition = "phase_transition"
    case verdictDrumroll = "verdict_drumroll"
    case crowdGasp = "crowd_gasp"
    case crowdLaugh = "crowd_laugh"
}
