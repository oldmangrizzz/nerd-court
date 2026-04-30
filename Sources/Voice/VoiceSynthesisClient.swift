@preconcurrency import AVFoundation
import Foundation

@MainActor
final class VoiceSynthesisClient {
    private var voiceBank: [Speaker: CharacterVoiceID] = [:]
    private var audioCache: [String: URL] = [:]
    private let session: URLSession
    private let engine: AVAudioEngine
    private var playerNodes: [AVAudioPlayerNode] = []
    private let maxConcurrentVoices = 3

    // MARK: - Init

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
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

        // Generate via F5-XTTS on Ollama Cloud API
        let url = await synthesizeViaCloud(voiceID: voiceID, text: text, cacheKey: cacheKey)
        return url
    }

    private func synthesizeViaCloud(voiceID: CharacterVoiceID, text: String, cacheKey: String) async -> URL {
        let fallbackURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(voiceID.rawValue)_\(UUID().uuidString).wav")

        let endpoint = "https://ollama.com/api/generate"
        let prompt = buildTTSPrompt(voiceID: voiceID, text: text)

        let body: [String: Any] = [
            "model": "f5-xtts:v2",
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.2,
                "num_ctx": 4096,
                "voice_profile": voiceID.rawValue,
            ],
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return fallbackURL
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer e42471f8231349d991e9ebe4d001d9ea.4-l0FMlffIsnnxj65AOfVq0X",
                        forHTTPHeaderField: "Authorization")
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

    private func buildTTSPrompt(voiceID: CharacterVoiceID, text: String) -> String {
        """
        Generate speech audio for the following character voice.

        Voice: \(voiceID.rawValue)
        Source material: \(voiceID.sourceMaterial)
        Text to speak: \(text)

        Requirements:
        - Match the character's vocal timbre, cadence, and emotional register
        - Preserve punctuation pacing (commas = micro-pauses, periods = full stops)
        - Output as base64-encoded WAV, 24kHz sample rate, mono
        """
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
