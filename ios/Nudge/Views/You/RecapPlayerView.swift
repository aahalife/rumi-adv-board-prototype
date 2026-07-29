import SwiftUI

/// The Cinematic Recap — a 30-second film about *them*. Slow Ken-Burns drifts
/// over scene backdrops, serif title cards, the one place the score leads.
/// Earned, rare, skippable.
struct RecapPlayerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private struct Chapter {
        let image: String
        let kicker: String
        let title: String
        let detail: String
    }

    @State private var index = 0
    @State private var progress: Double = 0
    @State private var drift = false
    @State private var showText = false
    @State private var timerTask: Task<Void, Never>? = nil

    private let chapterSeconds: Double = 6.5

    private var chapters: [Chapter] {
        switch model.pathway {
        case .metabolic:
            return [
                Chapter(image: "recap_dawn", kicker: "Your chapter", title: "A year of turning it around",
                        detail: "From 9.4 to 8.4 — five readings, one direction."),
                Chapter(image: "recap_path", kicker: "The work", title: "Evenings that moved",
                        detail: "Eleven of fourteen nights. The Braves schedule never knew it was a health plan."),
                Chapter(image: "recap_garden", kicker: "The proof", title: "Your steadiest week",
                        detail: "Seven mornings, all drifting toward the calm zone."),
                Chapter(image: "recap_dawn", kicker: "Still going", title: "Under 8 by fall",
                        detail: "That's not a wish. That's a trajectory."),
            ]
        case .oncology:
            return [
                Chapter(image: "recap_dawn", kicker: "Your chapter", title: "Halfway through the hard part",
                        detail: "Three cycles met. Three to go."),
                Chapter(image: "recap_path", kicker: "The rhythm", title: "Your body kept its promises",
                        detail: "Counts recovered on time — every single cycle."),
                Chapter(image: "recap_garden", kicker: "The words", title: "\u{201C}Exactly what we hoped\u{201D}",
                        detail: "Dr. Rivera, reading your May scan."),
                Chapter(image: "recap_dawn", kicker: "Still going", title: "The good window opens again",
                        detail: "Day 10 is coming. Plan something that feels like you."),
            ]
        case .procedure:
            return [
                Chapter(image: "recap_dawn", kicker: "Your chapter", title: "Twelve days out, walking in strong",
                        detail: "Nine of ten prehab days kept."),
                Chapter(image: "recap_path", kicker: "The proof", title: "Pain already two points lower",
                        detail: "Your muscles started the work the new knee will finish."),
                Chapter(image: "recap_garden", kicker: "The setup", title: "A home that's ready for after",
                        detail: "Ice packs, clear walkways, the chair by the window."),
                Chapter(image: "recap_dawn", kicker: "Still going", title: "June 23 — and then the walks come back",
                        detail: "This is the before picture. You're building the after."),
            ]
        case .cardiometabolic:
            return [
                Chapter(image: "recap_dawn", kicker: "Your chapter", title: "Three conditions, one steady you",
                        detail: "Heart, sugar and kidneys — held together, not juggled."),
                Chapter(image: "recap_path", kicker: "The habit", title: "The morning you never miss",
                        detail: "Two weeks on the scale, steady within a pound."),
                Chapter(image: "recap_garden", kicker: "The catch", title: "Kidneys, protected early",
                        detail: "The risk model saw it coming — and your medicine answered."),
                Chapter(image: "recap_dawn", kicker: "Still going", title: "Quiet is the goal",
                        detail: "A1c near target, breath easy, numbers that hold."),
            ]
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Backdrop with slow Ken-Burns drift
            backdrop
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.55), .clear, .black.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    // Progress — a soft light line, never a scrubber.
                    HStack(spacing: 5) {
                        ForEach(chapters.indices, id: \.self) { chapterIndex in
                            Capsule()
                                .fill(.white.opacity(chapterIndex < index ? 0.9 : 0.3))
                                .overlay(alignment: .leading) {
                                    if chapterIndex == index {
                                        GeometryReader { geo in
                                            Capsule()
                                                .fill(.white.opacity(0.9))
                                                .frame(width: geo.size.width * progress)
                                        }
                                    }
                                }
                                .frame(height: 3)
                        }
                    }

                    Button {
                        end()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.15), in: .circle)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .accessibilityLabel("Close recap")
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer()

                if index < chapters.count {
                    let chapter = chapters[index]
                    VStack(alignment: .leading, spacing: 10) {
                        Text(chapter.kicker.uppercased())
                            .font(NudgeType.kicker())
                            .tracking(2.2)
                            .foregroundStyle(.white.opacity(0.75))
                        Text(chapter.title)
                            .font(NudgeType.serif(34))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(chapter.detail)
                            .font(NudgeType.rounded(15.5))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 70)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 18)
                    .id(index)
                }
            }
        }
        .statusBarHidden()
        .onTapGesture { advance() }
        .onAppear { start() }
        .onDisappear {
            timerTask?.cancel()
            SoundEngine.shared.stopRecap()
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if index < chapters.count {
            let name = chapters[index].image
            Group {
                if UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LivingGradientView()
                        SceneVisual(seed: 60 + index * 7, height: 900)
                    }
                }
            }
            .scaleEffect(drift ? 1.18 : 1.04)
            .offset(x: drift ? -14 : 12, y: drift ? -18 : 10)
            .animation(.linear(duration: chapterSeconds + 1).delay(0.05), value: drift)
            .id(index)
            .transition(.opacity)
            .allowsHitTesting(false)
        }
    }

    private func start() {
        SoundEngine.shared.startRecap()
        Haptics.glass()
        playChapter()
    }

    private func playChapter() {
        timerTask?.cancel()
        progress = 0
        drift = false
        showText = false
        withAnimation(NudgeSpring.gentle.delay(0.25)) { showText = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            drift = true
        }
        timerTask = Task { @MainActor in
            let steps = 80
            for step in 0...steps {
                guard !Task.isCancelled else { return }
                progress = Double(step) / Double(steps)
                try? await Task.sleep(for: .seconds(chapterSeconds / Double(steps)))
            }
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    private func advance() {
        if index >= chapters.count - 1 {
            end()
            return
        }
        Haptics.tick()
        withAnimation(NudgeSpring.gentle) { index += 1 }
        playChapter()
    }

    private func end() {
        timerTask?.cancel()
        SoundEngine.shared.stopRecap()
        model.orb.celebrate()
        dismiss()
    }
}
