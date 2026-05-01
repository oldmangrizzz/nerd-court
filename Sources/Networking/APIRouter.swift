import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Router

enum APIRouter {
    case query(function: String)
    case mutation(function: String)
    case action(function: String)
    
    // MARK: - Path
    
    private var path: String {
        switch self {
        case .query(let function):
            return "/api/query/\(function)"
        case .mutation(let function):
            return "/api/mutation/\(function)"
        case .action(let function):
            return "/api/action/\(function)"
        }
    }
    
    // MARK: - HTTP Method
    
    private var httpMethod: HTTPMethod {
        switch self {
        case .query:
            return .get
        case .mutation, .action:
            return .post
        }
    }
    
    // MARK: - URL Request Builder
    
    func urlRequest(baseURL: URL, body: (any Encodable)? = nil) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        
        return request
    }
}

// MARK: - Type-Erasure Helper for Encodable

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init(_ wrapped: any Encodable) {
        _encode = { encoder in
            try wrapped.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}