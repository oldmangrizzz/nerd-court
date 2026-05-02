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
final class VoiceSynthesisClient: VoiceSynthesisServiceProtocol {
    private var voiceBank: [Speaker: CharacterVoiceID] = [:]
    private var audioCache: [String: URL] = [:]
    private let session: URLSession
    private let engine: AVAudioEngine
    private var playerNodes: [AVAudioPlayerNode] = []
    private let maxConcurrentVoices = 3

    /// Backend proxy endpoint for voice synthesis. Configurable via init for testing.
    private let synthesisEndpoint: URL

    // MARK: - Init

    init(synthesisEndpoint: URL? = nil, session: URLSession? = nil) {
        // Default endpoint: local backend proxy that forwards to TTS provider.
        // No secrets or provider URLs are embedded here — the backend proxy
        // handles authentication and routing to the actual TTS service.
        self.synthesisEndpoint = synthesisEndpoint
            ?? URL(string: "/api/voice/synthesize", relativeTo: nil)!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = session ?? URLSession(configuration: config)
        self.engine = AVAudioEngine()
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

        // Route through backend proxy — no bearer tokens or provider URLs in client code.
        let url = await synthesizeViaProxy(voiceID: voiceID, text: text, cacheKey: cacheKey)
        return url
    }

    private func synthesizeViaProxy(voiceID: CharacterVoiceID, text: String, cacheKey: String) async -> URL {
        let fallbackURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(voiceID.rawValue)_\(UUID().uuidString).wav")

        let body: [String: Any] = [
            "voice_profile": voiceID.rawValue,
            "text": text,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return fallbackURL
        }

        var request = URLRequest(url: synthesisEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let audioB64 = json["audio"] as? String ?? json["response"] as? String,
                  let audioData = Data(base64Encoded: audioB64) else {
                return fallbackURL
            }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(voiceID.rawValue)_\(UUID().uuidString).wav")
            try audioData.write(to: outputURL)
            audioCache[cacheKey] = outputURL
            return outputURL
        } catch {
            return fallbackURL
        }
    }

    // MARK: - Playback

    func play(url: URL, speaker: Speaker, completion: @escaping @Sendable () -> Void = {}) {
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
