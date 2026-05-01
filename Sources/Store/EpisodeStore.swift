import Foundation
import Observation

// MARK: - FileIOActor

/// Actor responsible for thread-safe file I/O operations.
private actor FileIOActor {
    /// Loads an array of episodes from a JSON file.
    func loadEpisodes(from url: URL) throws -> [Episode] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Episode].self, from: data)
    }
    
    /// Saves an array of episodes to a JSON file.
    func saveEpisodes(_ episodes: [Episode], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(episodes)
        try data.write(to: url, options: .atomic)
    }
}

// MARK: - EpisodeStore

/// Manages local persistence and caching of Episode objects.
/// All UI-facing mutations occur on the main actor.
@MainActor
@Observable
final class EpisodeStore {
    /// Shared singleton instance for app-wide episode storage.
    static let shared = EpisodeStore()
    
    /// The in-memory list of episodes, sorted by generation date (newest first).
    private(set) var episodes: [Episode] = []
    
    /// Indicates whether an initial load from disk is in progress.
    private(set) var isLoading = false
    
    /// Holds the last encountered error message, if any.
    private(set) var errorMessage: String?
    
    /// URL to the local JSON file used for persistence.
    private let fileURL: URL
    
    /// Actor handling all file operations off the main thread.
    private let fileIO = FileIOActor()
    
    /// Fast lookup dictionary keyed by episode ID.
    private var episodesByID: [String: Episode] = [:]
    
    /// Creates a new store and triggers an initial load from disk.
    init() {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        fileURL = documentsDirectory.appendingPathComponent("episodes.json")
        
        Task {
            await load()
        }
    }
    
    // MARK: - Public API
    
    /// Loads episodes from the local JSON file.
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let loaded = try await fileIO.loadEpisodes(from: fileURL)
            episodes = loaded.sorted { $0.generatedAt > $1.generatedAt }
            rebuildLookup()
        } catch {
            errorMessage = "Failed to load episodes: \(error.localizedDescription)"
            episodes = []
            episodesByID = [:]
        }
    }
    
    /// Persists the current in-memory episodes to disk.
    func save() async {
        do {
            try await fileIO.saveEpisodes(episodes, to: fileURL)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save episodes: \(error.localizedDescription)"
        }
    }
    
    /// Adds a new episode, persists, and updates the in-memory list.
    func addEpisode(_ episode: Episode) async {
        // Avoid duplicates
        guard episodesByID[episode.id] == nil else {
            errorMessage = "Episode with ID \(episode.id) already exists."
            return
        }
        
        episodes.append(episode)
        episodes.sort { $0.generatedAt > $1.generatedAt }
        episodesByID[episode.id] = episode
        
        await save()
    }
    
    /// Removes an episode by ID, persists, and updates the in-memory list.
    func removeEpisode(id: String) async {
        guard episodesByID[id] != nil else {
            errorMessage = "Episode with ID \(id) not found."
            return
        }
        
        episodes.removeAll { $0.id == id }
        episodesByID.removeValue(forKey: id)
        
        await save()
    }
    
    /// Updates an existing episode (e.g., after debate completion) and persists.
    func updateEpisode(_ updatedEpisode: Episode) async {
        guard let index = episodes.firstIndex(where: { $0.id == updatedEpisode.id }) else {
            errorMessage = "Episode with ID \(updatedEpisode.id) not found for update."
            return
        }
        
        episodes[index] = updatedEpisode
        episodes.sort { $0.generatedAt > $1.generatedAt }
        episodesByID[updatedEpisode.id] = updatedEpisode
        
        await save()
    }
    
    /// Retrieves an episode by ID in O(1) time.
    func episode(for id: String) -> Episode? {
        return episodesByID[id]
    }
    
    /// Removes all episodes from memory and disk.
    func clearAll() async {
        episodes.removeAll()
        episodesByID.removeAll()
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            errorMessage = nil
        } catch {
            errorMessage = "Failed to clear episodes: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Helpers
    
    /// Rebuilds the lookup dictionary from the current episodes array.
    private func rebuildLookup() {
        episodesByID = Dictionary(uniqueKeysWithValues: episodes.map { ($0.id, $0) })
    }
}