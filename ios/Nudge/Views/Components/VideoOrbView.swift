import SwiftUI
import AVFoundation

/// The companion's living form — real footage of a hand-crafted glass orb
/// (Gleb-style), state-driven, cross-faded between moods, masked into a
/// feathered circle so it melts into any background.
///
/// Day ambient: a pearl. Night ambient: deep indigo. Speaking/listening:
/// the vivid Siri-glass. Thinking: a transparent bubble. Celebrating: the
/// checkmark bloom. Small placements (<60pt) fall back to the Metal orb.
struct VideoOrbView: View {
    var size: CGFloat
    var state: OrbState
    var showsHalo: Bool = false

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if size < 60 {
            OrbView(size: size, state: state, showsHalo: showsHalo)
        } else {
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
                }

                OrbVideoSurface(resource: resourceName, breathPeriod: state.breathPeriod)
                    .frame(width: size, height: size)
                    .mask(featherMask)
                    .overlay(rimLight)
                    .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
            .accessibilityLabel("Companion — \(state.accessibilityDescription)")
        }
    }

    private var resourceName: String {
        switch state.mode {
        case .ambient, .resting, .concerned:
            return scheme == .dark ? "orb_night" : "orb_day"
        case .listening, .speaking:
            return "orb_speak"
        case .thinking:
            return "orb_think"
        case .celebrating:
            return "orb_bloom"
        }
    }

    /// Opaque center, soft fade at the rim — no box, no hard edge, ever.
    private var featherMask: some View {
        RadialGradient(
            stops: [
                .init(color: .white, location: 0.0),
                .init(color: .white, location: 0.86),
                .init(color: .white.opacity(0), location: 1.0),
            ],
            center: .center,
            startRadius: 0,
            endRadius: size / 2
        )
    }

    /// A whisper of specular rim so the orb reads as glass on any ground.
    private var rimLight: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [.white.opacity(0.35), .clear, .white.opacity(0.12), .clear, .white.opacity(0.3)],
                    center: .center
                ),
                lineWidth: 1
            )
            .padding(size * 0.04)
            .blur(radius: 0.6)
            .blendMode(.plusLighter)
    }
}

/// AVPlayerLayer-backed looping surface with cross-fade between sources.
private struct OrbVideoSurface: UIViewRepresentable {
    let resource: String
    let breathPeriod: Double

    func makeUIView(context: Context) -> OrbVideoUIView {
        let view = OrbVideoUIView()
        view.show(resource: resource, animated: false)
        view.breathe(period: breathPeriod)
        return view
    }

    func updateUIView(_ uiView: OrbVideoUIView, context: Context) {
        uiView.show(resource: resource, animated: true)
        uiView.breathe(period: breathPeriod)
    }
}

/// Two stacked player layers; mood changes cross-fade between them so the
/// orb never cuts — it morphs.
final class OrbVideoUIView: UIView {
    private var layerA = AVPlayerLayer()
    private var layerB = AVPlayerLayer()
    private var looperA: AVPlayerLooper?
    private var looperB: AVPlayerLooper?
    private var activeIsA = true
    private var currentResource: String?
    private var currentBreathPeriod: Double = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        for playerLayer in [layerA, layerB] {
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.opacity = 0
            layer.addSublayer(playerLayer)
        }
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layerA.frame = bounds
        layerB.frame = bounds
        CATransaction.commit()
    }

    func show(resource: String, animated: Bool) {
        guard resource != currentResource else { return }
        currentResource = resource
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp4") else { return }

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        let looper = AVPlayerLooper(player: player, templateItem: item)

        let incoming = activeIsA ? layerB : layerA
        let outgoing = activeIsA ? layerA : layerB
        if activeIsA { looperB = looper } else { looperA = looper }
        activeIsA.toggle()

        incoming.player = player
        player.play()

        let duration = animated ? 0.7 : 0.0
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        incoming.opacity = 1
        outgoing.opacity = 0
        CATransaction.commit()
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak outgoing] in
            (outgoing?.player as? AVQueuePlayer)?.pause()
        }
    }

    /// A slow scale breath layered on top of the footage, tempo per mood.
    func breathe(period: Double) {
        guard abs(period - currentBreathPeriod) > 0.01 else { return }
        currentBreathPeriod = period
        layer.removeAnimation(forKey: "breath")
        let breath = CABasicAnimation(keyPath: "transform.scale")
        breath.fromValue = 0.985
        breath.toValue = 1.025
        breath.duration = period
        breath.autoreverses = true
        breath.repeatCount = .infinity
        breath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(breath, forKey: "breath")
    }
}
