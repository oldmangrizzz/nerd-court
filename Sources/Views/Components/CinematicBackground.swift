import SwiftUI

// MARK: - CinematicBackground

/// A Spider-Verse style parallax background with comic-book effects.
/// Supports Ben-Day dots, speed lines, glitch distortion, and multi-layer parallax.
struct CinematicBackground: View {
    let colorPalette: [Color]
    let intensity: Double
    let benDayDots: Bool
    let speedLines: Bool
    let glitch: Bool
    let parallaxOffset: CGSize

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colorPalette.isEmpty ? [.black, .purple] : colorPalette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geometry in
                let size = geometry.size

                // Distant layer – moves slowest
                if benDayDots {
                    BenDayDotsView(
                        dotSize: 4,
                        spacing: 8,
                        color: colorPalette.first ?? .white
                    )
                    .offset(
                        x: parallaxOffset.width * 0.2,
                        y: parallaxOffset.height * 0.2
                    )
                    .frame(width: size.width, height: size.height)
                }

                // Midground layer – moves at medium speed
                if speedLines {
                    SpeedLinesView(
                        lineCount: 20,
                        color: colorPalette.last ?? .white,
                        intensity: intensity
                    )
                    .offset(
                        x: parallaxOffset.width * 0.5,
                        y: parallaxOffset.height * 0.5
                    )
                    .frame(width: size.width, height: size.height)
                }

                // Foreground layer – moves fastest
                if glitch {
                    GlitchEffectView(intensity: intensity)
                        .offset(
                            x: parallaxOffset.width * 0.8,
                            y: parallaxOffset.height * 0.8
                        )
                        .frame(width: size.width, height: size.height)
                }
            }
        }
        .ignoresSafeArea()
        .drawingGroup() // Renders everything into a single flattened bitmap for performance
    }
}

// MARK: - Ben-Day Dots

/// Renders a repeating pattern of circles (Ben-Day dots) using Canvas.
struct BenDayDotsView: View {
    let dotSize: CGFloat
    let spacing: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, size in
            let step = spacing
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Circle().path(in: rect), with: .color(color))
                    y += step
                }
                x += step
            }
        }
    }
}

// MARK: - Speed Lines

/// Animated speed lines that convey motion and intensity.
struct SpeedLinesView: View {
    let lineCount: Int
    let color: Color
    let intensity: Double

    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let seed = now.truncatingRemainder(dividingBy: 1000)
                var rng = SeededRandomNumberGenerator(seed: UInt64(seed * 1000))

                for _ in 0..<lineCount {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let length = CGFloat.random(in: 20...80, using: &rng) * CGFloat(intensity)
                    let opacity = Double.random(in: 0.2...0.8, using: &rng)
                    let angle = Angle.degrees(Double.random(in: -30...30, using: &rng))

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + length * cos(angle.radians),
                                             y: length * sin(angle.radians)))

                    context.stroke(
                        path,
                        with: .color(color.opacity(opacity)),
                        lineWidth: 1.5
                    )
                }
            }
        }
    }
}

// MARK: - Glitch Effect

/// Simulates a digital glitch by offsetting color channels and adding random displacement.
struct GlitchEffectView: View {
    let intensity: Double

    @State private var glitchOffset: CGSize = .zero
    @State private var glitchActive: Bool = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let seed = now.truncatingRemainder(dividingBy: 1000)
            var rng = SeededRandomNumberGenerator(seed: UInt64(seed * 1000))

            // Randomly trigger glitch frames
            let shouldGlitch = Double.random(in: 0...1, using: &rng) < intensity * 0.3

            ZStack {
                // Base layer (green channel)
                Color.clear
                    .overlay(
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .offset(shouldGlitch ? randomGlitchOffset(using: &rng) : .zero)
                    )

                // Red channel offset
                Color.clear
                    .overlay(
                        Rectangle()
                            .fill(Color.red.opacity(0.3))
                            .offset(shouldGlitch ? randomGlitchOffset(using: &rng) : .zero)
                    )

                // Blue channel offset
                Color.clear
                    .overlay(
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .offset(shouldGlitch ? randomGlitchOffset(using: &rng) : .zero)
                    )

                // Random horizontal slices
                if shouldGlitch {
                    ForEach(0..<Int(intensity * 5), id: \.self) { _ in
                        let y = CGFloat.random(in: 0...1, using: &rng)
                        let height = CGFloat.random(in: 0.01...0.05, using: &rng)
                        let xOffset = CGFloat.random(in: -20...20, using: &rng) * intensity

                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: height * UIScreen.main.bounds.height)
                            .offset(x: xOffset, y: (y - 0.5) * UIScreen.main.bounds.height)
                    }
                }
            }
            .animation(.linear(duration: 0.05), value: shouldGlitch)
        }
    }

    private func randomGlitchOffset(using rng: inout SeededRandomNumberGenerator) -> CGSize {
        CGSize(
            width: CGFloat.random(in: -10...10, using: &rng) * intensity,
            height: CGFloat.random(in: -5...5, using: &rng) * intensity
        )
    }
}

// MARK: - Helpers

/// A simple deterministic random number generator for use in Canvas/TimelineView.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Preview

#if DEBUG
struct CinematicBackground_Previews: PreviewProvider {
    static var previews: some View {
        CinematicBackground(
            colorPalette: [.black, .purple, .pink],
            intensity: 0.8,
            benDayDots: true,
            speedLines: true,
            glitch: true,
            parallaxOffset: CGSize(width: 20, height: -10)
        )
        .previewLayout(.fixed(width: 400, height: 300))
    }
}
#endif