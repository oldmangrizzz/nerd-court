import SwiftUI

// MARK: - Comic Beat Overlay

/// Renders comic-book-style cinematic effects: speed lines, Ben-Day dots, and glitch artifacts.
/// Driven by a `CinematicFrame` configuration.
struct ComicBeatOverlay: View {
    let cinematicFrame: CinematicFrame

    var body: some View {
        ZStack {
            if cinematicFrame.speedLines {
                SpeedLinesOverlay(
                    intensity: cinematicFrame.intensity,
                    colorPalette: cinematicFrame.colorPalette
                )
            }
            if cinematicFrame.benDayDots {
                BenDayDotsOverlay(
                    intensity: cinematicFrame.intensity,
                    colorPalette: cinematicFrame.colorPalette
                )
            }
            if cinematicFrame.glitch {
                GlitchOverlay(intensity: cinematicFrame.intensity)
            }
        }
        .allowsHitTesting(false)
        .drawingGroup() // Renders efficiently into a single flat layer
    }
}

// MARK: - Speed Lines

private struct SpeedLinesOverlay: View {
    let intensity: Double
    let colorPalette: [String]

    @State private var lineSpecs: [LineSpec] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let lineColor = colorFromPalette(at: 0, default: .white)

                for spec in lineSpecs {
                    let totalWidth = size.width + spec.length
                    let rawX = (spec.initialX + time * spec.speed)
                        .truncatingRemainder(dividingBy: totalWidth)
                    let x = rawX - spec.length / 2

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: spec.y))
                    path.addLine(to: CGPoint(x: x + spec.length, y: spec.y))

                    context.stroke(
                        path,
                        with: .color(lineColor.opacity(spec.opacity)),
                        lineWidth: spec.thickness
                    )
                }
            }
            .onAppear {
                lineSpecs = generateLineSpecs()
            }
            .onChange(of: intensity) { _, _ in
                lineSpecs = generateLineSpecs()
            }
        }
    }

    private func generateLineSpecs() -> [LineSpec] {
        let count = max(4, Int(20 * intensity))
        var specs: [LineSpec] = []
        for _ in 0..<count {
            specs.append(LineSpec(
                y: CGFloat.random(in: 0...1),
                length: CGFloat.random(in: 40...120) * CGFloat(intensity),
                speed: CGFloat.random(in: 80...200) * CGFloat(intensity),
                thickness: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...0.9) * intensity,
                initialX: CGFloat.random(in: 0...300)
            ))
        }
        return specs
    }

    private struct LineSpec {
        let y: CGFloat       // normalized 0-1
        let length: CGFloat
        let speed: CGFloat   // points per second
        let thickness: CGFloat
        let opacity: Double
        let initialX: CGFloat
    }
}

// MARK: - Ben-Day Dots

private struct BenDayDotsOverlay: View {
    let intensity: Double
    let colorPalette: [String]

    var body: some View {
        Canvas { context, size in
            let dotColor = colorFromPalette(at: 1, default: .yellow)
            let baseRadius: CGFloat = 3
            let radius = baseRadius * CGFloat(intensity)
            let spacing: CGFloat = 12

            let columns = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1

            for row in 0..<rows {
                for col in 0..<columns {
                    let x = CGFloat(col) * spacing + spacing / 2
                    let y = CGFloat(row) * spacing + spacing / 2
                    let rect = CGRect(x: x - radius, y: y - radius,
                                      width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
        }
        .blendMode(.overlay) // Blend dots with underlying content
    }
}

// MARK: - Glitch Artifacts

private struct GlitchOverlay: View {
    let intensity: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let seed = Int(time * 10) // changes every 0.1s
                var rng = SeededRandomNumberGenerator(seed: seed)

                let sliceCount = max(1, Int(6 * intensity))
                for _ in 0..<sliceCount {
                    let y = CGFloat.random(in: 0...size.height, using: &rng)
                    let height = CGFloat.random(in: 2...8, using: &rng) * CGFloat(intensity)
                    let offsetX = CGFloat.random(in: -15...15, using: &rng) * CGFloat(intensity)
                    let color = glitchColor(using: &rng)

                    let rect = CGRect(x: offsetX, y: y, width: size.width, height: height)
                    context.fill(Path(rect), with: .color(color.opacity(0.4 * intensity)))
                }
            }
        }
        .blendMode(.screen)
    }

    private func glitchColor(using rng: inout SeededRandomNumberGenerator) -> Color {
        let roll = Int.random(in: 0...2, using: &rng)
        switch roll {
        case 0: return .red
        case 1: return .green
        case 2: return .blue
        default: return .white
        }
    }
}

// MARK: - Helpers

/// Simple deterministic random number generator for glitch effects.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// Converts a hex string from the palette to a Color, falling back to a default.
private func colorFromPalette(at index: Int, default defaultColor: Color) -> Color {
    // In a full implementation, this would parse the hex string.
    // For now we return the default; palette handling can be extended later.
    return defaultColor
}