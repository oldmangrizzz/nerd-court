import SpriteKit
import SwiftUI

struct CourtroomView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var scene: CourtroomScene?
    @State private var showFinisher = false
    @State private var showVerdict = false
    @State private var transcriptOpacity: Double = 0
    @State private var progressValue: Double = 0
    let trialCoordinator: TrialCoordinator

    private let totalDebatePhases: Double = 14

    var body: some View {
        ZStack {
            // SpriteKit layer
            if let scene {
                SpriteKitView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // UI overlay
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomSection
            }

            // Verdict reveal
            if showVerdict, let verdict = appState.activeEpisode?.verdict {
                verdictOverlay(verdict)
            }

            // Finisher animation label
            if showFinisher, let finisher = appState.activeEpisode?.finisherType {
                finisherOverlay(finisher)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showVerdict)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showFinisher)
        .task {
            let skScene = CourtroomScene(size: UIScreen.main.bounds.size)
            scene = skScene
            appState.courtScene = UIScreen.main.bounds
            if let grievance = appState.activeGrievance {
                await trialCoordinator.startTrial(scene: skScene, grievance: grievance)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Phase indicator
            Text(appState.currentDebatePhase.displayName.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.75))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.yellow.opacity(0.3), lineWidth: 1))

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.15))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressValue, height: 3)
                        .animation(.easeInOut(duration: 0.8), value: progressValue)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 8) {
            // Character roster
            characterRoster
                .padding(.horizontal, 20)

            // Transcript bubble
            transcriptBubble
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
        .onChange(of: appState.currentDebatePhase) { _, newPhase in
            progressValue = newPhase.progressFraction
        }
    }

    // MARK: - Character Roster

    private var characterRoster: some View {
        HStack(spacing: 12) {
            CharacterChip(name: "JASON", color: .red, isActive: isJasonActive)
            CharacterChip(name: "MATT", color: .red.opacity(0.7), isActive: isMattActive)
            CharacterChip(name: "JERRY", color: .yellow, isActive: appState.currentDebatePhase == .verdictAnnouncement)
            CharacterChip(name: "DP", color: .pink, isActive: isDeadpoolActive)

            if let guests = appState.activeEpisode?.transcript.compactMap({ $0.speaker }).uniqueGuests,
               !guests.isEmpty {
                ForEach(Array(guests.prefix(2)), id: \.self) { guest in
                    CharacterChip(name: guest.initials, color: .cyan, isActive: false)
                }
            }
        }
    }

    // MARK: - Transcript Bubble

    private var transcriptBubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let turn = appState.activeEpisode?.transcript.last {
                HStack(spacing: 8) {
                    Circle()
                        .fill(speakerColor(turn.speaker))
                        .frame(width: 8, height: 8)

                    Text(turn.speaker.displayName.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(speakerColor(turn.speaker))

                    Spacer()

                    Text(turn.timestamp, style: .time)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }

                Text(turn.text)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(5)
                    .opacity(transcriptOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.3)) { transcriptOpacity = 1 }
                    }
                    .onChange(of: turn.text) { _, _ in
                        transcriptOpacity = 0
                        withAnimation(.easeIn(duration: 0.3)) { transcriptOpacity = 1 }
                    }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Verdict Overlay

    private func verdictOverlay(_ verdict: Verdict) -> some View {
        VStack(spacing: 20) {
            Text(verdict.rulingDisplay.uppercased())
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundColor(verdict.rulingColor)

            Text("""
"\(verdict.judgeJerryWisdom)"
""")
                .font(.system(size: 18, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("— Judge Jerry Springer")
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.85))
        .transition(.opacity)
    }

    // MARK: - Finisher Overlay

    private func finisherOverlay(_ finisher: FinisherType) -> some View {
        VStack(spacing: 8) {
            Image(systemName: finisher.iconName)
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text(finisher.label.uppercased())
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundColor(.red)
        }
        .padding(24)
        .background(.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.4), lineWidth: 2)
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Helpers

    private var isJasonActive: Bool {
        [.openingStatement, .closingArguments, .crossExamination].contains(appState.currentDebatePhase)
    }

    private var isMattActive: Bool {
        [.openingStatement, .closingArguments, .crossExamination].contains(appState.currentDebatePhase)
    }

    private var isDeadpoolActive: Bool {
        [.finisherExecution, .deadpoolWrapUp].contains(appState.currentDebatePhase)
    }

    private func speakerColor(_ speaker: Speaker) -> Color {
        switch speaker {
        case .jasonTodd: .red
        case .mattMurdock: .red.opacity(0.8)
        case .judgeJerry: .yellow
        case .deadpool: .pink
        case .guest: .cyan
        }
    }
}

// MARK: - Character Chip

struct CharacterChip: View {
    let name: String
    let color: Color
    let isActive: Bool

    var body: some View {
        Text(name)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(isActive ? .black : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? color : color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(isActive ? 1 : 0.3), lineWidth: 1)
            )
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

// MARK: - SpriteKit View Bridge

struct SpriteKitView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.showsFPS = false
        view.showsNodeCount = false
        view.allowsTransparency = true
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}

// MARK: - Extensions for UI support

extension DebatePhase {
    var displayName: String {
        switch self {
        case .intake: "Intake"
        case .canonResearch: "Canon Research"
        case .openingStatement: "Opening Statement"
        case .witnessTestimony: "Witness Testimony"
        case .crossExamination: "Cross Examination"
        case .evidencePresentation: "Evidence"
        case .objections: "Objections"
        case .closingArguments: "Closing Arguments"
        case .juryDeliberation: "Jury Deliberation"
        case .verdictAnnouncement: "Verdict"
        case .finisherExecution: "Finisher"
        case .postTrialCommentary: "Commentary"
        case .deadpoolWrapUp: "Deadpool Wrap"
        case .complete: "Complete"
        }
    }

    var progressFraction: Double {
        switch self {
        case .intake: 0.0
        case .canonResearch: 0.07
        case .openingStatement: 0.14
        case .witnessTestimony: 0.28
        case .crossExamination: 0.42
        case .evidencePresentation: 0.50
        case .objections: 0.57
        case .closingArguments: 0.64
        case .juryDeliberation: 0.78
        case .verdictAnnouncement: 0.85
        case .finisherExecution: 0.92
        case .postTrialCommentary: 0.96
        case .deadpoolWrapUp: 0.98
        case .complete: 1.0
        }
    }
}

extension Verdict {
    var rulingDisplay: String {
        switch ruling {
        case .plaintiffWins: "Plaintiff Wins!"
        case .defendantWins: "Defendant Wins!"
        case .hugItOut: "Hug It Out!"
        }
    }

    var rulingColor: Color {
        switch ruling {
        case .plaintiffWins: .green
        case .defendantWins: .blue
        case .hugItOut: .yellow
        }
    }
}

extension FinisherType {
    var iconName: String {
        switch self {
        case .crowbarBeatdown: "hammer.fill"
        case .lazarusPitDunking: "drop.fill"
        case .deadpoolShooting: "target"
        case .characterMorph: "theatermask.and.paintbrush.fill"
        case .gavelOfDoom: "scalemass.fill"
        }
    }
    
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

extension Array where Element == Speaker {
    var uniqueGuests: [Speaker] {
        var seen = Set<Speaker>()
        return filter { speaker in
            if case .guest = speaker, !seen.contains(speaker) {
                seen.insert(speaker)
                return true
            }
            return false
        }
    }
}

extension Speaker {
    var initials: String {
        switch self {
        case .jasonTodd: "JT"
        case .mattMurdock: "MM"
        case .judgeJerry: "JJ"
        case .deadpool: "DP"
        case .guest(_, let name): String(name.prefix(2)).uppercased()
        }
    }
}
