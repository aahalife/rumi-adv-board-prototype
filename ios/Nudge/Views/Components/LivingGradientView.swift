import SwiftUI

/// The app-wide ground. Never flat — an ultra-slow Metal mesh of three
/// orbiting radial centers, tuned per time of day.
struct LivingGradientView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: scenePhase != .active || reduceMotion)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate * 0.011
                let hour = Calendar.current.component(.hour, from: timeline.date)
                let palette = Theme.gradientPalette(scheme: scheme, hour: hour)
                Rectangle()
                    .fill(Theme.base)
                    .colorEffect(ShaderLibrary.livingGradient(
                        .float2(geo.size),
                        .float(Float(t)),
                        .color(palette.0),
                        .color(palette.1),
                        .color(palette.2)
                    ))
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
