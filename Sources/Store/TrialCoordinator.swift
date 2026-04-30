import Foundation

@MainActor
@Observable final class TrialCoordinator {
    private let ollamaClient: OllamaMaxClient
    private let convexClient: ConvexClient
    private let debateEngine: DebateEngine
    private let researchEngine: CanonResearchEngine
    private let voiceClient: VoiceSynthesisClient
    private let guestGenerator: GuestCharacterGenerator

    init(ollamaClient: OllamaMaxClient, convexClient: ConvexClient,
         debateEngine: DebateEngine, researchEngine: CanonResearchEngine,
         voiceClient: VoiceSynthesisClient, guestGenerator: GuestCharacterGenerator) {
        self.ollamaClient = ollamaClient
        self.convexClient = convexClient
        self.debateEngine = debateEngine
        self.researchEngine = researchEngine
        self.voiceClient = voiceClient
        self.guestGenerator = guestGenerator
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
            sources: [], keyFacts: [], plaintiffEvidence: [], defendantEvidence: []
        )

        if let episode = try? await debateEngine.runDebate(
            grievance: grievance, research: researchResult, guests: guests
        ) {
            saveEpisode(episode)
        }
    }

    private func saveEpisode(_ episode: Episode) {
        Task {
            _ = try? await convexClient.mutation("episodes:insert", args: [
                "grievanceId": episode.grievanceId,
                "transcript": episode.transcript.map { turn in
                    ["speaker": turn.speaker.displayName, "text": turn.text, "phase": turn.phase]
                },
                "finisherType": episode.finisherType?.rawValue ?? NSNull(),
            ])
        }
    }
}
