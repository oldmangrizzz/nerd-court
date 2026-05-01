import SwiftUI

/// A single character slot displaying a portrait and name for a courtroom participant.
struct CharacterSlot: View {
    let speaker: Speaker
    var portrait: Image? = nil
    var size: CGFloat = 80

    private var displayName: String {
        switch speaker {
        case .jasonTodd: return "Jason Todd"
        case .mattMurdock: return "Matt Murdock"
        case .judgeJerry: return "Judge Jerry"
        case .deadpool: return "Deadpool"
        case .guest(_, let name): return name
        }
    }

    private var initials: String {
        let components = displayName.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }

    private var defaultSystemImage: String {
        switch speaker {
        case .jasonTodd: return "figure.martial.arts"
        case .mattMurdock: return "figure.walk"
        case .judgeJerry: return "hammer"
        case .deadpool: return "theatermasks"
        case .guest: return "person.fill.questionmark"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            portraitCircle
                .frame(width: size, height: size)
            Text(displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Character: \(displayName)")
    }

    @ViewBuilder
    private var portraitCircle: some View {
        if let portrait = portrait {
            portrait
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        } else {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: defaultSystemImage)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }

    private var gradientColors: [Color] {
        switch speaker {
        case .jasonTodd: return [.red, .orange]
        case .mattMurdock: return [.red, .pink]
        case .judgeJerry: return [.purple, .indigo]
        case .deadpool: return [.red, .black]
        case .guest: return [.gray, .secondary]
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        CharacterSlot(speaker: .jasonTodd)
        CharacterSlot(speaker: .mattMurdock)
        CharacterSlot(speaker: .judgeJerry)
        CharacterSlot(speaker: .deadpool)
        CharacterSlot(speaker: .guest(id: "g1", name: "Spider-Man"))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}