import SwiftUI

/// A Siri-like voice aura that rises from the bottom of the screen and breathes
/// with speech energy. Tuned to read clearly against the calm Rumi background:
/// a luminous soft-white core with a gentle multicolor fringe, and small, slow,
/// graceful particles that drift up like embers of light — never a fast, busy
/// confetti.
struct VoiceGradientGlow: View {
    /// Audio energy, 0…1 — mic loudness while listening, playback loudness
    /// while the companion speaks.
    var level: Double
    /// True while listening or speaking; when false the glow settles.
    var active: Bool

    private let particleCount = 34

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breath = (sin(t * 0.8) + 1) / 2 * 0.12
            let energy = active ? min(max(level, 0), 1) : 0
            // A higher floor keeps the aura visible at rest; energy lifts it.
            let glow = 0.46 + breath + energy * 0.54

            ZStack {
                gradient(glow: glow, time: t)
                Canvas { context, size in
                    draw(context: context, size: size, time: t, energy: energy)
                }
                .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }

    private var palette: [Color] {
        [Color.white, Theme.sky, Theme.rose, Theme.gold, Theme.life]
    }

    /// A bright soft-white core anchored low with a gentle color fringe, so it
    /// reads like light rising into the conversation rather than a flat bar.
    private func gradient(glow: Double, time: Double) -> some View {
        let reach = 0.40 + glow * 0.34
        let sweep = UnitPoint(x: 0.5 + 0.16 * sin(time * 0.5), y: 1)
        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: Theme.sky.opacity(glow * 0.16), location: max(0, 1 - reach)),
                .init(color: Theme.rose.opacity(glow * 0.22), location: max(0, 1 - reach * 0.70)),
                .init(color: Theme.gold.opacity(glow * 0.28), location: max(0, 1 - reach * 0.44)),
                .init(color: Color.white.opacity(glow * 0.74), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            ZStack {
                RadialGradient(
                    colors: [Color.white.opacity(glow * 0.92), Color.white.opacity(glow * 0.30), .clear],
                    center: sweep,
                    startRadius: 0,
                    endRadius: 300 * (0.78 + glow * 0.5)
                )
                RadialGradient(
                    colors: [Theme.sky.opacity(glow * 0.50), Theme.rose.opacity(glow * 0.24), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 340
                )
                RadialGradient(
                    colors: [Theme.rose.opacity(glow * 0.42), Theme.gold.opacity(glow * 0.22), .clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 340
                )
            }
            .frame(height: 380)
            .blur(radius: 30)
        }
    }

    private func draw(context: GraphicsContext, size: CGSize, time: Double, energy: Double) {
        let colors = palette
        for i in 0..<particleCount {
            let fi = Double(i)
            let seedX = fract(sin(fi * 12.9898) * 43758.5453)
            // Much slower rise — embers of light, not darting sparks.
            let seedSpeed = 0.016 + fract(sin(fi * 78.233) * 12345.678) * 0.03
            let seedPhase = fract(sin(fi * 3.123) * 9871.23)
            let speed = seedSpeed * (1 + energy * 0.45)
            let progress = fract(time * speed + seedPhase)

            let drift = sin(time * 0.4 + fi) * (6 + energy * 10)
            let x = seedX * size.width + drift
            let y = size.height * (1 - progress)
            let edgeFade = sin(progress * .pi)
            let opacity = edgeFade * (0.14 + energy * 0.42)
            guard opacity > 0.015 else { continue }

            // Smaller, softer dots so the field feels calm and graceful.
            let radius = (1.0 + energy * 1.8) * (0.55 + edgeFade)
            let color = colors[i % colors.count]
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            context.fill(Circle().path(in: rect), with: .color(color.opacity(opacity)))
        }
    }

    private func fract(_ value: Double) -> Double { value - floor(value) }
}
