import Foundation

enum AppConfig {
    /// In-memory cache of `RuntimeConfig.plist` (a bundle resource) so we
    /// only parse the file once. Secrets in this file are gitignored — see
    /// `Resources/RuntimeConfig.example.plist` for the schema.
    private static let runtimeConfig: [String: String] = {
        guard let url = Bundle.main.url(forResource: "RuntimeConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data,
                                                                     options: [],
                                                                     format: nil) as? [String: Any]
        else { return [:] }
        return dict.compactMapValues { $0 as? String }
    }()

    /// Resolve a configuration value. Order:
    ///   1. process environment (developer override)
    ///   2. RuntimeConfig.plist bundle resource (production)
    ///   3. Info.plist (legacy fallback for already-shipped builds)
    private static func value(envKey: String?, key: String) -> String? {
        if let envKey, let env = ProcessInfo.processInfo.environment[envKey], !env.isEmpty {
            return env
        }
        if let runtime = runtimeConfig[key], !runtime.isEmpty {
            return runtime
        }
        if let info = Bundle.main.object(forInfoDictionaryKey: key) as? String, !info.isEmpty {
            return info
        }
        return nil
    }

    /// Returns the Convex deployment URL.
    static var convexDeploymentURL: String {
        value(envKey: "CONVEX_DEPLOYMENT_URL", key: "ConvexDeploymentURL")
            ?? "https://notable-kookabura-259.convex.cloud"
    }

    /// Ollama Cloud API key (ollama.com). Empty string means "not configured" —
    /// callers must check before constructing `OllamaCloudClient`.
    static var ollamaCloudApiKey: String {
        value(envKey: "OLLAMA_API_KEY", key: "OllamaApiKey") ?? ""
    }

    /// F5-TTS Cloud Run endpoint base URL (or empty when unconfigured).
    static var f5ttsEndpoint: String {
        value(envKey: "F5TTS_ENDPOINT", key: "F5TTSEndpoint") ?? ""
    }

    /// F5-TTS shared-secret API key.
    static var f5ttsApiKey: String {
        value(envKey: "F5TTS_API_KEY", key: "F5TTSApiKey") ?? ""
    }
}

