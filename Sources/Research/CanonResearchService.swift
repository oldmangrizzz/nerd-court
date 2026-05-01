import Foundation

// MARK: - Research Service

actor CanonResearchService {
    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String?
    
    enum ResearchError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case noResults
        case serverError(statusCode: Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid search URL"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .decodingError(let error): return "Failed to parse response: \(error.localizedDescription)"
            case .noResults: return "No research results found"
            case .serverError(let code): return "Server error with status code \(code)"
            }
        }
    }
    
    init(baseURL: URL,
         apiKey: String? = nil,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }
    
    // MARK: - Public Methods
    
    func research(query: String) async throws -> CanonResearchResult {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ResearchError.invalidURL
        }
        
        let results = try await performSearch(query: query)
        let summary = generateSummary(from: results, query: query)
        
        return CanonResearchResult(
            sources: results,
            keyFacts: [summary],
            plaintiffEvidence: [],
            defendantEvidence: [],
            researchedAt: Date()
        )
    }
    
    func researchCharacter(name: String, universe: String) async throws -> CanonResearchResult {
        let query = "\(name) \(universe) character personality speech patterns voice"
        return try await research(query: query)
    }
    
    func researchFranchise(franchise: Franchise) async throws -> CanonResearchResult {
        let query = "\(franchise.displayName) franchise lore rules canon"
        return try await research(query: query)
    }
    
    // MARK: - Private Helpers
    
    private func performSearch(query: String) async throws -> [CanonSource] {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        
        guard let url = components?.url else {
            throw ResearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResearchError.networkError(URLError(.badServerResponse))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ResearchError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        do {
            let searchResponse = try decoder.decode(MCPSearchResponse.self, from: data)
            guard !searchResponse.results.isEmpty else {
                throw ResearchError.noResults
            }
            return searchResponse.results.map { result in
                CanonSource(
                    id: result.id,
                    title: result.title,
                    url: result.url.absoluteString,
                    excerpt: result.snippet
                )
            }
        } catch let decodingError as DecodingError {
            throw ResearchError.decodingError(decodingError)
        } catch {
            throw ResearchError.networkError(error)
        }
    }
    
    private func generateSummary(from sources: [CanonSource], query: String) -> String {
        guard !sources.isEmpty else { return "No information found for '\(query)'." }
        
        let topSnippets = sources
            .sorted(by: { $0.title.count > $1.title.count })
            .prefix(3)
            .map { $0.excerpt }
        
        let combined = topSnippets.joined(separator: " ")
        if combined.count > 500 {
            return String(combined.prefix(500)) + "..."
        }
        return combined
    }
}

// MARK: - MCP Search API Response Models

private struct MCPSearchResponse: Codable {
    let results: [MCPResult]
}

private struct MCPResult: Codable {
    let id: String
    let title: String
    let snippet: String
    let url: URL
    let source: String
    let score: Double
}