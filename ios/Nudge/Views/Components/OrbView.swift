import SwiftUI

/// The companion's form — a small aurora held in glass. Three noise-displaced
/// gradient shells, additive blending, specular kiss, volumetric halo, and a
/// soft pastel light-nest beneath so it never sits on bare ground.
/// Not a face, not a mascot. It breathes.
struct OrbView: View {
    var size: CGFloat
    var state: OrbState
    /// Soft pastel bloom behind the orb — on for hero placements, off for chips.
    var showsHalo: Bool = false

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let energy = state.energy(at: t)
            let palette = Theme.companion(scheme)

            ZStack {
                if showsHalo {
                    RadialGradient(
                        colors: Theme.orbHalo(scheme),
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.95
                    )
                    .frame(width: size * 1.9, height: size * 1.9)
                    .blur(radius: 6)
                    .opacity(0.6 + energy * 0.4)
                }

                ZStack {
                    shell(t: t * 0.55, energy: energy, inner: palette[0], outer: palette[1])
                    shell(t: t * 0.8 + 2.4, energy: energy * 0.9, inner: palette[1], outer: palette[2])
                        .blendMode(.plusLighter)
                    shell(t: t * 0.35 + 5.1, energy: energy * 0.7, inner: palette[2], outer: palette[0])
                        .blendMode(.plusLighter)
                    specular
                }
                .compositingGroup()
                .scaleEffect(breathScale(t: t))
                .overlay {
                    if state.mode == .celebrating {
                        HaloRing(color: palette[1])
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Companion — \(state.accessibilityDescription)")
    }

    private func shell(t: Double, energy: Double, inner: Color, outer: Color) -> some View {
        Rectangle()
            .fill(.white)
            .colorEffect(ShaderLibrary.orbShell(
                .float2(CGSize(width: size * 1.3, height: size * 1.3)),
                .float(Float(t)),
                .float(Float(energy)),
                .color(inner),
                .color(outer)
            ))
            .frame(width: size * 1.3, height: size * 1.3)
    }

    private var specular: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.6), .white.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.13
                )
            )
            .frame(width: size * 0.26, height: size * 0.26)
            .offset(x: -size * 0.11, y: -size * 0.14)
            .blur(radius: 1.5)
    }

    private func breathScale(t: Double) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let breath = sin(t * (2 * .pi) / state.breathPeriod)
        return 1 + 0.03 * CGFloat(breath)
    }
}

/// Expanding light ring for the bloom — fired once, on NudgeSpring.delight.
private struct HaloRing: View {
    let color: Color
    @State private var expanded = false

    var body: some View {
        Circle()
            .strokeBorder(color.opacity(expanded ? 0 : 0.7), lineWidth: expanded ? 1 : 6)
            .scaleEffect(expanded ? 1.9 : 0.9)
            .onAppear {
                withAnimation(NudgeSpring.delight.speed(0.55)) { expanded = true }
            }
            .allowsHitTesting(false)
    }
}
