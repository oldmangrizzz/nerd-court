import Foundation

actor ConvexClient {
    private let baseURL: String
    private let session: URLSession

    init(deploymentURL: String = "https://fastidious-wolverine-481.convex.cloud") {
        self.baseURL = deploymentURL + "/api"
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func query<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: baseURL + "/query")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": []])

        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func mutation(_ path: String, args: [String: Any]) async throws -> Data {
        let url = URL(string: baseURL + "/mutation")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args])

        let (data, _) = try await session.data(for: req)
        return data
    }

    func action(_ path: String, args: [String: Any]) async throws -> Data {
        let url = URL(string: baseURL + "/action")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args])

        let (data, _) = try await session.data(for: req)
        return data
    }
}
