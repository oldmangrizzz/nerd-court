import Foundation

/// Persistent submission rate-limiter for grievance filing.
///
/// Threat model:
///   - User mashes "FILE GRIEVANCE" repeatedly, each press spawning a 10–20
///     minute trial that drives Ollama Cloud + F5-TTS calls. The operator
///     pays for both. A trivial accidental DoS would burn the budget.
///   - A scripted attacker programmatically files thousands of grievances.
///
/// Policy (production defaults):
///   - Cooldown: at least 30 seconds between consecutive submissions.
///   - Daily cap: at most 20 submissions per rolling 24 h window.
///
/// Storage: `UserDefaults` so limits survive app relaunches. No PII.
final class SubmissionRateLimiter: @unchecked Sendable {
    enum Decision: Equatable {
        case allowed
        case cooldown(retryAfter: TimeInterval)
        case dailyCapReached(retryAfter: TimeInterval)

        var allowed: Bool {
            if case .allowed = self { return true }
            return false
        }

        var humanReason: String? {
            switch self {
            case .allowed: return nil
            case .cooldown(let s):
                let secs = max(1, Int(s.rounded(.up)))
                return "Slow down — try again in \(secs)s."
            case .dailyCapReached(let s):
                let mins = max(1, Int((s / 60).rounded(.up)))
                return "Daily trial cap reached. Try again in ~\(mins) min."
            }
        }
    }

    struct Policy {
        let cooldown: TimeInterval
        let dailyCap: Int
        let dailyWindow: TimeInterval

        static let production = Policy(cooldown: 30, dailyCap: 20, dailyWindow: 24 * 3600)
    }

    private let policy: Policy
    private let defaults: UserDefaults
    private let now: () -> Date
    private let lock = NSLock()

    private static let lastSubmittedKey = "nc.rateLimiter.lastSubmittedAt"
    private static let dailyTimestampsKey = "nc.rateLimiter.dailyTimestamps"

    init(policy: Policy = .production,
         defaults: UserDefaults = .standard,
         now: @escaping () -> Date = Date.init) {
        self.policy = policy
        self.defaults = defaults
        self.now = now
    }

    /// Non-mutating evaluation. Useful for UI ("disable button until X").
    func evaluate() -> Decision {
        lock.lock(); defer { lock.unlock() }
        return decideLocked(at: now())
    }

    /// Atomically check + record. Returns the decision; if `.allowed`, the
    /// submission is recorded and subsequent calls observe the new state.
    func consume() -> Decision {
        lock.lock(); defer { lock.unlock() }
        let stamp = now()
        let decision = decideLocked(at: stamp)
        guard case .allowed = decision else { return decision }
        defaults.set(stamp.timeIntervalSince1970, forKey: Self.lastSubmittedKey)
        var window = pruneDailyWindow(at: stamp)
        window.append(stamp.timeIntervalSince1970)
        defaults.set(window, forKey: Self.dailyTimestampsKey)
        return .allowed
    }

    // MARK: - Private

    private func decideLocked(at moment: Date) -> Decision {
        let last = defaults.double(forKey: Self.lastSubmittedKey)
        if last > 0 {
            let elapsed = moment.timeIntervalSince1970 - last
            if elapsed < policy.cooldown {
                return .cooldown(retryAfter: policy.cooldown - elapsed)
            }
        }
        let window = pruneDailyWindow(at: moment)
        if window.count >= policy.dailyCap, let oldest = window.first {
            let waitUntil = oldest + policy.dailyWindow
            return .dailyCapReached(retryAfter: max(0, waitUntil - moment.timeIntervalSince1970))
        }
        return .allowed
    }

    private func pruneDailyWindow(at moment: Date) -> [Double] {
        let raw = defaults.array(forKey: Self.dailyTimestampsKey) as? [Double] ?? []
        let cutoff = moment.timeIntervalSince1970 - policy.dailyWindow
        let pruned = raw.filter { $0 >= cutoff }
        if pruned.count != raw.count {
            defaults.set(pruned, forKey: Self.dailyTimestampsKey)
        }
        return pruned
    }
}
