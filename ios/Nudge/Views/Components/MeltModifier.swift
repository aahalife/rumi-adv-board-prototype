import SwiftUI

/// Fluid melt dissolve for dismissed moments — alpha erosion via Metal,
/// animatable so it rides NudgeSpring like everything else.
struct MeltModifier: ViewModifier, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .visualEffect { view, proxy in
                view.colorEffect(ShaderLibrary.melt(
                    .float(Float(progress)),
                    .float2(proxy.size)
                ))
            }
    }
}

extension View {
    func melt(_ progress: Double) -> some View {
        modifier(MeltModifier(progress: progress))
    }
}
