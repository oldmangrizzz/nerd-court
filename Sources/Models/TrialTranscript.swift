import Foundation

struct TrialTranscript {
    let id: String
    private(set) var turns: [SpeechTurn]

    init(id: String = UUID().uuidString, turns: [SpeechTurn] = []) {
        self.id = id
        self.turns = turns
    }

    // MARK: - Computed Properties

    var startTime: Date? {
        turns.first?.timestamp
    }

    var endTime: Date? {
        turns.last?.timestamp
    }

    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }

    var speakers: [Speaker] {
        var seen = Set<Speaker>()
        return turns.compactMap { turn in
            if seen.insert(turn.speaker).inserted {
                return turn.speaker
            }
            return nil
        }
    }

    var speakerTurnCounts: [Speaker: Int] {
        turns.reduce(into: [:]) { counts, turn in
            counts[turn.speaker, default: 0] += 1
        }
    }

    var isEmpty: Bool {
        turns.isEmpty
    }

    var count: Int {
        turns.count
    }

    // MARK: - Mutating Methods

    mutating func append(_ turn: SpeechTurn) {
        turns.append(turn)
    }

    mutating func append(contentsOf newTurns: [SpeechTurn]) {
        turns.append(contentsOf: newTurns)
    }

    // MARK: - Query Methods

    func turns(for speaker: Speaker) -> [SpeechTurn] {
        turns.filter { $0.speaker == speaker }
    }

    func turns(in range: ClosedRange<Date>) -> [SpeechTurn] {
        turns.filter { range.contains($0.timestamp) }
    }

    // MARK: - Export

    func textTranscript() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return turns.map { turn in
            "[\(formatter.string(from: turn.timestamp))] \(speakerName(turn.speaker)): \(turn.text)"
        }.joined(separator: "\n")
    }

    // MARK: - Helpers

    private func speakerName(_ speaker: Speaker) -> String {
        switch speaker {
        case .jasonTodd: return "Jason Todd"
        case .mattMurdock: return "Matt Murdock"
        case .judgeJerry: return "Judge Jerry"
        case .deadpool: return "Deadpool"
        case .guest(_, let name): return name
        }
    }
}

// MARK: - Codable

extension TrialTranscript: Codable {
    enum CodingKeys: String, CodingKey {
        case id, turns
    }
}

// MARK: - Equatable

extension TrialTranscript: Equatable {
    static func == (lhs: TrialTranscript, rhs: TrialTranscript) -> Bool {
        lhs.id == rhs.id && lhs.turns == rhs.turns
    }
}

// MARK: - Hashable

extension TrialTranscript: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(turns)
    }
}

// MARK: - Identifiable

extension TrialTranscript: Identifiable {}

// MARK: - Convenience

extension TrialTranscript {
    static var empty: TrialTranscript {
        TrialTranscript()
    }
}