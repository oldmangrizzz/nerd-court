import SwiftUI

// MARK: - Verdict Reveal View

/// A dramatic full-screen overlay that reveals the trial verdict with a push transition and color shift.
/// Displays the ruling, reasoning, final thought, and a finisher icon.
/// Tapping the background or the "Witness the Finisher" button dismisses the view.
struct VerdictRevealView: View {
    let verdict: Verdict
    let finisherType: FinisherType
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var cardOffset: CGFloat = UIScreen.main.bounds.width
    @State private var cardScale: CGFloat = 0.8
    @State private var backgroundOpacity: Double = 0
    @State private var gradientEnd: Color = .black
    @State private var verdictScale: CGFloat = 1.0
    @State private var gavelRotation: Double = -30
    @State private var gavelOpacity: Double = 0
    @State private var isDismissing = false

    private let rulingColor: Color
    private let finisherSymbol: String

    init(verdict: Verdict, finisherType: FinisherType, onDismiss: @escaping () -> Void) {
        self.verdict = verdict
        self.finisherType = finisherType
        self.onDismiss = onDismiss

        switch verdict.ruling {
        case .plaintiffWins:
            rulingColor = .green
        case .defendantWins:
            rulingColor = .red
        case .hugItOut:
            rulingColor = .purple
        }

        switch finisherType {
        case .crowbarBeatdown:
            finisherSymbol = "hammer"
        case .lazarusPitDunking:
            finisherSymbol = "drop.fill"
        case .deadpoolShooting:
            finisherSymbol = "target"
        case .characterMorph:
            finisherSymbol = "person.fill.questionmark"
        case .gavelOfDoom:
            finisherSymbol = "hammer.fill"
        }
    }

    var body: some View {
        ZStack {
            // Background: fades from black to a gradient based on ruling
            Group {
                if isVisible {
                    LinearGradient(
                        colors: [.black, gradientEnd],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .transition(.opacity)
                } else {
                    Color.black
                }
            }
            .opacity(backgroundOpacity)
            .animation(.easeInOut(duration: 1.5), value: isVisible)
            .ignoresSafeArea()

            // Main card
            VStack(spacing: 24) {
                // Gavel icon with dramatic entrance
                Image(systemName: finisherSymbol)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(rulingColor)
                    .rotationEffect(.degrees(gavelRotation))
                    .opacity(gavelOpacity)
                    .scaleEffect(gavelOpacity == 1 ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3), value: gavelRotation)
                    .animation(.easeOut(duration: 0.3), value: gavelOpacity)

                Text("VERDICT")
                    .font(.system(.largeTitle, design: .serif, weight: .black))
                    .foregroundColor(.white)
                    .tracking(4)

                Text(rulingText)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundColor(rulingColor)
                    .multilineTextAlignment(.center)
                    .scaleEffect(verdictScale)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: verdictScale)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Reasoning", systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text(verdict.reasoning)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)

                    Label("Final Thought", systemImage: "quote.bubble")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text(verdict.finalThought)
                        .font(.body.italic())
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: rulingColor.opacity(0.3), radius: 10)

                Button {
                    dismissWithAnimation()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Witness the Finisher")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(rulingColor, in: Capsule())
                    .foregroundColor(.white)
                    .shadow(color: rulingColor.opacity(0.6), radius: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(rulingColor.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: rulingColor.opacity(0.4), radius: 20)
            .offset(x: cardOffset)
            .scaleEffect(cardScale)
            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3), value: cardOffset)
            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3), value: cardScale)
            .onTapGesture { /* absorb taps on card to prevent background dismissal */ }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissWithAnimation()
        }
        .onAppear(perform: appear)
        .onChange(of: isDismissing) { _, dismissing in
            if dismissing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onDismiss()
                }
            }
        }
    }

    private var rulingText: String {
        switch verdict.ruling {
        case .plaintiffWins:
            return "Plaintiff Wins!"
        case .defendantWins:
            return "Defendant Wins!"
        case .hugItOut:
            return "Hug It Out!"
        }
    }

    private func appear() {
        withAnimation(.easeOut(duration: 0.8)) {
            isVisible = true
            backgroundOpacity = 1
            gradientEnd = rulingColor
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)) {
            cardOffset = 0
            cardScale = 1
        }
        // Gavel entrance after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3)) {
                gavelRotation = 0
                gavelOpacity = 1
            }
        }
        // Subtle pulse on verdict text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                verdictScale = 1.05
            }
        }
    }

    private func dismissWithAnimation() {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(.easeIn(duration: 0.4)) {
            cardOffset = UIScreen.main.bounds.width
            cardScale = 0.8
            backgroundOpacity = 0
            gavelOpacity = 0
        }
    }
}

// MARK: - Preview

#Preview {
    VerdictRevealView(
        verdict: Verdict(
            ruling: .plaintiffWins,
            reasoning: "After careful analysis of canon precedents, the plaintiff's argument holds more weight. The defendant's reliance on retcon material was deemed inadmissible.",
            finalThought: "In the end, the truth is like a crowbar to the face — it hurts, but you can't ignore it.",
            finisherType: .crowbarBeatdown
        ),
        finisherType: .crowbarBeatdown,
        onDismiss: { print("Dismissed") }
    )
    .preferredColorScheme(.dark)
}