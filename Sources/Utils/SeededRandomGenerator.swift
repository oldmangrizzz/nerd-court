import Foundation

/// A simple deterministic random number generator for reproducible glitch/animation effects.
/// Uses a linear congruential generator (LCG) algorithm for determinism.
struct GlitchRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
