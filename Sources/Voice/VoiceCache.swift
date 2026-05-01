import Foundation
import CryptoKit

// MARK: - Cache Key

struct VoiceCacheKey: Hashable, Codable {
    let speaker: Speaker
    let text: String
}

// MARK: - Voice Cache Actor

/// Caches synthesized voice audio data in memory and on disk.
/// Uses LRU eviction for memory cache.
actor VoiceCache {
    // MARK: - Singleton
    
    static let shared = VoiceCache()
    
    // MARK: - Properties
    
    private let diskCacheDirectory: URL?
    private let maxMemorySize: Int
    
    private struct CacheEntry {
        let data: Data
        let size: Int
        var lastAccess: Date
    }
    
    private var memoryCache: [VoiceCacheKey: CacheEntry] = [:]
    private var accessOrder: [VoiceCacheKey] = []
    private var currentMemorySize: Int = 0
    
    // MARK: - Initialization
    
    /// Creates a voice cache.
    /// - Parameters:
    ///   - diskCacheDirectory: Directory for persistent disk cache. If nil, disk caching is disabled.
    ///   - maxMemorySize: Maximum bytes to keep in memory before eviction. Default 50 MB.
    init(diskCacheDirectory: URL? = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("VoiceCache"),
         maxMemorySize: Int = 50 * 1024 * 1024) {
        self.diskCacheDirectory = diskCacheDirectory
        self.maxMemorySize = maxMemorySize
        
        // Ensure disk directory exists
        if let dir = diskCacheDirectory {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Public Methods
    
    /// Stores audio data for a given key.
    func store(audio: Data, for key: VoiceCacheKey) async {
        // Write to disk first (if enabled)
        if let diskURL = diskURL(for: key) {
            try? audio.write(to: diskURL, options: .atomic)
        }
        
        // Update memory cache
        let entry = CacheEntry(data: audio, size: audio.count, lastAccess: Date())
        
        // Remove existing entry if present
        if let existing = memoryCache[key] {
            currentMemorySize -= existing.size
            accessOrder.removeAll { $0 == key }
        }
        
        // Add new entry
        memoryCache[key] = entry
        accessOrder.insert(key, at: 0)
        currentMemorySize += entry.size
        
        // Evict if over limit
        while currentMemorySize > maxMemorySize, let lastKey = accessOrder.last {
            evict(key: lastKey)
        }
    }
    
    /// Retrieves cached audio data for a key, if available.
    func retrieve(for key: VoiceCacheKey) async -> Data? {
        // Check memory
        if let entry = memoryCache[key] {
            // Update access time and move to front
            memoryCache[key]?.lastAccess = Date()
            accessOrder.removeAll { $0 == key }
            accessOrder.insert(key, at: 0)
            return entry.data
        }
        
        // Check disk
        guard let diskURL = diskURL(for: key),
              FileManager.default.fileExists(atPath: diskURL.path),
              let data = try? Data(contentsOf: diskURL) else {
            return nil
        }
        
        // Load into memory (may trigger eviction)
        let entry = CacheEntry(data: data, size: data.count, lastAccess: Date())
        memoryCache[key] = entry
        accessOrder.insert(key, at: 0)
        currentMemorySize += entry.size
        
        // Evict if needed
        while currentMemorySize > maxMemorySize, let lastKey = accessOrder.last {
            evict(key: lastKey)
        }
        
        return data
    }
    
    /// Removes a specific entry from both memory and disk.
    func remove(for key: VoiceCacheKey) async {
        evict(key: key)
        if let diskURL = diskURL(for: key) {
            try? FileManager.default.removeItem(at: diskURL)
        }
    }
    
    /// Clears all cached data (memory and disk).
    func clearAll() async {
        // Clear memory
        memoryCache.removeAll()
        accessOrder.removeAll()
        currentMemorySize = 0
        
        // Clear disk
        if let dir = diskCacheDirectory {
            try? FileManager.default.removeItem(at: dir)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
    
    /// Clears only the in-memory cache, keeping disk data.
    func clearMemory() async {
        memoryCache.removeAll()
        accessOrder.removeAll()
        currentMemorySize = 0
    }
    
    /// Returns the total size of the disk cache in bytes.
    func diskCacheSize() async -> Int {
        guard let dir = diskCacheDirectory else { return 0 }
        let resourceKeys: [URLResourceKey] = [.fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: resourceKeys) else {
            return 0
        }
        var total = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  let size = values.fileSize else { continue }
            total += size
        }
        return total
    }
    
    // MARK: - Private Helpers
    
    private func diskURL(for key: VoiceCacheKey) -> URL? {
        guard let base = diskCacheDirectory else { return nil }
        let hash = SHA256.hash(data: key.description.data(using: .utf8)!)
        let filename = hash.compactMap { String(format: "%02x", $0) }.joined()
        return base.appendingPathComponent(filename)
    }
    
    private func evict(key: VoiceCacheKey) {
        if let entry = memoryCache.removeValue(forKey: key) {
            currentMemorySize -= entry.size
        }
        accessOrder.removeAll { $0 == key }
    }
}

// MARK: - VoiceCacheKey Description

extension VoiceCacheKey: CustomStringConvertible {
    var description: String {
        "\(speaker.rawValue)|\(text)"
    }
}