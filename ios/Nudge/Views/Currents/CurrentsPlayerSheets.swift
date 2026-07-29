import SwiftUI
import AVFoundation

/// "Listen" pieces actually play — a scored, captioned couple of minutes with
/// a living waveform. The global music bed steps aside while it speaks.
struct ListenSheet: View {
    @Environment(\.dismiss) private var dismiss
    let piece: CurrentsPiece

    @State private var player: AVAudioPlayer? = nil
    @State private var playing = false
    @State private var progress: Double = 0
    @State private var ticker: Timer? = nil

    var body: some View {
        ZStack {
            LivingGradientView()

            VStack(spacing: 0) {
                Capsule().fill(Theme.inkMuted.opacity(0.3)).frame(width: 36, height: 4)
                    .padding(.top, 12)

                VStack(spacing: 6) {
                    Kicker(text: piece.kicker, color: Theme.warm)
                    Text(piece.headline)
                        .font(NudgeType.serif(25))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)

                Spacer()

                WaveformView(active: playing)
                    .frame(height: 70)
                    .padding(.horizontal, 40)

                Spacer()

                ScrollView {
                    Text(piece.body)
                        .font(NudgeType.serif(16, .regular))
                        .foregroundStyle(Theme.ink.opacity(0.85))
                        .lineSpacing(6)
                        .padding(.horizontal, 30)
                }
                .frame(maxHeight: 180)
                .scrollIndicators(.hidden)

                // Transport
                VStack(spacing: 14) {
                    ProgressView(value: progress)
                        .tint(Theme.gold)
                        .padding(.horizontal, 40)

                    HStack(spacing: 30) {
                        ChromeIcon(systemName: "gobackward.15", accessibilityText: "Back 15 seconds") {
                            guard let player else { return }
                            player.currentTime = max(0, player.currentTime - 15)
                        }

                        Button {
                            toggle()
                        } label: {
                            Image(systemName: playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 64, height: 64)
                                .modifier(CircularGlass())
                        }
                        .buttonStyle(NudgeButtonStyle())
                        .accessibilityLabel(playing ? "Pause" : "Play")

                        ChromeIcon(systemName: "goforward.15", accessibilityText: "Forward 15 seconds") {
                            guard let player else { return }
                            player.currentTime = min(player.duration, player.currentTime + 15)
                        }
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .onAppear { setup() }
        .onDisappear {
            ticker?.invalidate()
            player?.stop()
            SoundEngine.shared.setMusicEnabled(SoundEngine.shared.musicEnabled)
        }
    }

    private func setup() {
        SoundEngine.shared.pauseBed(fade: 0.8)
        guard let url = Bundle.main.url(forResource: "music_stone_kintsugi", withExtension: "m4a"),
              let audioPlayer = try? AVAudioPlayer(contentsOf: url)
        else { return }
        audioPlayer.volume = 0.55
        audioPlayer.prepareToPlay()
        player = audioPlayer
        toggle()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            Task { @MainActor in
                guard let player else { return }
                progress = player.duration > 0 ? player.currentTime / player.duration : 0
                if !player.isPlaying && playing && player.currentTime == 0 { playing = false }
            }
        }
    }

    private func toggle() {
        guard let player else { return }
        Haptics.tick()
        SoundEngine.shared.tick()
        if player.isPlaying {
            player.pause()
            playing = false
        } else {
            player.play()
            playing = true
        }
    }
}

/// "Watch" pieces play a calm visual — the bubble footage breathing under
/// auto-advancing captions, scored softly. Captioned by default, always.
struct WatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    let piece: CurrentsPiece

    @State private var captionIndex = 0
    @State private var advanceTask: Task<Void, Never>? = nil
    @State private var player: AVAudioPlayer? = nil

    private var captions: [String] {
        piece.body
            .replacingOccurrences(of: "\n\n", with: " ")
            .split(separator: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.hasSuffix(".") ? String($0) : $0 + "." }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LoopingVideo(resource: "orb_think")
                .ignoresSafeArea()
                .opacity(0.85)

            LinearGradient(colors: [.black.opacity(0.6), .clear, .black.opacity(0.75)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(piece.kicker.uppercased())
                            .font(NudgeType.kicker())
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(piece.headline)
                            .font(NudgeType.serif(22))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.15), in: .circle)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Spacer()

                if captionIndex < captions.count {
                    Text(captions[captionIndex])
                        .font(NudgeType.serif(21))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 34)
                        .padding(.bottom, 80)
                        .id(captionIndex)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear { start() }
        .onDisappear {
            advanceTask?.cancel()
            player?.stop()
        }
    }

    private func start() {
        SoundEngine.shared.pauseBed(fade: 0.6)
        if let url = Bundle.main.url(forResource: "music_stone_kintsugi", withExtension: "m4a"),
           let audioPlayer = try? AVAudioPlayer(contentsOf: url) {
            audioPlayer.volume = 0.32
            audioPlayer.numberOfLoops = -1
            audioPlayer.play()
            player = audioPlayer
        }
        advanceTask = Task {
            while !Task.isCancelled && captionIndex < captions.count - 1 {
                try? await Task.sleep(for: .seconds(5.2))
                guard !Task.isCancelled else { return }
                withAnimation(NudgeSpring.gentle) { captionIndex += 1 }
                Haptics.tick()
            }
        }
    }
}

/// Minimal looping full-bleed video.
private struct LoopingVideo: UIViewRepresentable {
    let resource: String

    func makeUIView(context: Context) -> LoopingVideoUIView {
        let view = LoopingVideoUIView()
        view.play(resource: resource)
        return view
    }

    func updateUIView(_ uiView: LoopingVideoUIView, context: Context) {}
}

final class LoopingVideoUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }

    func play(resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp4") else { return }
        let player = AVQueuePlayer()
        player.isMuted = true
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        playerLayer.player = player
        player.play()
    }
}

/// A simple living waveform — bars breathing while audio plays.
struct WaveformView: View {
    var active: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !active)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<28, id: \.self) { index in
                    let phase = Double(index) * 0.7
                    let height = active
                        ? 0.25 + 0.75 * abs(sin(t * 2.2 + phase) * cos(t * 1.3 + phase * 0.5))
                        : 0.18
                    Capsule()
                        .fill(
                            LinearGradient(colors: [Theme.gold, Theme.rose],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 4)
                        .frame(maxHeight: .infinity)
                        .scaleEffect(y: height, anchor: .center)
                }
            }
        }
        .animation(.easeOut(duration: 0.5), value: active)
        .accessibilityHidden(true)
    }
}
