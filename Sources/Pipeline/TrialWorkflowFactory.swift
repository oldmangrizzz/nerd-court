import Foundation

/// Composes the standard 5-stage trial pipeline:
/// `research → debate → persistence → playback → finisher`.
///
/// This is the n8n-style declarative graph we want for everything: the UI
/// just calls `factory.build(...).run(grievance)` and watches the events
/// stream. Each node is independently testable and swappable — debug
/// builds can replace `DebateNode` with a fixture, replay builds can skip
/// research and feed an `Episode` straight into `PlaybackNode`, etc.
@MainActor
enum TrialWorkflowFactory {
    static func build(
        grievance: Grievance,
        scene: CourtroomScene,
        voiceClient: any VoiceSynthesisServiceProtocol,
        guestGenerator: GuestCharacterGenerator,
        appState: AppState,
        llmFactory: @escaping @Sendable () -> (any LLMClient)? = defaultLLMFactory
    ) -> Workflow<ResearchNode, FinisherNode> {
        Workflow(
            name: "trial",
            ResearchNode(guestGenerator: guestGenerator),
            DebateNode(llmFactory: llmFactory),
            PersistenceNode(),
            PlaybackNode(scene: scene, voiceClient: voiceClient, appState: appState),
            FinisherNode(scene: scene,
                          plaintiff: grievance.plaintiff,
                          defendant: grievance.defendant)
        )
    }

    /// Default factory: spin up a live OllamaCloudClient if a key is configured,
    /// otherwise return nil (DebateNode falls back to ScriptedDialogueEngine).
    static let defaultLLMFactory: @Sendable () -> (any LLMClient)? = {
        let key = AppConfig.ollamaCloudApiKey
        guard !key.isEmpty else { return nil }
        return try? OllamaCloudClient(apiKey: key)
    }
}
