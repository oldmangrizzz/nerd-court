import SwiftUI

@main
struct NerdCourtApp: App {
    @State private var appState = AppState()
    private let coordinator: TrialCoordinator

    init() {
        let rotationClient = OllamaMaxClient()
        let convexClient = ConvexClient(deploymentURL: AppConfig.convexDeploymentURL)
        self.coordinator = TrialCoordinator(
            ollamaClient: rotationClient,
            convexClient: convexClient,
            debateEngine: DebateEngine(ollamaClient: rotationClient),
            researchEngine: CanonResearchEngine(),
            voiceClient: VoiceSynthesisClient()
        )
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $appState.selectedTab) {
                IntakeScreen()
                    .tabItem { Label("File", systemImage: "hammer.fill") }
                    .tag(0)

                CourtroomView(trialCoordinator: coordinator)
                    .tabItem { Label("Courtroom", systemImage: "building.columns.fill") }
                    .tag(1)

                EpisodeBrowserView()
                    .tabItem { Label("Episodes", systemImage: "tv.fill") }
                    .tag(2)
            }
            .environment(appState)
        }
    }
}
