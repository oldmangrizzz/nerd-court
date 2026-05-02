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
                await trialCoordinator.startTrial(scene: skScene, grievance: grievance, appState: appState)
            }
        }
        .onChange(of: appState.activeGrievance) { _, newGrievance in
            if let newGrievance, let skScene = scene {
                Task {
                    await trialCoordinator.startTrial(scene: skScene, grievance: newGrievance, appState: appState)
                }
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
            characterPortraitChip(speaker: .jasonTodd, isActive: isJasonActive)
            characterPortraitChip(speaker: .mattMurdock, isActive: isMattActive)
            characterPortraitChip(speaker: .judgeJerry, isActive: appState.currentDebatePhase == .verdictAnnouncement)
            characterPortraitChip(speaker: .deadpool, isActive: isDeadpoolActive)

            if let guests = appState.activeEpisode?.transcript.compactMap({ $0.speaker }).uniqueGuests,
               !guests.isEmpty {
                ForEach(Array(guests.prefix(2)), id: \.self) { guest in
                    characterPortraitChip(speaker: guest, isActive: false)
                }
            }
        }
    }

    private func characterPortraitChip(speaker: Speaker, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                CharacterPortraitShape(speaker: speaker)
                    .fill(CharacterPortraitShape(speaker: speaker).fillColor(for: speaker))
                    .shadow(color: .white.opacity(isActive ? 0.5 : 0.15), radius: isActive ? 8 : 2)
                CharacterPortraitShape(speaker: speaker)
                    .stroke(.white, lineWidth: 2)
                Text(speaker.initials)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)

            Text(speaker.initials)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
        }
    }

    // MARK: - Transcript Bubble

    private var transcriptBubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let turn = appState.activeEpisode?.transcript.last {
                HStack(spacing: 8) {
                    ZStack {
                        CharacterPortraitShape(speaker: turn.speaker)
                            .fill(CharacterPortraitShape(speaker: turn.speaker).fillColor(for: turn.speaker))
                        CharacterPortraitShape(speaker: turn.speaker)
                            .stroke(.white, lineWidth: 1.5)
                        Text(turn.speaker.initials)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 24, height: 24)

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
        ZStack {
            // Dramatic color shift background
            LinearGradient(
                colors: [.black, verdict.rulingColor.opacity(0.6), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                CharacterPortraitShape(speaker: .judgeJerry)
                    .frame(width: 120, height: 120)
                    .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 0)

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    // MARK: - Finisher Overlay

    private func finisherOverlay(_ finisher: FinisherType) -> some View {
        ZStack {
            // Red vignette background
            RadialGradient(
                colors: [.red.opacity(0.7), .black],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: finisher.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.6), radius: 12, x: 0, y: 0)

                Text(finisher.label.uppercased())
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundColor(.red)

                Text(finisher.displayName.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Character Portrait Shape (SwiftUI)

struct CharacterPortraitShape: Shape {
    let speaker: Speaker

    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY
        let half = size / 2

        switch speaker {
        case .jasonTodd:
            return jaggedHexagon(cx: cx, cy: cy, half: half)
        case .mattMurdock:
            return shield(cx: cx, cy: cy, half: half)
        case .judgeJerry:
            return gavel(in: rect)
        case .deadpool:
            return chaoticStar(cx: cx, cy: cy, half: half)
        case .guest:
            return roundedDiamond(cx: cx, cy: cy, half: half)
        }
    }

    private func jaggedHexagon(cx: CGFloat, cy: CGFloat, half: CGFloat) -> Path {
        var path = Path()
        let points = 6
        let inner = half * 0.55
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let r = (i % 2 == 0) ? half : inner
            let x = cx + r * cos(angle)
            let y = cy + r * sin(angle)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }

    private func shield(cx: CGFloat, cy: CGFloat, half: CGFloat) -> Path {
        var path = Path()
        let topY = cy - half + half * 0.3
        let bottomY = cy + half
        let leftX = cx - half + half * 0.1
        let rightX = cx + half - half * 0.1
        path.move(to: CGPoint(x: leftX, y: topY))
        path.addQuadCurve(to: CGPoint(x: rightX, y: topY),
                          control: CGPoint(x: cx, y: cy - half - half * 0.1))
        path.addLine(to: CGPoint(x: rightX, y: topY + half * 0.8))
        path.addLine(to: CGPoint(x: cx, y: bottomY))
        path.addLine(to: CGPoint(x: leftX, y: topY + half * 0.8))
        path.closeSubpath()
        return path
    }

    private func gavel(in rect: CGRect) -> Path {
        var path = Path()
        let headW = rect.width * 0.85
        let headH = rect.height * 0.55
        let headRect = CGRect(
            x: rect.midX - headW / 2,
            y: rect.midY - headH / 2,
            width: headW,
            height: headH
        )
        path.addRoundedRect(in: headRect, cornerSize: CGSize(width: 8, height: 8))
        let handleW = rect.width * 0.35
        let handleH = rect.height * 0.22
        let handleRect = CGRect(
            x: rect.midX + headW / 2 - 4,
            y: rect.midY - handleH / 2,
            width: handleW,
            height: handleH
        )
        path.addRoundedRect(in: handleRect, cornerSize: CGSize(width: 4, height: 4))
        return path
    }

    private func chaoticStar(cx: CGFloat, cy: CGFloat, half: CGFloat) -> Path {
        var path = Path()
        let points = 5
        let inner = half * 0.45
        let warps: [CGFloat] = [0.92, 1.08, 0.88, 1.12, 0.95, 1.05, 0.90, 1.10, 0.97, 1.03]
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let base = (i % 2 == 0) ? half : inner
            let r = base * warps[i % warps.count]
            let x = cx + r * cos(angle)
            let y = cy + r * sin(angle)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }

    private func roundedDiamond(cx: CGFloat, cy: CGFloat, half: CGFloat) -> Path {
        var path = Path()
        let p1 = CGPoint(x: cx, y: cy - half)
        let p2 = CGPoint(x: cx + half, y: cy)
        let p3 = CGPoint(x: cx, y: cy + half)
        let p4 = CGPoint(x: cx - half, y: cy)
        let t: CGFloat = 0.15

        func midpoint(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }

        path.move(to: midpoint(p1, p2, t: t))
        path.addQuadCurve(to: midpoint(p2, p3, t: t), control: p2)
        path.addQuadCurve(to: midpoint(p3, p4, t: t), control: p3)
        path.addQuadCurve(to: midpoint(p4, p1, t: t), control: p4)
        path.addQuadCurve(to: midpoint(p1, p2, t: t), control: p1)
        path.closeSubpath()
        return path
    }
}

extension CharacterPortraitShape {
    func fillColor(for speaker: Speaker) -> Color {
        switch speaker {
        case .jasonTodd: Color(red: 0.86, green: 0.08, blue: 0.24)
        case .mattMurdock: Color(red: 0.70, green: 0.13, blue: 0.13)
        case .judgeJerry: Color(red: 1.0, green: 0.84, blue: 0.0)
        case .deadpool: Color(red: 1.0, green: 0.08, blue: 0.58)
        case .guest: Color(red: 0.0, green: 0.81, blue: 0.82)
        }
    }
}

// MARK: - Character Portrait Chip View

struct CharacterPortraitChip: View {
    let speaker: Speaker
    let isActive: Bool

    var body: some View {
        ZStack {
            CharacterPortraitShape(speaker: speaker)
                .fill(CharacterPortraitShape(speaker: speaker).fillColor(for: speaker))
                .overlay(
                    CharacterPortraitShape(speaker: speaker)
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: .white.opacity(0.3), radius: isActive ? 8 : 2)

            Text(speaker.initials)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(width: 44, height: 44)
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
