import SwiftUI

/// A warm, direct-to-camera overlay where Judge Jerry delivers his final thought.
/// Displays Jerry's avatar, a typewriter-revealed message, and a dismiss button.
struct FinalThoughtOverlay: View {
    let finalThought: String
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)? = nil

    @State private var displayedText: String = ""
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Content card
            VStack(spacing: 24) {
                // Jerry's avatar (placeholder using SF Symbol)
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.orange)
                    .background(Circle().fill(.white))
                    .clipShape(Circle())
                    .shadow(color: .orange.opacity(0.5), radius: 10, y: 5)

                Text("Judge Jerry")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                // Typewriter text
                ScrollView {
                    Text(displayedText)
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 200)

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.horizontal)
            }
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .padding(.horizontal, 40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                opacity = 1
                scale = 1
            }
            startTypewriter()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
        onDismiss?()
    }

    private func startTypewriter() {
        displayedText = ""
        let characters = Array(finalThought)
        guard !characters.isEmpty else { return }

        Task {
            for char in characters {
                await MainActor.run {
                    displayedText.append(char)
                }
                try? await Task.sleep(for: .milliseconds(40))
            }
        }
    }
}

#if DEBUG
struct FinalThoughtOverlay_Previews: PreviewProvider {
    static var previews: some View {
        FinalThoughtOverlay(
            finalThought: "Sometimes the real victory is the friends we made along the way. Case dismissed with a hug.",
            isPresented: .constant(true)
        )
        .preferredColorScheme(.dark)
    }
}
#endif