import Foundation

actor ConvexClient {
    private let baseURL: String
    private let session: URLSession

    /// Create a ConvexClient with an explicit deployment URL and optional session.
    /// - Parameters:
    ///   - deploymentURL: The Convex deployment URL (e.g. from environment config). Must not be empty.
    ///   - session: Optional URLSession for testing; defaults to a standard configuration.
    init(deploymentURL: String, session: URLSession? = nil) {
        precondition(!deploymentURL.isEmpty, "Convex deployment URL must be provided via environment config — no hardcoded defaults.")
        self.baseURL = deploymentURL + "/api"
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = session ?? URLSession(configuration: config)
    }
    
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func query<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: baseURL + "/query")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": []])

        let (data, _) = try await session.data(for: req)
        return try makeDecoder().decode(T.self, from: data)
    }
    
    func query<T: Decodable & Sendable>(_ path: String, args: [String: any Sendable]) async throws -> T {
        let url = URL(string: baseURL + "/query")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args])

        let (data, _) = try await session.data(for: req)
        return try makeDecoder().decode(T.self, from: data)
    }

    func mutation(_ path: String, args: [String: any Sendable]) async throws -> Data {
        let url = URL(string: baseURL + "/mutation")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args])

        let (data, _) = try await session.data(for: req)
        return data
    }

    func action(_ path: String, args: [String: any Sendable]) async throws -> Data {
        let url = URL(string: baseURL + "/action")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args])

        let (data, _) = try await session.data(for: req)
        return data
    }
}
