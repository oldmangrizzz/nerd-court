import Foundation

enum AppConfig {
    /// Returns the Convex deployment URL from the environment, or falls back
    /// to the project default for local development.
    static var convexDeploymentURL: String {
        ProcessInfo.processInfo.environment["CONVEX_DEPLOYMENT_URL"]
            ?? "https://notable-kookabura-259.convex.cloud"
    }

    /// Ollama Cloud API key (ollama.com). Required at runtime — no default.
    /// Plumbed via Info.plist key `OllamaApiKey` or env `OLLAMA_API_KEY`.
    static var ollamaCloudApiKey: String {
        if let env = ProcessInfo.processInfo.environment["OLLAMA_API_KEY"], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "OllamaApiKey") as? String,
           !plist.isEmpty {
            return plist
        }
        return ""
    }
}
