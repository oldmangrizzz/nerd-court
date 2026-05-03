import SwiftUI

@main
struct NerdCourtApp: App {
    @State private var appState = AppState()
    private let coordinator: TrialCoordinator

    init() {
        self.coordinator = TrialCoordinator(
            voiceClient: VoiceSynthesisClient(),
            guestGenerator: GuestCharacterGenerator()
        )
        // Self-heal F5-TTS voice registry on cold-started Cloud Run instances.
        // Fire-and-forget: synthesis falls back to local TTS if this races,
        // but on the next trial the staff voices are already there.
        if let replay = VoiceRegistryReplay.fromInfoPlist() {
            Task.detached(priority: .utility) {
                _ = await replay.ensureStaffVoicesRegistered()
            }
        }
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
