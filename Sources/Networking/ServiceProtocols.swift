import Foundation
import SpriteKit

// MARK: - Protocols

protocol LLMClient: Sendable {
    func dispatch(systemPrompt: String, debateContext: String, turnHistory: [SpeechTurn]) async throws -> String
}

protocol DebateEngineProtocol: Sendable {
    func runDebate(grievance: Grievance, research: CanonResearchResult, guests: [GuestCharacter]) async throws -> Episode
}

protocol CanonResearchServiceProtocol: Sendable {
    func research(grievance: Grievance) async throws -> CanonResearchResult
}

@preconcurrency protocol ConvexPersisting: Sendable {
    func query<T: Decodable & Sendable>(_ path: String, args: [String: any Sendable]) async throws -> T
    func mutation(_ path: String, args: [String: any Sendable]) async throws -> Data
    func action(_ path: String, args: [String: any Sendable]) async throws -> Data
}

@preconcurrency protocol FinisherAnimating: Sendable {
    func triggerEffect(_ type: FinisherType, duration: TimeInterval, intensity: Double) async
}

// MARK: - LLMClient Conformance

// `OllamaCloudClient` declares `LLMClient` conformance directly (file-local).

// MARK: - DebateEngineProtocol Conformance

extension DebateEngine: DebateEngineProtocol {
    // Already conforms: func runDebate(grievance: Grievance, research: CanonResearchResult, guests: [GuestCharacter]) async throws -> Episode
}

// MARK: - CanonResearchServiceProtocol Conformance

extension CanonResearchEngine: CanonResearchServiceProtocol {
    // Already conforms: func research(grievance: Grievance) async throws -> CanonResearchResult
}

// MARK: - ConvexPersisting Conformance

extension ConvexClient: ConvexPersisting {
    // Already conforms via the three required members (query, mutation, action)
}

// MARK: - FinisherAnimating Conformance

extension FinisherAnimator: FinisherAnimating {
    func triggerEffect(_ type: FinisherType, duration: TimeInterval, intensity: Double) async {
        // FinisherAnimator runs finisher effects on an ephemeral SKScene.
        // For protocol conformance, we create a transient scene and execute.
        let scene = SKScene(size: CGSize(width: 390, height: 844))
        scene.backgroundColor = .black
        let engine = CinematicEngine()
        engine.attach(to: scene)

        switch type {
        case .crowbarBeatdown:
            await execute(.crowbarBeatdown, winner: "Plaintiff", loser: "Defendant", on: scene)
        case .lazarusPitDunking:
            await execute(.lazarusPitDunking, winner: "Plaintiff", loser: "Defendant", on: scene)
        case .deadpoolShooting:
            await execute(.deadpoolShooting, winner: "Plaintiff", loser: "Defendant", on: scene)
        case .characterMorph:
            await execute(.characterMorph, winner: "Plaintiff", loser: "Defendant", on: scene)
        case .gavelOfDoom:
            await execute(.gavelOfDoom, winner: "Plaintiff", loser: "Defendant", on: scene)
        }

        let delay = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: delay)
    }
}
