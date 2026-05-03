import Foundation

/// Self-healing voice registry for F5-TTS Cloud Run.
///
/// Cloud Run scales to zero. When the container cold-starts, the in-memory
/// voice registry is empty. The first trial after a cold start would then
/// silently fall back to `AVSpeechSynthesizer` instead of the four staff
/// voices the operator approved.
///
/// `VoiceRegistryReplay`:
///   1. Queries `GET {endpoint}/` for the advertised voice catalogue.
///   2. POSTs `/v1/voices/register` for any of the four staff voices missing
///      from the catalogue, using the same yt-search source strings the
///      regression suite verifies.
///   3. Is idempotent and safe to call on every app launch.
///   4. Fails open: if the network is down or the endpoint is unreachable,
///      it returns silently — `VoiceSynthesisClient` will fall back to local
///      speech for that trial, never crashing the app.
final class VoiceRegistryReplay: @unchecked Sendable {

    struct StaffVoice {
        let voiceID: String
        let displayName: String
        let source: String
        let warmupLine: String
    }

    /// The four-voice cast that must always be present on the server.
    /// Sources are the same yt-dlp queries the regression suite uses; they
    /// resolve deterministically to the same reference clips F5-TTS needs.
    static let staff: [StaffVoice] = [
        StaffVoice(
            voiceID: "jason_todd",
            displayName: "Jason Todd",
            source: "ytsearch1:Jason Todd Red Hood Arkham Knight angry monologue",
            warmupLine: "Court is in session."
        ),
        StaffVoice(
            voiceID: "matt_murdock",
            displayName: "Matt Murdock",
            source: "ytsearch1:Charlie Cox Daredevil courtroom closing argument speech",
            warmupLine: "Your honor, the evidence speaks for itself."
        ),
        StaffVoice(
            voiceID: "jerry_springer",
            displayName: "Judge Jerry Springer",
            source: "ytsearch1:Jerry Springer final thought monologue speech",
            warmupLine: "Take care of yourselves and each other."
        ),
        StaffVoice(
            voiceID: "deadpool_nph",
            displayName: "Deadpool as NPH",
            source: "ytsearch1:Neil Patrick Harris Dr Horrible Sing Along Blog narration",
            warmupLine: "Legendary. Streamlining is sexy."
        )
    ]

    private let endpoint: URL
    private let apiKey: String?
    private let session: URLSession

    init(endpoint: URL, apiKey: String?, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.session = session
    }

    /// Convenience: read endpoint + key from Info.plist exactly the way
    /// `VoiceSynthesisClient` does. Returns nil if either is missing.
    static func fromInfoPlist(session: URLSession = .shared) -> VoiceRegistryReplay? {
        let raw = AppConfig.f5ttsEndpoint
        guard !raw.isEmpty,
              let url = URL(string: raw),
              url.scheme != nil else { return nil }
        let key = AppConfig.f5ttsApiKey
        return VoiceRegistryReplay(endpoint: url, apiKey: key.isEmpty ? nil : key, session: session)
    }

    /// Bring the server registry up to spec. Safe to call concurrently.
    /// Returns the list of voice IDs that were (re-)registered this call.
    @discardableResult
    func ensureStaffVoicesRegistered(timeout: TimeInterval = 240) async -> [String] {
        let advertised = (try? await fetchAdvertisedVoices()) ?? []
        let advertisedSet = Set(advertised)
        var registered: [String] = []
        for voice in Self.staff where !advertisedSet.contains(voice.voiceID) {
            if await register(voice, timeout: timeout) {
                registered.append(voice.voiceID)
            }
        }
        return registered
    }

    // MARK: - Private

    private func makeRequest(path: String, method: String) -> URLRequest {
        let url: URL = {
            if path.isEmpty || path == "/" { return endpoint }
            return endpoint.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        }()
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        return req
    }

    private struct CatalogueResponse: Decodable {
        struct Voice: Decodable { let voice_id: String? }
        let voices: [Voice]?
    }

    func fetchAdvertisedVoices() async throws -> [String] {
        var req = makeRequest(path: "/", method: "GET")
        req.timeoutInterval = 20
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return []
        }
        let decoded = try JSONDecoder().decode(CatalogueResponse.self, from: data)
        return decoded.voices?.compactMap { $0.voice_id } ?? []
    }

    private func register(_ voice: StaffVoice, timeout: TimeInterval) async -> Bool {
        var req = makeRequest(path: "v1/voices/register", method: "POST")
        req.timeoutInterval = timeout
        let body: [String: Any] = [
            "voice_id": voice.voiceID,
            "display_name": voice.displayName,
            "source": voice.source,
            "warmup_text": voice.warmupLine
        ]
        guard let json = try? JSONSerialization.data(withJSONObject: body) else { return false }
        req.httpBody = json
        do {
            let (_, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
