import SwiftUI

@main
struct NerdCourtApp: App {
    @State private var appState = AppState()
    private let coordinator: TrialCoordinator

    init() {
        let deltaHost = ProcessInfo.processInfo.environment["DELTA_HOST"] ?? "delta.local"
        let dispatchClient = DeltaDispatchClient(deltaHost: deltaHost)
        let rotationClient = OllamaMaxClient()
        let convexDeploymentURL = ProcessInfo.processInfo.environment["CONVEX_DEPLOYMENT_URL"]
        let convexClient: ConvexClient? = convexDeploymentURL.map { ConvexClient(deploymentURL: $0) }
        // Pass dispatchClient directly - TrialCoordinator will create GuestCharacterGenerator internally
        self.coordinator = TrialCoordinator(
            ollamaClient: dispatchClient,
            convexClient: convexClient,
            debateEngine: DebateEngine(ollamaClient: rotationClient),
            researchEngine: CanonResearchEngine(),
            voiceClient: VoiceSynthesisClient()
        )
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                IntakeScreen()
                    .tabItem { Label("File", systemImage: "hammer.fill") }

                CourtroomView(trialCoordinator: coordinator)
                    .tabItem { Label("Courtroom", systemImage: "building.columns.fill") }

                EpisodeBrowserView()
                    .tabItem { Label("Episodes", systemImage: "tv.fill") }
            }
            .environment(appState)
        }
    }
}
