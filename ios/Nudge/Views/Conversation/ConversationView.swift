import SwiftUI

/// The conversation is a place, not a screen — a deepened living scene the
/// rest of the app exhales into. The orb holds center stage; the companion's
/// words land directly on the canvas with a streaming glow; your words float
/// in glass. Stone Kintsugi plays underneath, one tap from silence.
struct ConversationView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    var orbSpace: Namespace.ID

    @State private var input = ""
    @FocusState private var focused: Bool
    @State private var rippleCounter = 0
    @State private var dragY: CGFloat = 0
    @State private var showVoice = false

    var body: some View {
        @Bindable var model = model
        ZStack {
            ConversationScene()

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Spacer()
                                Button {
                                    rippleCounter += 1
                                    Haptics.glass()
                                    SoundEngine.shared.glass()
                                    model.orb.set(.listening)
                                } label: {
                                    VideoOrbView(size: 110, state: model.orb, showsHalo: true)
                                        .matchedGeometryEffect(id: "orb", in: orbSpace)
                                }
                                .buttonStyle(NudgeButtonStyle())
                                .accessibilityLabel("Rumi")
                                Spacer()
                            }
                            .padding(.top, 2)
                            .padding(.bottom, 4)

                            ForEach(model.companion.turns) { turn in
                                TurnView(turn: turn)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .bottom)
                                                .combined(with: .opacity)
                                                .combined(with: .scale(scale: 0.97, anchor: .bottom)),
                                            removal: .opacity
                                        )
                                    )
                            }

                            if model.companion.isThinking {
                                ThinkingShimmer()
                            }

                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 4)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .animation(NudgeSpring.gentle, value: model.companion.turns.count)
                    .onChange(of: model.companion.turns) { _, _ in
                        withAnimation(NudgeSpring.ui) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }

                if model.companion.turns.count <= 1 {
                    suggestionChips
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                inputBar
            }
        }
        .offset(y: max(dragY, 0))
        .opacity(1 - Double(max(dragY, 0)) / 900)
        .fullScreenCover(isPresented: $showVoice) {
            VoiceModeView()
        }
    }

    // MARK: Header — the way out is unmissable; day/night and music ride along

    private var header: some View {
        VStack(spacing: 6) {
            // Grabber — the whole top edge drags the conversation closed.
            Capsule()
                .fill(Theme.inkMuted.opacity(0.35))
                .frame(width: 40, height: 4.5)
                .padding(.top, 8)

            HStack(spacing: 10) {
                ChromeIcon(systemName: "chevron.down", accessibilityText: "Close conversation") {
                    model.closeConversation()
                }

                Spacer()

                Text("Rumi")
                    .font(NudgeType.display(24))
                    .foregroundStyle(Theme.ink.opacity(0.9))

                Spacer()

                // Day / night — see both worlds without leaving the moment.
                ChromeIcon(
                    systemName: scheme == .dark ? "sun.haze" : "moon.stars",
                    accessibilityText: scheme == .dark ? "Switch to day" : "Switch to night"
                ) {
                    withAnimation(NudgeSpring.gentle) {
                        model.appearance = scheme == .dark ? "Day" : "Night"
                    }
                }

                // Stone Kintsugi underneath — one tap to silence, one to return.
                ChromeIcon(
                    systemName: model.musicOn ? "speaker.wave.2.fill" : "speaker.slash",
                    tint: model.musicOn ? Theme.gold : Theme.ink,
                    accessibilityText: model.musicOn ? "Mute music" : "Play music"
                ) {
                    model.musicOn.toggle()
                }
            }
            .padding(.horizontal, 20)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    guard value.translation.height > 0 else { return }
                    dragY = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 110 {
                        Haptics.glass()
                        dragY = 0
                        model.closeConversation()
                    } else {
                        withAnimation(NudgeSpring.ui) { dragY = 0 }
                    }
                }
        )
    }

    // MARK: Suggestion chips — doors into the things worth talking about

    private var suggestions: [String] {
        switch model.pathway {
        case .metabolic: return ["How's my A1c?", "Tonight's walk", "My refill", "Rough day"]
        case .oncology: return ["How are my counts?", "The fever rule", "I'm tired", "Feeling scared"]
        case .procedure: return ["What happens day-of?", "My pain trend", "The med cut-off", "I'm nervous"]
        case .cardiometabolic: return ["Today's weigh-in", "My kidney risk", "A little short of breath", "My refill"]
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        Haptics.tick()
                        SoundEngine.shared.tick()
                        model.companion.send(suggestion, orb: model.orb)
                    } label: {
                        Text(suggestion)
                            .font(NudgeType.rounded(13, .medium))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .capsuleGlass()
                    }
                    .buttonStyle(NudgeButtonStyle())
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Say anything…", text: $input, axis: .vertical)
                .font(NudgeType.rounded(15))
                .foregroundStyle(Theme.ink)
                .lineLimit(1...4)
                .focused($focused)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .modifier(InputGlass())
                .onSubmit(send)

            if input.isEmpty {
                // Voice — the conversation, out loud.
                Button {
                    Haptics.glass()
                    SoundEngine.shared.glass()
                    showVoice = true
                } label: {
                    Image(systemName: "waveform")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44)
                        .modifier(CircularGlass())
                }
                .buttonStyle(NudgeButtonStyle())
                .accessibilityLabel("Talk out loud")
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.base)
                    .frame(width: 44, height: 44)
                    .background(Theme.ink.opacity(input.isEmpty ? 0.35 : 1), in: .circle)
            }
            .buttonStyle(NudgeButtonStyle())
            .disabled(input.isEmpty)
            .accessibilityLabel("Send")
        }
        .animation(NudgeSpring.ui, value: input.isEmpty)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private func send() {
        let text = input
        input = ""
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Haptics.glass()
        SoundEngine.shared.send()
        rippleCounter += 1
        model.companion.send(text, orb: model.orb)
    }
}

/// Glass for the input bar — true liquid glass where available. The glass is
/// a background layer so it never wraps the UIKit-backed text field itself.
private struct InputGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.background {
                Color.clear
                    .glassEffect(.regular, in: .rect(cornerRadius: 26, style: .continuous))
            }
        } else {
            content
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.8)
                )
        }
    }
}

/// The deepened scene behind the conversation — aurora washes and drifting
/// light motes over the living gradient. Atmosphere, not decoration.
/// Shared with voice mode, which lives one layer deeper in the same place.
struct ConversationScene: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LivingGradientView()

            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: scenePhase != .active || reduceMotion)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let palette = Theme.conversationPalette(scheme)
                Canvas { context, size in
                    // Aurora washes — two broad, slow ribbons of color.
                    drawWash(context, size: size, t: t * 0.05, yBase: 0.18, color: palette.0, alpha: scheme == .dark ? 0.5 : 0.55)
                    drawWash(context, size: size, t: t * 0.04 + 3, yBase: 0.65, color: palette.1, alpha: scheme == .dark ? 0.38 : 0.42)

                    // Drifting light motes — fireflies in the glass.
                    var rng = SeededRandom(seed: 77)
                    for index in 0..<26 {
                        let speed = 0.018 + rng.unit() * 0.03
                        let baseX = rng.unit()
                        let baseY = rng.unit()
                        let phase = rng.unit() * Double.pi * 2
                        let x = CGFloat((baseX + t * speed * 0.4).truncatingRemainder(dividingBy: 1)) * size.width
                        let y = CGFloat(baseY) * size.height + CGFloat(sin(t * speed * 6 + phase) * 16)
                        let radius = 1.2 + CGFloat(rng.unit()) * 2.4
                        let twinkle = 0.25 + 0.3 * (0.5 + 0.5 * sin(t * (0.6 + rng.unit()) + phase))
                        let moteColor: Color = index % 3 == 0 ? Theme.gold : (index % 3 == 1 ? Theme.sky : Theme.rose)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(moteColor.opacity(twinkle * (scheme == .dark ? 1 : 0.7)))
                        )
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private func drawWash(_ context: GraphicsContext, size: CGSize, t: Double,
                          yBase: Double, color: Color, alpha: Double) {
        let centerX = size.width * CGFloat(0.5 + 0.3 * sin(t))
        let centerY = size.height * CGFloat(yBase + 0.06 * cos(t * 1.3))
        let radius = size.width * 0.85
        context.fill(
            Path(ellipseIn: CGRect(x: centerX - radius, y: centerY - radius * 0.7,
                                   width: radius * 2, height: radius * 1.4)),
            with: .radialGradient(
                Gradient(colors: [color.opacity(alpha), color.opacity(0)]),
                center: CGPoint(x: centerX, y: centerY),
                startRadius: 0,
                endRadius: radius
            )
        )
    }
}

/// One conversation turn — companion words sit directly on the canvas with a
/// soft glow and a breathing tail-shimmer while streaming; the user's words
/// float in glass capsules.
private struct TurnView: View {
    @Environment(AppModel.self) private var model
    let turn: ConversationTurn

    var body: some View {
        switch turn.role {
        case .user:
            HStack {
                Spacer(minLength: 60)
                Text(turn.text)
                    .font(NudgeType.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .capsuleGlass()
            }
        case .companion:
            VStack(alignment: .leading, spacing: 14) {
                StreamingText(text: turn.text, streaming: turn.streaming)
                richElement
            }
            .padding(.trailing, 36)
        }
    }

    @ViewBuilder
    private var richElement: some View {
        switch turn.rich {
        case .none:
            EmptyView()

        case .trend(let seriesID):
            if let series = model.series(seriesID) {
                OrganicSurface(radius: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Kicker(text: series.name)
                        GlowChart(series: series, accent: Theme.sky, height: 130, showAnnotation: true)
                        ProvenanceChip(text: series.provenance)
                    }
                    .padding(16)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

        case .habitProposal(let title, let context):
            proposalCard(kicker: "Habit proposal", kickerColor: Theme.life, title: title, detail: context,
                         doneLabel: "Held — I'll be quiet about it",
                         actionLabel: "Hold that spot") {
                model.companion.resolveRich(turnID: turn.id)
                if let journey = model.journeys.first, let habit = journey.habits.first {
                    model.keepHabit(journeyID: journey.id, habitID: habit.id)
                }
            }

        case .refillFix(let med, let detail):
            proposalCard(kicker: "Refill", kickerColor: Theme.gold, title: med, detail: detail,
                         doneLabel: "Done — it's handled",
                         actionLabel: "Switch to delivery") {
                model.companion.resolveRich(turnID: turn.id)
                Haptics.success()
            }

        case .guideAdd(let question):
            OrganicSurface(radius: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Kicker(text: "Added to your visit guide", color: Theme.gold)
                    Text(question)
                        .font(NudgeType.serif(16))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Label("Waiting in You → Discussion guide", systemImage: "text.book.closed")
                        .font(NudgeType.rounded(12, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(16)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .agentAction(let title, let detail):
            agentCard(title: title, detail: detail)

        case .program(let title):
            if let program = model.programs.first(where: { $0.title.lowercased() == title.lowercased() }) {
                ConversationProgramCard(program: program, turnID: turn.id)
            }
        }
    }

    private func proposalCard(kicker: String, kickerColor: Color, title: String, detail: String,
                              doneLabel: String, actionLabel: String,
                              onAccept: @escaping () -> Void) -> some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(text: kicker, color: kickerColor)
                Text(title)
                    .font(NudgeType.serif(17))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.inkMuted)
                if turn.richResolved {
                    Label(doneLabel, systemImage: "checkmark")
                        .font(NudgeType.rounded(13, .medium))
                        .foregroundStyle(Theme.life)
                        .padding(.top, 4)
                } else {
                    HStack(spacing: 10) {
                        Button(action: onAccept) {
                            Text(actionLabel)
                                .font(NudgeType.rounded(13, .semibold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .capsuleGlass()
                        }
                        .buttonStyle(NudgeButtonStyle())

                        Button {
                            model.companion.resolveRich(turnID: turn.id)
                        } label: {
                            Text("Not now")
                                .font(NudgeType.rounded(13, .medium))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func agentCard(title: String, detail: String) -> some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(text: "I can take this one", color: Theme.gold)
                Text(title)
                    .font(NudgeType.serif(17))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                if turn.richResolved {
                    Label("On it — you'll see it land", systemImage: "checkmark")
                        .font(NudgeType.rounded(13, .medium))
                        .foregroundStyle(Theme.life)
                        .padding(.top, 4)
                } else {
                    HStack(spacing: 10) {
                        Button {
                            model.companion.resolveRich(turnID: turn.id)
                            model.agentActions.insert(AgentAction(
                                title: title, detail: detail,
                                outcomeLine: "\(title) — done.",
                                glyph: "sparkles", leavesDevice: true, state: .done
                            ), at: 0)
                            model.orb.celebrate()
                            Haptics.bloom()
                            SoundEngine.shared.bloom()
                        } label: {
                            Text("Approve & go")
                                .font(NudgeType.rounded(13, .semibold))
                                .foregroundStyle(Theme.base)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Theme.ink, in: .capsule)
                        }
                        .buttonStyle(NudgeButtonStyle())

                        Button {
                            model.companion.resolveRich(turnID: turn.id)
                        } label: {
                            Text("Not now")
                                .font(NudgeType.rounded(13, .medium))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

/// A program offered mid-conversation — clinical why, plain disclosure,
/// equal-weight decline.
private struct ConversationProgramCard: View {
    @Environment(AppModel.self) private var model
    let program: Program
    let turnID: UUID

    var body: some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 9) {
                Kicker(text: "A door, if you want it", color: Theme.life)
                Text(program.title)
                    .font(NudgeType.serif(17))
                    .foregroundStyle(Theme.ink)
                Text(program.personalFit)
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if program.enrolled {
                    Label("You're in — first step is on Today", systemImage: "checkmark")
                        .font(NudgeType.rounded(13, .medium))
                        .foregroundStyle(Theme.life)
                } else {
                    HStack(spacing: 10) {
                        Button {
                            model.companion.resolveRich(turnID: turnID)
                            withAnimation(NudgeSpring.ui) { model.enroll(program.id) }
                        } label: {
                            Text("Count me in")
                                .font(NudgeType.rounded(13, .semibold))
                                .foregroundStyle(Theme.base)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Theme.ink, in: .capsule)
                        }
                        .buttonStyle(NudgeButtonStyle())

                        Button {
                            model.companion.resolveRich(turnID: turnID)
                            withAnimation(NudgeSpring.ui) { model.decline(program.id) }
                        } label: {
                            Text("Not for me")
                                .font(NudgeType.rounded(13, .medium))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .capsuleGlass()
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }

                if let sponsor = program.sponsor {
                    Text("Supported by \(sponsor) — they fund it; your data stays yours.")
                        .font(NudgeType.rounded(10.5, .medium))
                        .foregroundStyle(Theme.inkMuted.opacity(0.85))
                }
            }
            .padding(16)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

/// Companion text with a living tail — the last stretch of a streaming reply
/// glows softly, so tokens feel poured rather than printed.
private struct StreamingText: View {
    let text: String
    let streaming: Bool

    var body: some View {
        Text(text)
            .font(NudgeType.rounded(16.5))
            .foregroundStyle(Theme.ink)
            .lineSpacing(4.5)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: Theme.warm.opacity(streaming ? 0.3 : 0.16), radius: streaming ? 18 : 13)
            .animation(.easeOut(duration: 0.4), value: streaming)
            .contentTransition(.interpolate)
    }
}

/// Thinking — a quiet shimmer, no typing-dots cliché.
private struct ThinkingShimmer: View {
    @State private var phase = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.inkMuted.opacity(phase ? 0.7 : 0.25))
                    .frame(width: 6, height: 6)
                    .animation(
                        NudgeSpring.gentle.repeatForever(autoreverses: true).delay(Double(index) * 0.18),
                        value: phase
                    )
            }
        }
        .padding(.leading, 4)
        .onAppear { phase = true }
        .accessibilityLabel("Rumi is thinking")
    }
}
