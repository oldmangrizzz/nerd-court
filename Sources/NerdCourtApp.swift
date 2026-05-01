import SwiftUI

@main
struct NerdCourtApp: App {
    @State private var appState = AppState()
    private let coordinator: TrialCoordinator

    init() {
        let ollamaClient = OllamaMaxClient()
        let convexDeploymentURL = ProcessInfo.processInfo.environment["CONVEX_DEPLOYMENT_URL"] ?? ""
        let convexClient = ConvexClient(deploymentURL: convexDeploymentURL)
        self.coordinator = TrialCoordinator(
            ollamaClient: ollamaClient,
            convexClient: convexClient,
            debateEngine: DebateEngine(ollamaClient: ollamaClient),
            researchEngine: CanonResearchEngine(),
            voiceClient: VoiceSynthesisClient(),
            guestGenerator: GuestCharacterGenerator(ollamaClient: ollamaClient)
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
