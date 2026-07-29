import SwiftUI

/// An abstract, beautiful figure of light — not an anatomy chart. Tap where
/// it lives; the region answers with a glow. Used for pain-type symptoms.
struct BodyMapView: View {
    @Binding var selection: BodyRegion?

    @Environment(\.colorScheme) private var scheme

    /// Region hotspots in unit coordinates (x, y, radius) on the figure canvas.
    private let hotspots: [(region: BodyRegion, x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (.head, 0.5, 0.09, 0.09),
        (.chest, 0.5, 0.27, 0.11),
        (.abdomen, 0.5, 0.43, 0.11),
        (.leftArm, 0.27, 0.34, 0.09),
        (.rightArm, 0.73, 0.34, 0.09),
        (.lowerBack, 0.5, 0.54, 0.09),
        (.leftLeg, 0.41, 0.74, 0.1),
        (.rightLeg, 0.59, 0.74, 0.1),
        (.feet, 0.5, 0.94, 0.08),
    ]

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    figure(size: size)

                    ForEach(hotspots, id: \.region) { spot in
                        let selected = selection == spot.region
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: selected
                                        ? [Theme.warm.opacity(0.75), Theme.warm.opacity(0)]
                                        : [Theme.sky.opacity(0.0), Theme.sky.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: spot.r * size.width * 1.6
                                )
                            )
                            .frame(width: spot.r * size.width * 3.2, height: spot.r * size.width * 3.2)
                            .position(x: spot.x * size.width, y: spot.y * size.height)
                            .animation(NudgeSpring.delight, value: selection)
                            .allowsHitTesting(false)

                        if selected {
                            Circle()
                                .strokeBorder(Theme.warm.opacity(0.8), lineWidth: 1.4)
                                .frame(width: spot.r * size.width * 2.3, height: spot.r * size.width * 2.3)
                                .position(x: spot.x * size.width, y: spot.y * size.height)
                                .transition(.scale.combined(with: .opacity))
                                .allowsHitTesting(false)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let unit = CGPoint(x: location.x / size.width, y: location.y / size.height)
                    let nearest = hotspots.min { lhs, rhs in
                        distance(unit, CGPoint(x: lhs.x, y: lhs.y)) < distance(unit, CGPoint(x: rhs.x, y: rhs.y))
                    }
                    if let nearest {
                        Haptics.glass()
                        SoundEngine.shared.glass()
                        withAnimation(NudgeSpring.delight) {
                            selection = nearest.region
                        }
                    }
                }
            }
            .aspectRatio(0.46, contentMode: .fit)
            .frame(maxHeight: 320)

            Text(selection.map { "Right there — \($0.rawValue.lowercased())" } ?? "Tap where it lives")
                .font(NudgeType.rounded(13, .medium))
                .foregroundStyle(selection == nil ? Theme.inkMuted : Theme.warm)
                .animation(NudgeSpring.ui, value: selection)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Body map")
        .accessibilityValue(selection?.rawValue ?? "Nothing selected")
    }

    /// The figure — soft luminous strokes, gradient-lit like the rest of the world.
    private func figure(size: CGSize) -> some View {
        Canvas { context, _ in
            let w = size.width
            let h = size.height
            let stroke = Color.white.opacity(scheme == .dark ? 0.0 : 0.0)
            _ = stroke

            var body = Path()
            // Head
            body.addEllipse(in: CGRect(x: w * 0.41, y: h * 0.035, width: w * 0.18, height: h * 0.105))
            // Torso — a soft rounded form
            body.move(to: CGPoint(x: w * 0.36, y: h * 0.17))
            body.addCurve(to: CGPoint(x: w * 0.64, y: h * 0.17),
                          control1: CGPoint(x: w * 0.44, y: h * 0.145),
                          control2: CGPoint(x: w * 0.56, y: h * 0.145))
            body.addCurve(to: CGPoint(x: w * 0.60, y: h * 0.60),
                          control1: CGPoint(x: w * 0.70, y: h * 0.32),
                          control2: CGPoint(x: w * 0.66, y: h * 0.48))
            body.addCurve(to: CGPoint(x: w * 0.40, y: h * 0.60),
                          control1: CGPoint(x: w * 0.56, y: h * 0.66),
                          control2: CGPoint(x: w * 0.44, y: h * 0.66))
            body.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.17),
                          control1: CGPoint(x: w * 0.34, y: h * 0.48),
                          control2: CGPoint(x: w * 0.30, y: h * 0.32))
            // Arms
            body.move(to: CGPoint(x: w * 0.36, y: h * 0.20))
            body.addCurve(to: CGPoint(x: w * 0.20, y: h * 0.50),
                          control1: CGPoint(x: w * 0.26, y: h * 0.26),
                          control2: CGPoint(x: w * 0.20, y: h * 0.38))
            body.move(to: CGPoint(x: w * 0.64, y: h * 0.20))
            body.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.50),
                          control1: CGPoint(x: w * 0.74, y: h * 0.26),
                          control2: CGPoint(x: w * 0.80, y: h * 0.38))
            // Legs
            body.move(to: CGPoint(x: w * 0.44, y: h * 0.62))
            body.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.95),
                          control1: CGPoint(x: w * 0.43, y: h * 0.74),
                          control2: CGPoint(x: w * 0.42, y: h * 0.86))
            body.move(to: CGPoint(x: w * 0.56, y: h * 0.62))
            body.addCurve(to: CGPoint(x: w * 0.58, y: h * 0.95),
                          control1: CGPoint(x: w * 0.57, y: h * 0.74),
                          control2: CGPoint(x: w * 0.58, y: h * 0.86))

            context.stroke(
                body,
                with: .linearGradient(
                    Gradient(colors: [Theme.sky.opacity(0.85), Theme.rose.opacity(0.6), Theme.gold.opacity(0.7)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: h)
                ),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            )

            // Inner glow wash
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.3, y: h * 0.18, width: w * 0.4, height: h * 0.42)),
                with: .radialGradient(
                    Gradient(colors: [Theme.sky.opacity(0.14), Theme.sky.opacity(0)]),
                    center: CGPoint(x: w * 0.5, y: h * 0.36),
                    startRadius: 0,
                    endRadius: w * 0.32
                )
            )
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
