import SwiftUI

/// Not a dashboard. One living scene: the orb in ambient state, the Thread
/// (max 3 moments), the companion's pending actions, and the signature
/// pull-to-talk gesture. The scene knows whose life it's holding.
struct TodayCanvasView: View {
    @Environment(AppModel.self) private var model
    var orbSpace: Namespace.ID

    @State private var pull: CGFloat = 0
    @State private var pullTriggered = false
    @State private var plusPulse = false

    private var pullProgress: CGFloat { min(pull / 110, 1) }

    var body: some View {
        ZStack {
            scroll

            // The '+' floats on its own layer — outside the scroll's offset and
            // melt effects, so it is always exactly where the finger expects.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    plusButton
                }
            }
        }
    }

    private var scroll: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 6)

                Button {
                    Haptics.glass()
                    SoundEngine.shared.glass()
                    model.openConversation()
                } label: {
                    VideoOrbView(size: 150, state: model.orb, showsHalo: true)
                        .matchedGeometryEffect(id: "orb", in: orbSpace)
                        .scaleEffect(1 + pullProgress * 0.14)
                }
                .buttonStyle(NudgeButtonStyle())
                .accessibilityLabel("Talk with Rumi")
                .highPriorityGesture(pullToTalk)
                .padding(.top, 4)

                VStack(spacing: 6) {
                    Text(greeting)
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text(statusLine)
                        .font(NudgeType.rounded(14))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                Text("pull down to talk")
                    .font(NudgeType.rounded(11, .medium))
                    .foregroundStyle(Theme.inkMuted.opacity(0.55 + pullProgress * 0.45))
                    .padding(.top, 8)

                // A gentle line when the care team has something new — so the
                // user always knows to look, without it ever feeling like an alarm.
                if model.careUnreadCount > 0 {
                    careAlertBanner
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // The companion's hands — steps it can take, waiting for one tap.
                if let action = model.pendingActions.first {
                    AgentActionCard(action: action)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // The agent network, surfaced — calm by default, capable when you
                // look. Rumi's quiet differentiator, never hidden.
                if !model.agentTasksInMotion.isEmpty || !model.agentTasksWaiting.isEmpty {
                    AgentPulseCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // The Thread — the companion's chosen moments for right now.
                VStack(spacing: 13) {
                    if model.moments.isEmpty {
                        threadResolved
                    } else {
                        ForEach(model.moments.prefix(3)) { moment in
                            MomentCard(moment: moment)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                lifeStrip
                    .padding(.top, 18)

                // Generous tail so the last row always clears the floating dock
                // and the whole page scrolls freely from anywhere on screen.
                Color.clear.frame(height: 150)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.always)
        .offset(y: pull * 0.3)
        .sensoryFeedback(.impact(weight: .medium), trigger: pullTriggered)
        .onAppear {
            plusPulse = true
            if model.justBloomedToday {
                model.justBloomedToday = false
                Task {
                    try? await Task.sleep(for: .seconds(1.0))
                    model.orb.celebrate()
                    SoundEngine.shared.bloom()
                }
            }
        }
    }

    // MARK: Header — settings · condition, one glass voice

    private var header: some View {
        HStack(spacing: 10) {
            ChromeIcon(systemName: "slider.horizontal.3", accessibilityText: "Settings") {
                model.showSettings = true
            }

            // The condition is present, not shouted — one quiet chip into
            // the full picture: conditions, plan, what to expect.
            Button {
                Haptics.tick()
                model.tab = .you
                NotificationCenter.default.post(name: .nudgeOpenConditions, object: nil)
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.life)
                        .frame(width: 6, height: 6)
                    Text(model.persona.conditionChip)
                        .font(NudgeType.rounded(12, .medium))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .capsuleGlass()
            }
            .buttonStyle(NudgeButtonStyle())
            .accessibilityLabel("Your conditions and care plan")

            Spacer()

            // The score's one-tap silence — top right, from the very first screen.
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

    // MARK: The '+' — impossible to miss, beautiful to press

    private var plusButton: some View {
        Button {
            Haptics.pull()
            SoundEngine.shared.glass()
            model.quickLogMedID = nil
            model.showQuickLog = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Theme.ink)
                .frame(width: 56, height: 56)
                .modifier(CircularGlass())
                .background {
                    // Breathing gradient ring — pure decoration, never a finger trap.
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [Theme.warm, Theme.rose, Theme.gold, Theme.warm],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 64, height: 64)
                        .opacity(plusPulse ? 0.9 : 0.4)
                        .scaleEffect(plusPulse ? 1.04 : 0.97)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: plusPulse)
                        .allowsHitTesting(false)
                }
                .contentShape(Circle().inset(by: -8))
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel("Log something — a symptom, a meal, a move, a med")
        .padding(.trailing, 22)
        .padding(.bottom, 96)
    }

    // MARK: Life strip — today's meals, moves and meds as floating objects

    private var lifeStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                openLife()
            } label: {
                HStack {
                    Kicker(text: "Today at your table")
                    Spacer()
                    HStack(spacing: 4) {
                        Text("See it all")
                            .font(NudgeType.rounded(12, .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(Theme.warm)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(NudgeButtonStyle())
            .padding(.horizontal, 22)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(todayEntries.prefix(6)) { entry in
                        Button { openLife() } label: {
                            LifeThumb(entry: entry)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                    if todayEntries.isEmpty {
                        Text("Nothing logged yet — the '+' is right there, glowing.")
                            .font(NudgeType.rounded(12.5))
                            .foregroundStyle(Theme.inkMuted)
                            .padding(.vertical, 28)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 20)
        }
    }

    private func openLife() {
        Haptics.glass()
        SoundEngine.shared.glass()
        withAnimation(NudgeSpring.ui) { model.tab = .you }
        NotificationCenter.default.post(name: .nudgeOpenLife, object: nil)
    }

    // MARK: Care-team alert — a calm nudge toward the Care hub

    private var careAlertBanner: some View {
        Button {
            Haptics.glass()
            SoundEngine.shared.glass()
            withAnimation(NudgeSpring.ui) { model.tab = .care }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: "cross.case")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Theme.sky)
                        .frame(width: 38, height: 38)
                        .background(Theme.sky.opacity(0.14), in: .circle)
                    Circle()
                        .fill(Theme.warm)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().strokeBorder(Theme.surface, lineWidth: 1.5))
                        .offset(x: 14, y: -14)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(careAlertTitle)
                        .font(NudgeType.serif(16))
                        .foregroundStyle(Theme.ink)
                    Text("Tap to open your Care hub")
                        .font(NudgeType.rounded(12))
                        .foregroundStyle(Theme.inkMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Theme.inkMuted)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Theme.sky.opacity(0.3), lineWidth: 0.9)
            )
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel("\(careAlertTitle). Opens your Care hub.")
    }

    private var careAlertTitle: String {
        let count = model.careUnreadCount
        if model.threads.contains(where: { $0.unread }) {
            return count > 1 ? "\(count) updates from your care team" : "A new message from your care team"
        }
        return "A new result is ready"
    }

    private var todayEntries: [CareEntry] {
        model.entries.filter { Calendar.current.isDateInToday($0.at) }
    }

    private var threadResolved: some View {
        VStack(spacing: 10) {
            SceneVisual(seed: 30, height: 70)
            Text("You're set for now — I'll keep watch.")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)
        }
        .padding(.vertical, 16)
    }

    private var pullToTalk: some Gesture {
        DragGesture()
            .onChanged { value in
                guard value.translation.height > 0,
                      abs(value.translation.height) > abs(value.translation.width)
                else { return }
                pull = value.translation.height * 0.7
                model.orb.set(.listening)
            }
            .onEnded { _ in
                if pullProgress >= 0.95 {
                    pullTriggered.toggle()
                    SoundEngine.shared.whoosh()
                    model.openConversation()
                } else {
                    model.orb.set(.ambient)
                }
                withAnimation(NudgeSpring.gentle) { pull = 0 }
            }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = model.displayFirstName
        switch hour {
        case 5..<12: return "Morning, \(name)."
        case 12..<17: return "Afternoon, \(name)."
        default: return "Evening, \(name)."
        }
    }

    private var statusLine: String {
        model.moments.isEmpty ? model.persona.statusQuiet : model.persona.statusBusy
    }
}

/// A small studio-photo tile for the Today life strip.
struct LifeThumb: View {
    let entry: CareEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color(.secondarySystemBackground)
                .frame(width: 92, height: 92)
                .overlay {
                    Image(entry.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.8)
                )
                .shadow(color: Theme.shadow.opacity(0.14), radius: 10, y: 4)

            Text(entry.title)
                .font(NudgeType.rounded(11.5, .medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(entry.at.formatted(date: .omitted, time: .shortened))
                .font(NudgeType.number(10, .medium))
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(width: 92)
    }
}

/// The companion proposing a real step — approve or wave it off, one tap each.
struct AgentActionCard: View {
    @Environment(AppModel.self) private var model
    let action: AgentAction
    @State private var sweep = 0

    var body: some View {
        OrganicSurface(radius: 30) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 9) {
                    Image(systemName: action.glyph)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Theme.gold)
                        .frame(width: 32, height: 32)
                        .background(Theme.gold.opacity(0.14), in: .circle)
                    VStack(alignment: .leading, spacing: 1) {
                        Kicker(text: "I can take this one", color: Theme.gold)
                        Text(action.title)
                            .font(NudgeType.serif(17))
                            .foregroundStyle(Theme.ink)
                    }
                }
                Text(action.detail)
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button {
                        sweep += 1
                        model.approveAction(action.id)
                    } label: {
                        Text(action.leavesDevice ? "Approve & go" : "Yes, do it")
                            .font(NudgeType.rounded(13.5, .semibold))
                            .foregroundStyle(Theme.base)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Theme.ink, in: .capsule)
                    }
                    .buttonStyle(NudgeButtonStyle())

                    Button {
                        model.declineAction(action.id)
                    } label: {
                        // Plain chip — this card rides shader sweeps, and glass
                        // must never sit under a layer effect.
                        Text("Not now")
                            .font(NudgeType.rounded(13.5, .medium))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Theme.raised.opacity(0.9), in: .capsule)
                            .overlay(Capsule().strokeBorder(Theme.edge.opacity(0.7), lineWidth: 0.8))
                    }
                    .buttonStyle(NudgeButtonStyle())

                    Spacer()

                    if action.leavesDevice {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised")
                                .font(.system(size: 9, weight: .medium))
                            Text("Nothing sends without you")
                                .font(NudgeType.rounded(10, .medium))
                        }
                        .foregroundStyle(Theme.inkMuted.opacity(0.8))
                    }
                }
            }
            .padding(17)
        }
        .lightSweep(trigger: sweep, strength: 0.7)
        .rippleOnTap(glow: 0.45)
    }
}

extension Notification.Name {
    /// Asks the You tab to open the conditions overview.
    static let nudgeOpenConditions = Notification.Name("nudgeOpenConditions")
    /// Asks the You tab to open the Life Catalog (meals, moves, meds).
    static let nudgeOpenLife = Notification.Name("nudgeOpenLife")
}
