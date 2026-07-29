import SwiftUI

/// Janum-Trivedi-style touch ripple — a fluid wave distortion that propagates
/// through the surface from the touch point, riding the Metal `ripple` shader,
/// paired with `touchGlow` so light visibly bends with the water (the Genie
/// moment). Driven by the finger — never a loop.
struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsed: TimeInterval
    var amplitude: Double = 11
    var frequency: Double = 13
    var decay: Double = 7
    var glow: Double = 0.55

    func body(content: Content) -> some View {
        let active = elapsed > 0 && elapsed < 1.2
        content.visualEffect { view, _ in
            view
                .distortionEffect(
                    ShaderLibrary.ripple(
                        .float2(origin),
                        .float(Float(elapsed)),
                        .float(Float(amplitude)),
                        .float(Float(frequency)),
                        .float(Float(decay))
                    ),
                    maxSampleOffset: CGSize(width: 24, height: 24),
                    isEnabled: active
                )
                .colorEffect(
                    ShaderLibrary.touchGlow(
                        .float2(origin),
                        .float(Float(elapsed)),
                        .float(Float(glow))
                    ),
                    isEnabled: active && glow > 0
                )
        }
    }
}

/// Counter-triggered ripple: every bump of `trigger` replays the wave from
/// `origin`. Drive `origin` from a SpatialTapGesture.
struct RippleEffect: ViewModifier {
    var origin: CGPoint
    var trigger: Int
    var glow: Double = 0.55

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(
                initialValue: 0.0,
                trigger: trigger
            ) { view, elapsed in
                view.modifier(RippleModifier(origin: origin, elapsed: elapsed, glow: glow))
            } keyframes: { _ in
                MoveKeyframe(0)
                LinearKeyframe(1.2, duration: 1.2)
            }
        }
    }
}

/// Attach to any surface: taps send a fluid wave of water-and-light through
/// it. The tap still reaches buttons beneath. Never attach to Liquid Glass —
/// layer effects over glass render placeholders on iOS 26.
struct RippleOnTap: ViewModifier {
    var glow: Double = 0.55

    @State private var origin: CGPoint = .zero
    @State private var counter = 0

    func body(content: Content) -> some View {
        content
            .modifier(RippleEffect(origin: origin, trigger: counter, glow: glow))
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        origin = value.location
                        counter += 1
                    }
            )
    }
}

extension View {
    /// Light-bending touch ripple on every tap — water in the glass.
    func rippleOnTap(glow: Double = 0.55) -> some View {
        modifier(RippleOnTap(glow: glow))
    }

    /// Externally triggered ripple (e.g. on send, on log).
    func ripple(origin: CGPoint, trigger: Int, glow: Double = 0.55) -> some View {
        modifier(RippleEffect(origin: origin, trigger: trigger, glow: glow))
    }
}
