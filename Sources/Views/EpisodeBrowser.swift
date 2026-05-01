import SwiftUI
import Foundation

// MARK: - Episode Summary (lightweight for grid display)

struct EpisodeSummary: Codable, Identifiable {
    let id: String
    let plaintiff: String
    let defendant: String
    let verdict: Verdict
    let finisherType: FinisherType
    let viewCount: Int
    let durationSeconds: Int
    let generatedAt: Date
}

// MARK: - Episode Browser View

@MainActor
struct EpisodeBrowser: View {
    @State private var episodes: [EpisodeSummary] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let convexClient: ConvexClient

    init(convexClient: ConvexClient? = nil) {
        let url = ProcessInfo.processInfo.environment["CONVEX_DEPLOYMENT_URL"] ?? ""
        self.convexClient = convexClient ?? ConvexClient(deploymentURL: url)
    }
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var filteredEpisodes: [EpisodeSummary] {
        guard !searchText.isEmpty else { return episodes }
        return episodes.filter { episode in
            episode.plaintiff.localizedCaseInsensitiveContains(searchText) ||
            episode.defendant.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && episodes.isEmpty {
                    ProgressView("Summoning past trials…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, episodes.isEmpty {
                    ContentUnavailableView(
                        "Court Archives Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if filteredEpisodes.isEmpty {
                    ContentUnavailableView(
                        "No Episodes Found",
                        systemImage: "magnifyingglass",
                        description: Text(searchText.isEmpty
                            ? "The court docket is empty. Try again later."
                            : "No episodes match your search.")
                    )
                } else {
                    episodeGrid
                }
            }
            .navigationTitle("Past Episodes")
            .searchable(text: $searchText, prompt: "Search by plaintiff or defendant")
            .task {
                await loadEpisodes()
            }
            .refreshable {
                await loadEpisodes()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(for: EpisodeSummary.self) { episode in
                EpisodeDetailView(episodeId: episode.id)
            }
        }
    }

    private var episodeGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredEpisodes) { episode in
                    NavigationLink(value: episode) {
                        EpisodeCard(episode: episode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func loadEpisodes() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await convexClient.query("episodes/list", body: Data())
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            episodes = try decoder.decode([EpisodeSummary].self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Episode Card

struct EpisodeCard: View {
    let episode: EpisodeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(episode.plaintiff) vs \(episode.defendant)")
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
            }

            HStack {
                Image(systemName: verdictIcon)
                    .foregroundStyle(verdictColor)
                Text(episode.verdict.ruling.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(episode.finisherType.displayName)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            HStack {
                Label("\(episode.viewCount)", systemImage: "eye")
                Spacer()
                Text(episode.generatedAt, style: .date)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }

    private var verdictIcon: String {
        switch episode.verdict.ruling {
        case .plaintiffWins: return "figure.wave"
        case .defendantWins: return "figure.stand"
        case .hugItOut: return "heart"
        }
    }

    private var verdictColor: Color {
        switch episode.verdict.ruling {
        case .plaintiffWins: return .green
        case .defendantWins: return .red
        case .hugItOut: return .pink
        }
    }
}

// MARK: - Helpers for Display Names

extension Verdict.Ruling {
    var displayName: String {
        switch self {
        case .plaintiffWins: return "Plaintiff Wins"
        case .defendantWins: return "Defendant Wins"
        case .hugItOut: return "Hug It Out"
        }
    }
}

extension FinisherType {
    var displayName: String {
        switch self {
        case .crowbarBeatdown: return "Crowbar Beatdown"
        case .lazarusPitDunking: return "Lazarus Pit Dunking"
        case .deadpoolShooting: return "Deadpool Shooting"
        case .characterMorph: return "Character Morph"
        case .gavelOfDoom: return "Gavel of Doom"
        }
    }
}