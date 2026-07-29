import SwiftUI

/// Onboarding is a conversation, not a form. Rumi introduces itself over a
/// soft pastel aura while "Barley Thunder" plays underneath; it learns your
/// name, finds your records, and visibly shapes the world around you.
struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var model

    enum Stage: Int {
        case welcome, aboutYou, path, shaping, connect, healthKit, conversation, epsilon
    }

    @State private var stage: Stage = .welcome
    @State private var values = ""
    @State private var barrier = ""
    @State private var tone = "Straight talk"

    var body: some View {
        @Bindable var model = model
        ZStack {
            // A painted pastel ground + drifting light — never a bare screen.
            if UIImage(named: "pastel_gradient_glow_bg") != nil {
                Image("pastel_gradient_glow_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.92)
                    .accessibilityHidden(true)
            }
            OnboardingAura(intensity: stage == .welcome ? 1 : 0.55)

            VStack(spacing: 0) {
                VideoOrbView(size: stage == .welcome ? 178 : 96,
                             state: model.orb,
                             showsHalo: stage == .welcome)
                    .padding(.top, stage == .welcome ? 84 : 14)
                    .animation(NudgeSpring.gentle, value: stage)

                // Each stage is locked to the visible scroll container, so it can
                // never be wider than the screen; it scrolls only if the keyboard
                // compresses the available height.
                ScrollView {
                    Group {
                        switch stage {
                        case .welcome:
                            WelcomeView { advance(.aboutYou) }
                        case .aboutYou:
                            AboutYouView { advance(.path) }
                        case .path:
                            PathChoiceView { chosen in
                                model.switchPathway(chosen)
                                advance(.shaping)
                            }
                        case .shaping:
                            ShapingView(pathway: model.pathway) { advance(.connect) }
                        case .connect:
                            RecordConnectView { advance(.healthKit) }
                        case .healthKit:
                            HealthKitAskView { advance(.conversation) }
                        case .conversation:
                            OnboardingConversationView(values: $values, barrier: $barrier, tone: $tone) {
                                advance(.epsilon)
                            }
                        case .epsilon:
                            EpsilonConsentView { consented in
                                model.epsilonConsent = consented
                                model.orb.celebrate()
                                SoundEngine.shared.bloom()
                                Haptics.bloom()
                                SoundEngine.shared.playBed(.ambient, fade: 3.0)
                                model.completeOnboarding(values: values, barrier: barrier, tone: tone)
                            }
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                    .transition(stageTransition)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }

            // The score's mute lives top-right from the very first breath.
            VStack {
                HStack {
                    Spacer()
                    ChromeIcon(
                        systemName: model.musicOn ? "speaker.wave.2.fill" : "speaker.slash",
                        tint: model.musicOn ? Theme.gold : Theme.ink,
                        accessibilityText: model.musicOn ? "Mute music" : "Play music"
                    ) {
                        model.musicOn.toggle()
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 6)
                Spacer()
            }
        }
        .onAppear {
            SoundEngine.shared.playBed(.onboarding, fade: 3.2)
        }
    }

    /// Pure breath — opacity and a whisper of scale. No x-offsets, so an
    /// interrupted transition can never strand a stage off the screen edge.
    private var stageTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.985)),
            removal: .opacity.combined(with: .scale(scale: 1.012))
        )
    }

    private func advance(_ next: Stage) {
        Haptics.glass()
        SoundEngine.shared.whoosh()
        withAnimation(NudgeSpring.gentle) { stage = next }
    }
}

/// Drifting pastel light blooms over the painted ground — the orb's nest.
struct OnboardingAura: View {
    var intensity: Double

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * 0.07
            let palette = Theme.companion(scheme)
            Canvas { context, size in
                let blooms: [(Double, Double, Double, Color)] = [
                    (0.5 + 0.18 * sin(t), 0.22 + 0.05 * cos(t * 0.8), 0.46, palette[0]),
                    (0.24 + 0.08 * cos(t * 0.6), 0.5 + 0.1 * sin(t * 0.9), 0.34, palette[1]),
                    (0.78 + 0.07 * sin(t * 0.7 + 2), 0.62 + 0.08 * cos(t * 0.5), 0.38, palette[2]),
                ]
                for (x, y, radius, color) in blooms {
                    let center = CGPoint(x: size.width * x, y: size.height * y)
                    let r = size.width * radius
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(0.26 * intensity), color.opacity(0)]),
                            center: center, startRadius: 0, endRadius: r
                        )
                    )
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .animation(NudgeSpring.gentle, value: intensity)
    }
}

/// Welcome — the orb breathes into existence inside a nest of light.
struct WelcomeView: View {
    var onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                Text("Rumi")
                    .font(NudgeType.display(64))
                    .foregroundStyle(Theme.ink)
                    .shadow(color: .white.opacity(0.55), radius: 18, y: 2)
                Text("Hi. I'm the one who'll remember\nthe small stuff between visits —\nand cheer embarrassingly hard for you.")
                    .font(NudgeType.rounded(16, .medium))
                    .foregroundStyle(Theme.ink.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 16))
                        Text("Continue with Apple")
                            .font(NudgeType.rounded(16, .semibold))
                    }
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())

                Button(action: onContinue) {
                    Text("Use a phone number instead")
                        .font(NudgeType.rounded(14, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                .buttonStyle(NudgeButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 44)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(NudgeSpring.gentle.delay(0.5)) { appeared = true }
        }
    }
}

/// Name & birthday — so records can find you and the greeting can be yours.
/// Pre-filled from Apple sign-in when available; everything editable.
struct AboutYouView: View {
    @Environment(AppModel.self) private var model
    var onDone: () -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -45, to: .now) ?? .now
    @FocusState private var focusedField: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("First things first — you.")
                    .font(NudgeType.serif(26))
                    .foregroundStyle(Theme.ink)
                Text("Your name so I can say hi properly, and your birthday so your hospital's records know it's really you. That's the whole form, promise.")
                    .font(NudgeType.rounded(14, .medium))
                    .foregroundStyle(Theme.ink.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    nameField("First name", text: $firstName, field: 0)
                    nameField("Last name", text: $lastName, field: 1)
                }

                HStack {
                    Text("Birthday")
                        .font(NudgeType.rounded(14, .medium))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    DatePicker("", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
                )
            }
            .padding(.horizontal, 26)
            .padding(.top, 22)

            HStack(spacing: 7) {
                Image(systemName: "lock")
                    .font(.system(size: 10, weight: .medium))
                Text("Used only to match your records — never sold, never shared without you.")
                    .font(NudgeType.rounded(11.5))
            }
            .foregroundStyle(Theme.inkMuted)
            .padding(.horizontal, 30)
            .padding(.top, 12)

            Spacer()

            Button {
                model.profile.firstName = firstName.trimmingCharacters(in: .whitespaces).capitalizedFirst
                model.profile.lastName = lastName.trimmingCharacters(in: .whitespaces).capitalizedFirst
                model.profile.birthDate = birthDate
                onDone()
            } label: {
                Text(firstName.isEmpty ? "I'll stay mysterious for now" : "Nice to meet you — onward")
                    .font(NudgeType.rounded(16, .semibold))
                    .foregroundStyle(firstName.isEmpty ? Theme.ink : Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(firstName.isEmpty ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Theme.ink), in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .animation(NudgeSpring.ui, value: firstName.isEmpty)
        }
        .onAppear {
            firstName = model.profile.firstName
            lastName = model.profile.lastName
            if let dob = model.profile.birthDate { birthDate = dob }
        }
    }

    private func nameField(_ placeholder: String, text: Binding<String>, field: Int) -> some View {
        TextField(placeholder, text: text)
            .font(NudgeType.rounded(15))
            .textContentType(field == 0 ? .givenName : .familyName)
            .focused($focusedField, equals: field)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
            )
    }
}

/// "What are you carrying?" — the choice that shapes the whole experience.
struct PathChoiceView: View {
    var onChoice: (CarePathway) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's on your plate right now?")
                    .font(NudgeType.serif(26))
                    .foregroundStyle(Theme.ink)
                Text("This shapes everything I watch for — so you never have to explain the basics twice.")
                    .font(NudgeType.rounded(14, .medium))
                    .foregroundStyle(Theme.ink.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)

            VStack(spacing: 11) {
                ForEach(CarePathway.allCases) { pathway in
                    Button {
                        onChoice(pathway)
                    } label: {
                        HStack(spacing: 14) {
                            if UIImage(named: heroImage(pathway)) != nil {
                                Color(.secondarySystemBackground)
                                    .frame(width: 52, height: 52)
                                    .overlay {
                                        Image(heroImage(pathway))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 16))
                            } else {
                                Image(systemName: pathway.glyph)
                                    .font(.system(size: 17, weight: .light))
                                    .foregroundStyle(Theme.warm)
                                    .frame(width: 52, height: 52)
                                    .background(Theme.warm.opacity(0.12), in: .rect(cornerRadius: 16))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(pathway.choiceLabel)
                                    .font(NudgeType.serif(17))
                                    .foregroundStyle(Theme.ink)
                                Text(pathway.choiceDetail)
                                    .font(NudgeType.rounded(12.5))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
                        )
                    }
                    .buttonStyle(NudgeButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            Spacer()

            Text("Carrying more than one thing? Pick the loudest — I'll learn the rest from your records.")
                .font(NudgeType.rounded(12.5, .medium))
                .foregroundStyle(Theme.ink.opacity(0.66))
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
        }
    }

    private func heroImage(_ pathway: CarePathway) -> String {
        switch pathway {
        case .metabolic: return "condition_diabetes"
        case .oncology: return "condition_chemo"
        case .procedure: return "condition_procedure"
        case .cardiometabolic: return "condition_diabetes"
        }
    }
}

/// The world visibly re-shapes itself — the user watches the app learn them.
struct ShapingView: View {
    @Environment(AppModel.self) private var model
    let pathway: CarePathway
    var onDone: () -> Void

    @State private var shown: Int = 0
    @State private var finished = false

    private var lines: [String] {
        switch pathway {
        case .metabolic:
            return [
                "Okay — settling in around the long game.",
                "Your symptom list now knows about cramps, foot tingling, and dizzy spells — the ones that actually matter here.",
                "I'll keep A1c, blood pressure and kidney trends one glance away, charted before every visit.",
                "And your care plan gets mapped to real evenings — not a calendar fantasy.",
            ]
        case .oncology:
            return [
                "Okay — settling in around your treatment.",
                "Your symptom list now speaks chemo: nausea, counts, mouth sores, the tingling worth tracking for your team.",
                "I'll learn your cycle's rhythm — the queasy window, the low-count days, and the good days worth planning around.",
                "And the fever rule stays one tap from the on-call line, always.",
            ]
        case .procedure:
            return [
                "Okay — settling in around June 23.",
                "Your world becomes a countdown: prehab, the med cut-offs, the night-before list — each thing at its right time.",
                "Pain and swelling get a place on the body map, charted for your pre-op visit.",
                "And after surgery, I flip with you — recovery milestones, watch-items, and PT cheerleading.",
            ]
        case .cardiometabolic:
            return [
                "Okay — settling in around all three: heart, sugar and kidneys.",
                "Your symptom list now speaks the language that matters here — breath, swelling, the morning weigh-in.",
                "I'll watch your weight, pressure and kidney trends together, since in your body they pull on the same strings.",
                "And I'll keep your primary, cardiology and nephrology reading the same page — never working blind.",
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(lines.prefix(shown).enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Theme.life)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        Text(line)
                            .font(NudgeType.rounded(15))
                            .foregroundStyle(Theme.ink.opacity(0.9))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)

            Spacer()

            if finished {
                Button(action: onDone) {
                    Text("That's exactly it — keep going")
                        .font(NudgeType.rounded(16, .semibold))
                        .foregroundStyle(Theme.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .transition(.opacity)
            }
        }
        .onAppear {
            model.orb.set(.thinking)
            Task {
                for index in 1...lines.count {
                    try? await Task.sleep(for: .seconds(index == 1 ? 0.5 : 1.15))
                    withAnimation(NudgeSpring.gentle) { shown = index }
                    Haptics.tick()
                    SoundEngine.shared.tick()
                }
                model.orb.set(.ambient)
                withAnimation(NudgeSpring.gentle) { finished = true }
            }
        }
    }
}
