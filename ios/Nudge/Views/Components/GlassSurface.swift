import SwiftUI

/// Liquid-glass chrome. On iOS 26 this is true Liquid Glass; earlier systems
/// get the layered-material equivalent. Reserved for the dock, floating chips,
/// input bars and sheet headers — glass is seasoning, not the meal.
struct GlassSurface<Content: View>: View {
    var radius: CGFloat = 36
    var interactive: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    interactive ? .regular.interactive() : .regular,
                    in: .rect(cornerRadius: radius, style: .continuous)
                )
        } else {
            content
                .background(.ultraThinMaterial, in: .rect(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(
                            .linearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Theme.shadow.opacity(0.14), radius: 24, y: 8)
        }
    }
}

/// Soft organic surface — the standard non-glass card ground. Clearly raised
/// above the living gradient: porcelain-bright by day, lifted indigo at night,
/// with a hairline edge and a warm tinted shadow.
struct OrganicSurface<Content: View>: View {
    var radius: CGFloat = 36
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(Theme.surface.opacity(0.96), in: .rect(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        .linearGradient(
                            colors: [Color.white.opacity(0.85), Theme.edge.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Theme.shadow.opacity(0.16), radius: 20, y: 7)
    }
}

/// Press feedback — every tappable thing acknowledges with a spring.
struct NudgeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(NudgeSpring.ui, value: configuration.isPressed)
    }
}

// MARK: - Unified floating chrome

/// One vocabulary for every floating icon button so day and night chrome
/// reads identically across screens. True interactive glass on iOS 26.
struct ChromeIcon: View {
    var systemName: String
    var size: CGFloat = 38
    var tint: Color = Theme.ink
    var accessibilityText: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tick()
            SoundEngine.shared.tick()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .regular))
                .foregroundStyle(tint.opacity(0.85))
                .frame(width: size, height: size)
                .modifier(CircularGlass())
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel(accessibilityText)
    }
}

/// Circular glass that is identical everywhere it appears.
struct CircularGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: .circle)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.8))
                .shadow(color: Theme.shadow.opacity(0.12), radius: 10, y: 4)
        }
    }
}

/// Capsule glass for chips — one source of truth.
struct CapsuleGlass: ViewModifier {
    var tint: Color? = nil

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint.opacity(0.25)).interactive(), in: .capsule)
            } else {
                content.glassEffect(.regular.interactive(), in: .capsule)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: .capsule)
                .overlay(Capsule().strokeBorder((tint ?? .white).opacity(0.3), lineWidth: 0.8))
        }
    }
}

extension View {
    func capsuleGlass(tint: Color? = nil) -> some View {
        modifier(CapsuleGlass(tint: tint))
    }
}

// MARK: - Light sweep (the Genie shimmer)

/// A traveling band of iridescent light with a faint liquid lens — fired on
/// demand (tap, appearance) or ambiently every so often. Cheap, Metal-backed.
struct LightSweep: ViewModifier {
    var trigger: Int
    var strength: Double = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: -0.2, trigger: trigger) { view, progress in
                view
                    .visualEffect { effect, proxy in
                        effect
                            .colorEffect(ShaderLibrary.lightSweep(
                                .float2(proxy.size),
                                .float(Float(progress)),
                                .float(Float(progress > 0 && progress < 1 ? strength : 0))
                            ))
                            .distortionEffect(ShaderLibrary.sweepLens(
                                .float2(proxy.size),
                                .float(Float(progress)),
                                .float(Float(progress > 0 && progress < 1 ? 2.4 : 0))
                            ), maxSampleOffset: CGSize(width: 4, height: 4))
                    }
            } keyframes: { _ in
                MoveKeyframe(0.0)
                LinearKeyframe(1.0, duration: 1.35)
            }
        }
    }
}

/// Periodically lets a light pass over the surface — glass catching the sun.
struct AmbientLightSweep: ViewModifier {
    var period: Double = 9
    var strength: Double = 0.4
    @State private var counter = 0

    func body(content: Content) -> some View {
        content
            .modifier(LightSweep(trigger: counter, strength: strength))
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(period + Double.random(in: -2...3)))
                    counter += 1
                }
            }
    }
}

extension View {
    /// Fire a light sweep when `trigger` changes.
    func lightSweep(trigger: Int, strength: Double = 0.5) -> some View {
        modifier(LightSweep(trigger: trigger, strength: strength))
    }

    /// A light passes over this surface every ~`period` seconds.
    func ambientSweep(period: Double = 9, strength: Double = 0.4) -> some View {
        modifier(AmbientLightSweep(period: period, strength: strength))
    }
}
