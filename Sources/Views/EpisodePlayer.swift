import SwiftUI
import AVFoundation

// MARK: - Episode Player View Model

@Observable
final class EpisodePlayerViewModel {
    let episode: Episode
    var currentPlayingTurnID: String?
    var isPlaying: Bool = false
    var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?
    private var delegate: AudioPlayerDelegate?
    private var playbackContinuation: CheckedContinuation<Void, Error>?

    init(episode: Episode) {
        self.episode = episode
    }

    func playAudio(for turn: SpeechTurn) {
        guard let audioData = turn.audioData else { return }

        stopAudio()

        do {
            let player = try AVAudioPlayer(data: audioData)
            let delegate = AudioPlayerDelegate { [weak self] in
                self?.handlePlaybackFinished()
            }
            player.delegate = delegate
            self.delegate = delegate
            self.audioPlayer = player

            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player.prepareToPlay()
            player.play()

            currentPlayingTurnID = turn.id
            isPlaying = true
        } catch {
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
            stopAudio()
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        delegate = nil
        currentPlayingTurnID = nil
        isPlaying = false
        playbackContinuation?.resume(throwing: CancellationError())
        playbackContinuation = nil
    }

    func playAll() async {
        for turn in episode.transcript where turn.audioData != nil {
            guard !Task.isCancelled else { break }
            await playTurnAudio(turn: turn)
        }
    }

    private func playTurnAudio(turn: SpeechTurn) async {
        guard turn.audioData != nil else { return }
        return await withCheckedThrowingContinuation { continuation in
            self.playbackContinuation = continuation
            self.playAudio(for: turn)
        }
    }

    private func handlePlaybackFinished() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.currentPlayingTurnID = nil
            self.audioPlayer = nil
            self.delegate = nil
            self.playbackContinuation?.resume(returning: ())
            self.playbackContinuation = nil
        }
    }
}

// MARK: - Audio Player Delegate

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFinish()
    }
}

// MARK: - Episode Player View

struct EpisodePlayerView: View {
    let episode: Episode
    @State private var viewModel: EpisodePlayerViewModel

    init(episode: Episode) {
        self.episode = episode
        _viewModel = State(initialValue: EpisodePlayerViewModel(episode: episode))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Transcript") {
                    ForEach(episode.transcript) { turn in
                        SpeechTurnRow(
                            turn: turn,
                            isPlaying: viewModel.currentPlayingTurnID == turn.id && viewModel.isPlaying,
                            onPlay: { viewModel.playAudio(for: turn) },
                            onStop: { viewModel.stopAudio() }
                        )
                    }
                }

                Section("Verdict") {
                    VerdictView(verdict: episode.verdict)
                }
            }
            .navigationTitle("Episode Replay")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.playAll()
                        }
                    } label: {
                        Label("Play All", systemImage: "play.fill")
                    }
                    .disabled(viewModel.isPlaying)
                }
            }
            .alert("Playback Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Speech Turn Row

struct SpeechTurnRow: View {
    let turn: SpeechTurn
    let isPlaying: Bool
    let onPlay: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(turn.speaker.displayName)
                    .font(.headline)
                Text(turn.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if turn.audioData != nil {
                Button {
                    if isPlaying {
                        onStop()
                    } else {
                        onPlay()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Verdict View

struct VerdictView: View {
    let verdict: Verdict

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ruling:")
                    .fontWeight(.semibold)
                Text(verdict.ruling.displayName)
                    .foregroundStyle(.primary)
            }
            Text(verdict.reasoning)
                .font(.body)
            Text("Final Thought: \(verdict.finalThought)")
                .font(.callout)
                .italic()
        }
    }
}

// MARK: - Speaker Display Name

extension Speaker {
    var displayName: String {
        switch self {
        case .jasonTodd: return "Jason Todd"
        case .mattMurdock: return "Matt Murdock"
        case .judgeJerry: return "Judge Jerry"
        case .deadpool: return "Deadpool"
        case .guest(let id, let name): return name
        }
    }
}

// MARK: - Verdict Ruling Display Name

extension Verdict.Ruling {
    var displayName: String {
        switch self {
        case .plaintiffWins: return "Plaintiff Wins"
        case .defendantWins: return "Defendant Wins"
        case .hugItOut: return "Hug It Out"
        }
    }
}