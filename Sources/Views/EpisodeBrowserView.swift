import SwiftUI

struct EpisodeBrowserView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var searchText = ""
    @State private var selectedUniverse: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    ForEach(filteredEpisodes) { episode in
                        EpisodeCard(episode: episode)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Episodes")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText,
                         placement: .navigationBarDrawer(displayMode: .always),
                         prompt: "Search episodes...")
        }
    }

    private var filteredEpisodes: [Episode] {
        let episodes = appState.episodes.filter { $0.verdict != nil }
        guard !searchText.isEmpty else { return episodes }
        return episodes.filter { episode in
            episode.transcript.contains {
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct EpisodeCard: View {
    let episode: Episode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.indigo.opacity(0.4))
                .frame(height: 100)
                .overlay {
                    if let verdict = episode.verdict {
                        VStack {
                            Image(systemName: verdict.ruling == .hugItOut ? "heart.fill" : "hammer.fill")
                                .font(.title2)
                                .foregroundColor(verdict.ruling == .plaintiffWins ? .green : .orange)
                            Text(verdict.ruling == .plaintiffWins ? "PLAINTIFF WINS" :
                                    verdict.ruling == .defendantWins ? "DEFENSE WINS" : "HUG IT OUT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

            Text(episode.readableDuration)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
