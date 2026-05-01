import Foundation

/// A single canon source found during research.
public struct CanonSource: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let url: String
    public let excerpt: String

    public init(id: String, title: String, url: String, excerpt: String) {
        self.id = id
        self.title = title
        self.url = url
        self.excerpt = excerpt
    }
}
