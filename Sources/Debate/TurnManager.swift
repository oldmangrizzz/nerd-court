import Foundation

// MARK: - Debate Phase Definition

enum DebatePhase: String, Codable, CaseIterable {
    case openingStatement
    case plaintiffArgument
    case defendantArgument
    case crossExamination
    case closingStatement
    case verdict
    case finished

    var next: DebatePhase? {
        guard let currentIndex = Self.allCases.firstIndex(of: self),
              currentIndex + 1 < Self.allCases.count else {
            return nil
        }
        return Self.allCases[currentIndex + 1]
    }
}

// MARK: - Turn Manager

actor TurnManager {
    private let guestCast: [GuestCharacter]
    private var guestIndices: [GuestRole: Int] = [:]
    private var turnCount: Int = 0

    init(guestCast: [GuestCharacter]) {
        self.guestCast = guestCast
    }

    // MARK: - Phase Routing

    /// Returns the next phase in the debate sequence, or nil if already finished.
    func nextPhase(after currentPhase: DebatePhase) -> DebatePhase? {
        return currentPhase.next
    }

    // MARK: - Speaker Selection

    /// Determines which speaker should talk next based on the current phase.
    /// - Parameter phase: The active debate phase.
    /// - Returns: The `Speaker` who will deliver the next turn.
    func getNextSpeaker(phase: DebatePhase) -> Speaker {
        switch phase {
        case .openingStatement:
            return .judgeJerry

        case .plaintiffArgument:
            if let guest = nextGuest(for: .plaintiffWitness) {
                return .guest(id: guest.id, name: guest.name)
            }
            return .jasonTodd

        case .defendantArgument:
            if let guest = nextGuest(for: .defendantWitness) {
                return .guest(id: guest.id, name: guest.name)
            }
            return .mattMurdock

        case .crossExamination:
            // Alternate between plaintiff and defendant attorneys
            if turnCount % 2 == 0 {
                return .jasonTodd
            } else {
                return .mattMurdock
            }

        case .closingStatement, .verdict:
            return .judgeJerry

        case .finished:
            preconditionFailure("No speaker available – debate has finished.")
        }
    }

    // MARK: - Deadpool Interjection

    /// Returns `true` roughly 25–30% of the time, indicating Deadpool should interject.
    func shouldInterject() -> Bool {
        Double.random(in: 0...1) < 0.275
    }

    // MARK: - Turn Counting

    /// Increments the internal turn counter. Call after each turn is completed.
    func incrementTurnCount() {
        turnCount += 1
    }

    // MARK: - Private Helpers

    private func nextGuest(for role: GuestRole) -> GuestCharacter? {
        let candidates = guestCast.filter { $0.role == role }
        guard !candidates.isEmpty else { return nil }

        let currentIndex = guestIndices[role] ?? 0
        let guest = candidates[currentIndex % candidates.count]
        guestIndices[role] = (currentIndex + 1) % candidates.count
        return guest
    }
}