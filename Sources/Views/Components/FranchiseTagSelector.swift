import SwiftUI

// MARK: - Franchise Model

enum Franchise: String, Codable, CaseIterable, Identifiable, Hashable {
    case marvel = "marvel"
    case dc = "dc"
    case starWars = "star_wars"
    case lotr = "lotr"
    case harryPotter = "harry_potter"
    case gameOfThrones = "game_of_thrones"
    case starTrek = "star_trek"
    case anime = "anime"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .marvel: return "Marvel"
        case .dc: return "DC"
        case .starWars: return "Star Wars"
        case .lotr: return "Lord of the Rings"
        case .harryPotter: return "Harry Potter"
        case .gameOfThrones: return "Game of Thrones"
        case .starTrek: return "Star Trek"
        case .anime: return "Anime"
        case .other: return "Other"
        }
    }
    
    var color: Color {
        switch self {
        case .marvel: return .red
        case .dc: return .blue
        case .starWars: return .yellow
        case .lotr: return .green
        case .harryPotter: return .purple
        case .gameOfThrones: return .gray
        case .starTrek: return .teal
        case .anime: return .pink
        case .other: return .orange
        }
    }
}

// MARK: - Franchise Tag Selector View

struct FranchiseTagSelector: View {
    @Binding var selectedFranchise: Franchise?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Franchise.allCases) { franchise in
                    FranchiseTag(
                        franchise: franchise,
                        isSelected: selectedFranchise == franchise,
                        action: {
                            selectedFranchise = franchise
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Individual Tag

struct FranchiseTag: View {
    let franchise: Franchise
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(franchise.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? franchise.color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(franchise.color.opacity(0.5), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: Franchise? = nil
        
        var body: some View {
            VStack {
                FranchiseTagSelector(selectedFranchise: $selected)
                if let selected {
                    Text("Selected: \(selected.displayName)")
                        .padding()
                }
            }
        }
    }
    
    return PreviewWrapper()
}