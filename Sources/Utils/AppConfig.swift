import Foundation

enum AppConfig {
    /// Returns the Convex deployment URL from the environment, or falls back
    /// to the project default for local development.
    static var convexDeploymentURL: String {
        ProcessInfo.processInfo.environment["CONVEX_DEPLOYMENT_URL"]
            ?? "https://fastidious-wolverine-481.convex.cloud"
    }

    /// The Delta Ollama Max host for LLM dispatch.
    static var deltaHost: String {
        ProcessInfo.processInfo.environment["DELTA_HOST"] ?? "delta.local"
    }
}
