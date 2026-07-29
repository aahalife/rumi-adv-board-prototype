import SwiftUI

/// Adherence without judgment — a soft tide whose fullness reflects the last
/// 30 days. No percentages on the surface, no red flags, ever.
struct TideView: View {
    /// 0…1 — how full the tide runs.
    var level: Double
    var height: CGFloat = 110

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawWave(context, size: size, t: t, speed: 0.6, amplitude: 7, phase: 0,
                         color: Theme.life, alpha: 0.45)
                drawWave(context, size: size, t: t, speed: 0.42, amplitude: 10, phase: 1.8,
                         color: Theme.sky, alpha: 0.32)
                drawWave(context, size: size, t: t, speed: 0.8, amplitude: 4, phase: 3.6,
                         color: Theme.gold, alpha: 0.25)
            }
        }
        .frame(height: height)
        .background(Theme.surface.opacity(0.6))
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .accessibilityLabel("Medication tide — running \(level > 0.85 ? "full" : level > 0.6 ? "steady" : "lighter") over the last 30 days")
    }

    private func drawWave(_ context: GraphicsContext, size: CGSize, t: Double,
                          speed: Double, amplitude: Double, phase: Double,
                          color: Color, alpha: Double) {
        let surfaceY = size.height * (1 - 0.18 - level * 0.66)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width {
            let y = surfaceY + CGFloat(sin(Double(x) * 0.022 + t * speed + phase) * amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
            x += 4
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [color.opacity(alpha), color.opacity(alpha * 0.15)]),
                startPoint: CGPoint(x: 0, y: surfaceY),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }
}
