import SwiftUI

/// Progressive (variable) blur — content melts into mist toward one edge.
/// Built from stacked, gradient-masked material layers so it ships on every
/// OS without private API. Place in an overlay aligned to the fading edge.
struct ProgressiveBlur: View {
    enum Edge { case top, bottom }

    var edge: Edge
    var height: CGFloat = 110
    /// Tint that deepens the fade into the app ground.
    var tint: Color? = nil

    var body: some View {
        ZStack {
            // Three blur strata, each masked tighter toward the edge —
            // the visual read is a smooth blur ramp.
            stratum(radius: 2.5, from: 0.0, to: 0.65)
            stratum(radius: 7, from: 0.25, to: 0.95)
            stratum(radius: 14, from: 0.55, to: 1.0)

            if let tint {
                LinearGradient(
                    colors: edge == .top
                        ? [tint.opacity(0.55), tint.opacity(0)]
                        : [tint.opacity(0), tint.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func stratum(radius: CGFloat, from: CGFloat, to: CGFloat) -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .blur(radius: radius)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: edge == .top ? 1 - to : from),
                        .init(color: .white, location: edge == .top ? 1 - from : to),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
    }
}

extension View {
    /// A soft progressive-blur veil under the top chrome, so content melts
    /// away as it scrolls beneath the status bar.
    func topMist(height: CGFloat = 96) -> some View {
        overlay(alignment: .top) {
            ProgressiveBlur(edge: .top, height: height, tint: Theme.base)
                .ignoresSafeArea(edges: .top)
        }
    }
}
