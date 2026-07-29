import SwiftUI

/// One kept habit, remembered as a light.
struct GardenEntry: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let date: Date
}

/// Progress as a growing organic form — each kept habit adds a softly glowing
/// element to a personal generative scene. Continuity without streak anxiety.
/// Touch a light and it answers: which habit, which day.
struct LightGardenView: View {
    var seed: Int
    var entries: [GardenEntry]
    var height: CGFloat = 170

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIndex: Int? = nil
    @State private var bloomTrigger = 0

    private var visibleCount: Int { min(entries.count, 60) }

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        drawGround(context, size: size)
                        let layout = Self.layout(seed: seed, count: visibleCount)
                        for (index, light) in layout.enumerated() {
                            draw(light: light, index: index, context: context, size: size, t: t,
                                 selected: index == selectedIndex)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleTap(at: location, in: geo.size)
                }
            }
            .frame(height: height)

            if let index = selectedIndex, index < entries.count {
                let entry = entries[entries.count - 1 - min(index, entries.count - 1)]
                GlassSurface(radius: 22) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 7, height: 7)
                            .shadow(color: Theme.gold.opacity(0.8), radius: 5)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.title)
                                .font(NudgeType.rounded(12.5, .semibold))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text("Kept \(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))")
                                .font(NudgeType.rounded(11))
                                .foregroundStyle(Theme.inkMuted)
                        }
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .id(index)
                .allowsHitTesting(false)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: bloomTrigger)
        .animation(NudgeSpring.delight, value: selectedIndex)
        .accessibilityLabel("Your light garden — \(entries.count) kept habits glowing. Tap a light to remember it.")
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        let layout = Self.layout(seed: seed, count: visibleCount)
        // Hit-test against the resting head positions.
        var best: (index: Int, distance: CGFloat)? = nil
        for (index, light) in layout.enumerated() {
            let x = light.baseX * size.width
            let y = (1 - light.stemHeight) * size.height - 8
            let d = hypot(location.x - x, location.y - y)
            if best == nil || d < best!.distance {
                best = (index, d)
            }
        }
        guard let best, best.distance < 46 else {
            withAnimation(NudgeSpring.ui) { selectedIndex = nil }
            return
        }
        bloomTrigger += 1
        SoundEngine.shared.glass()
        withAnimation(NudgeSpring.delight) {
            selectedIndex = selectedIndex == best.index ? nil : best.index
        }
    }

    // MARK: Deterministic layout

    struct Light {
        let baseX: CGFloat
        let stemHeight: CGFloat
        let glowRadius: CGFloat
        let swayRate: Double
        let paletteIndex: Int
    }

    static func layout(seed: Int, count: Int) -> [Light] {
        var rng = SeededRandom(seed: UInt64(seed) &* 0x9E3779B97F4A7C15 &+ 7)
        return (0..<count).map { index in
            Light(
                baseX: 0.08 + CGFloat(rng.unit()) * 0.84,
                stemHeight: 0.22 + CGFloat(rng.unit()) * 0.45,
                glowRadius: 7 + CGFloat(rng.unit()) * 9,
                swayRate: 0.5 + rng.unit() * 0.5,
                paletteIndex: index % 4
            )
        }
    }

    // MARK: Drawing

    private func drawGround(_ context: GraphicsContext, size: CGSize) {
        let groundRect = CGRect(x: -size.width * 0.2, y: size.height * 0.72,
                                width: size.width * 1.4, height: size.height * 0.6)
        context.fill(
            Path(ellipseIn: groundRect),
            with: .radialGradient(
                Gradient(colors: [Theme.gold.opacity(0.2), Theme.gold.opacity(0)]),
                center: CGPoint(x: size.width / 2, y: size.height * 0.95),
                startRadius: 0,
                endRadius: size.width * 0.7
            )
        )
    }

    private func draw(light: Light, index: Int, context: GraphicsContext,
                      size: CGSize, t: Double, selected: Bool) {
        let palette: [Color] = [Theme.gold, Theme.life, Theme.sky, Theme.warm]
        let sway = reduceMotion ? 0 : sin(t * light.swayRate + Double(index)) * 3.5
        let x = light.baseX * size.width + CGFloat(sway)
        let topY = size.height * (1 - light.stemHeight) - 8
        let baseY = size.height * 0.92
        let color = palette[light.paletteIndex]
        let glowRadius = selected ? light.glowRadius * 1.7 : light.glowRadius

        var stem = Path()
        stem.move(to: CGPoint(x: light.baseX * size.width, y: baseY))
        stem.addQuadCurve(
            to: CGPoint(x: x, y: topY),
            control: CGPoint(x: light.baseX * size.width + CGFloat(sway) * 0.4, y: (baseY + topY) / 2)
        )
        context.stroke(stem, with: .color(color.opacity(selected ? 0.45 : 0.22)),
                       style: StrokeStyle(lineWidth: selected ? 1.7 : 1.2, lineCap: .round))

        let headRect = CGRect(x: x - glowRadius, y: topY - glowRadius,
                              width: glowRadius * 2, height: glowRadius * 2)
        context.fill(
            Path(ellipseIn: headRect),
            with: .radialGradient(
                Gradient(colors: [color.opacity(selected ? 0.95 : 0.75), color.opacity(0)]),
                center: CGPoint(x: x, y: topY),
                startRadius: 0,
                endRadius: glowRadius
            )
        )
        let coreRadius = glowRadius * 0.22
        context.fill(
            Path(ellipseIn: CGRect(x: x - coreRadius, y: topY - coreRadius,
                                   width: coreRadius * 2, height: coreRadius * 2)),
            with: .color(.white.opacity(selected ? 1 : 0.85))
        )
        if selected {
            let ringRadius = glowRadius * 1.25
            context.stroke(
                Path(ellipseIn: CGRect(x: x - ringRadius, y: topY - ringRadius,
                                       width: ringRadius * 2, height: ringRadius * 2)),
                with: .color(color.opacity(0.6)),
                style: StrokeStyle(lineWidth: 1.1)
            )
        }
    }
}
