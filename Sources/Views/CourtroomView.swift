import SpriteKit
import SwiftUI

struct CourtroomView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var scene: CourtroomScene?
    @State private var showFinisher = false
    let trialCoordinator: TrialCoordinator

    var body: some View {
        ZStack {
            if let scene {
                SpriteKitView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                phaseIndicator
                Spacer()
                transcriptBubble
            }

            if showFinisher, let finisher = appState.activeEpisode?.verdict?.finisher {
                finisherOverlay(finisher)
            }
        }
        .task {
            let skScene = CourtroomScene(size: UIScreen.main.bounds.size)
            scene = skScene
            appState.courtScene = UIScreen.main.bounds
            if let grievance = appState.activeGrievance {
                await trialCoordinator.startTrial(scene: skScene, grievance: grievance)
            }
        }
    }

    private var phaseIndicator: some View {
        Text(appState.currentDebatePhase.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.yellow)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.top, 60)
    }

    private var transcriptBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let turn = appState.activeEpisode?.transcript.last {
                Text(turn.speaker.displayName)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(speakerColor(turn.speaker))
                Text(turn.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private func finisherOverlay(_ finisher: FinisherType) -> some View {
        Text(finisher.label.uppercased())
            .font(.system(size: 28, weight: .black, design: .serif))
            .foregroundColor(.red)
            .padding(20)
            .background(.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .transition(.scale.combined(with: .opacity))
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

struct SpriteKitView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}
