import SwiftUI

// MARK: - SpeechBubble View

/// An animated speech bubble with character-specific coloring and a directional tail.
struct SpeechBubble: View {
    let text: String
    let speaker: Speaker
    let isActive: Bool
    let alignment: HorizontalAlignment

    var body: some View {
        HStack(spacing: 0) {
            if alignment == .trailing {
                Spacer(minLength: 40)
            }

            VStack(alignment: alignment == .leading ? .leading : .trailing, spacing: 4) {
                Text(text)
                    .font(.body)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundColor(foregroundColor)
                    .clipShape(BubbleShape(tailAlignment: alignment))
                    .shadow(color: shadowColor, radius: isActive ? 6 : 2, x: 0, y: 2)
                    .scaleEffect(isActive ? 1.03 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            }
            .padding(.vertical, 4)

            if alignment == .leading {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 8)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Speaker-based styling

    private var backgroundColor: Color {
        switch speaker {
        case .jasonTodd:
            return Color(red: 0.8, green: 0.1, blue: 0.1) // Red Hood red
        case .mattMurdock:
            return Color(red: 0.6, green: 0.1, blue: 0.1) // Daredevil maroon
        case .judgeJerry:
            return Color(red: 0.4, green: 0.2, blue: 0.6) // Judge purple
        case .deadpool:
            return Color(red: 0.85, green: 0.15, blue: 0.15) // Deadpool red
        case .guest(let id, let name):
            // Generate a stable color from the guest's identity
            let hash = abs("\(id)\(name)".hashValue)
            let hue = Double(hash % 360) / 360.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.8)
        }
    }

    private var foregroundColor: Color {
        // White text for dark backgrounds, black for light ones
        backgroundColor.luminance > 0.5 ? .black : .white
    }

    private var shadowColor: Color {
        backgroundColor.opacity(0.5)
    }
}

// MARK: - Bubble Shape with Tail

private struct BubbleShape: Shape {
    let tailAlignment: HorizontalAlignment
    private let tailWidth: CGFloat = 10
    private let tailHeight: CGFloat = 12
    private let cornerRadius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let tailW = tailWidth
        let tailH = tailHeight

        // Main bubble rectangle (inset to leave room for tail)
        let bubbleRect: CGRect
        let tailOrigin: CGPoint

        if tailAlignment == .leading {
            // Tail on left side
            bubbleRect = CGRect(
                x: rect.minX + tailW,
                y: rect.minY,
                width: rect.width - tailW,
                height: rect.height
            )
            tailOrigin = CGPoint(x: rect.minX + tailW, y: rect.midY)
        } else {
            // Tail on right side
            bubbleRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width - tailW,
                height: rect.height
            )
            tailOrigin = CGPoint(x: rect.maxX - tailW, y: rect.midY)
        }

        // Draw rounded rectangle for main body
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: r, height: r))

        // Draw tail triangle
        let tailTip: CGPoint
        let tailBaseTop: CGPoint
        let tailBaseBottom: CGPoint

        if tailAlignment == .leading {
            tailTip = CGPoint(x: rect.minX, y: tailOrigin.y)
            tailBaseTop = CGPoint(x: bubbleRect.minX, y: tailOrigin.y - tailH / 2)
            tailBaseBottom = CGPoint(x: bubbleRect.minX, y: tailOrigin.y + tailH / 2)
        } else {
            tailTip = CGPoint(x: rect.maxX, y: tailOrigin.y)
            tailBaseTop = CGPoint(x: bubbleRect.maxX, y: tailOrigin.y - tailH / 2)
            tailBaseBottom = CGPoint(x: bubbleRect.maxX, y: tailOrigin.y + tailH / 2)
        }

        path.move(to: tailTip)
        path.addLine(to: tailBaseTop)
        path.addLine(to: tailBaseBottom)
        path.closeSubpath()

        return path
    }
}

// MARK: - Color Luminance Helper

private extension Color {
    /// Approximate luminance to decide foreground color.
    var luminance: Double {
        // Convert to NSColor/UIColor to extract components
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        // Relative luminance formula
        return 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
    }
}

// MARK: - Preview

#if DEBUG
struct SpeechBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SpeechBubble(
                text: "I'm telling you, the Batmobile's warranty doesn't cover crowbar dents!",
                speaker: .jasonTodd,
                isActive: true,
                alignment: .leading
            )

            SpeechBubble(
                text: "Your honor, my client clearly states in subsection 3 that 'acts of vigilante justice' are covered.",
                speaker: .mattMurdock,
                isActive: false,
                alignment: .trailing
            )

            SpeechBubble(
                text: "OVERRULED! I'll allow it because it's funny.",
                speaker: .judgeJerry,
                isActive: true,
                alignment: .leading
            )

            SpeechBubble(
                text: "Did someone say chimichangas?",
                speaker: .deadpool,
                isActive: false,
                alignment: .trailing
            )

            SpeechBubble(
                text: "As a guest star, I demand more screen time!",
                speaker: .guest(id: "g1", name: "Stan Lee"),
                isActive: true,
                alignment: .leading
            )
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
#endif