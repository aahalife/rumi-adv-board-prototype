import SwiftUI

/// A small generative light scene — seeded soft glow forms over clear ground.
/// Used for insight visuals, Currents grounds, and empty states. Never a sad
/// clipboard.
struct SceneVisual: View {
    var seed: Int
    var height: CGFloat = 150

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            var rng = SeededRandom(seed: UInt64(seed) &* 0x9E3779B97F4A7C15 &+ 1)
            let palette: [Color] = [Theme.warm, Theme.life, Theme.sky, Theme.gold]
            let count = 5 + Int(rng.next() % 3)
            for index in 0..<count {
                let x = CGFloat(rng.unit()) * size.width
                let y = CGFloat(rng.unit()) * size.height
                let radius = 24 + CGFloat(rng.unit()) * (size.height * 0.6)
                let color = palette[index % palette.count]
                let opacity = 0.22 + rng.unit() * 0.3
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [color.opacity(opacity), color.opacity(0)]),
                        center: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: radius
                    )
                )
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Deterministic generator so scenes are stable per seed.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x4D595DF4D0F33173 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func unit() -> Double {
        Double(next() % 10_000) / 10_000.0
    }
}
