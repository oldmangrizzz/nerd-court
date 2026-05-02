import Foundation

@MainActor
@Observable final class TrialCoordinator {
    private let ollamaClient: any LLMClient
    private let convexClient: (any ConvexPersisting)?
    private let debateEngine: any DebateEngineProtocol
    private let researchEngine: any CanonResearchServiceProtocol
    private let voiceClient: any VoiceSynthesisServiceProtocol
    private let guestGenerator: GuestCharacterGenerator

    init(ollamaClient: any LLMClient, convexClient: (any ConvexPersisting)?,
         debateEngine: any DebateEngineProtocol, researchEngine: any CanonResearchServiceProtocol,
         voiceClient: any VoiceSynthesisServiceProtocol) {
        self.ollamaClient = ollamaClient
        self.convexClient = convexClient
        self.debateEngine = debateEngine
        self.researchEngine = researchEngine
        self.voiceClient = voiceClient
        self.guestGenerator = GuestCharacterGenerator(ollamaClient: ollamaClient)
    }

    func startTrial(scene: CourtroomScene, grievance: Grievance) async {
        voiceClient.preloadVoices()

        let research = try? await researchEngine.research(grievance: grievance)

        var guests: [GuestCharacter] = []
        if let plaintiffId = grievance.guestPlaintiffId, !plaintiffId.isEmpty {
            let parts = plaintiffId.components(separatedBy: "|")
            if parts.count >= 3,
               let guest = try? await guestGenerator.generate(
                    name: parts[0], universe: parts[1], role: parts[2]) {
                guests.append(guest)
            }
        }

        let researchResult = research ?? CanonResearchResult(
            sources: [],
            keyFacts: ["No canon research available."],
            plaintiffEvidence: [],
            defendantEvidence: [],
            researchedAt: .now
        )

        if let episode = try? await debateEngine.runDebate(
            grievance: grievance, research: researchResult, guests: guests
        ) {
            saveEpisode(episode)
        }
    }

    private func saveEpisode(_ episode: Episode) {
        let episodeToSave = episode
        let store = EpisodeStore.shared
        
        let saveTask: Task<Void, Never> = Task { [episodeToSave, store] in
            // Persist to local store
            await store.addEpisode(episodeToSave)
            
            // Also sync to Convex if available
            if let convex = self.convexClient {
                let turns = episodeToSave.transcript.map { turn in
                    ["speaker": turn.speaker.displayName, "text": turn.text, "phase": turn.phase]
                }
                _ = try? await convex.mutation("episodes:insert", args: [
                    "grievanceId": episodeToSave.grievanceId,
                    "transcript": turns,
                    "finisherType": episodeToSave.finisherType?.rawValue ?? NSNull(),
                ])
            }
        }
        _ = saveTask
    }
}
