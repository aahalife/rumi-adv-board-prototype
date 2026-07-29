import SwiftUI

/// One simple door, many rails behind it: find your provider → sign in →
/// we match your record → Sano narrates what it found, warmly. Every step is
/// honest about what's happening, and the whole thing is skippable.
struct RecordConnectView: View {
    @Environment(AppModel.self) private var model
    var onDone: () -> Void

    enum Phase {
        case pick, signIn(Provider), match(Provider), discovering
    }

    struct Provider: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let rail: String
        let portal: String
    }

    @State private var phase: Phase = .pick
    @State private var search = ""
    @State private var narration: [String] = []
    @State private var finished = false
    @State private var portalUser = ""
    @State private var portalPass = ""

    private let providers: [Provider] = [
        Provider(name: "Piedmont Internal Medicine", rail: "Direct connection", portal: "Privia"),
        Provider(name: "Emory Healthcare", rail: "Patient sign-in", portal: "MyChart"),
        Provider(name: "Northside Hospital", rail: "Patient sign-in", portal: "MyChart"),
        Provider(name: "Midtown Orthopedics", rail: "Patient sign-in", portal: "Athena"),
        Provider(name: "CVS Pharmacy", rail: "Prescription records", portal: "CVS"),
        Provider(name: "Walgreens", rail: "Prescription records", portal: "Walgreens"),
        Provider(name: "Anthem (insurance)", rail: "Claims · can wait for later", portal: "Anthem"),
    ]

    private var discoveries: [String] {
        let name = model.displayFirstName
        switch model.pathway {
        case .metabolic:
            return [
                "Found you, \(name) — record matched on name and birthday. ✓",
                "Your labs came through: the March A1c is here, with four readings before it.",
                "Medication list assembled — metformin, lisinopril, atorvastatin, all reconciled.",
                "That's your whole story in one place. You'll never have to retell it in a waiting room again.",
            ]
        case .oncology:
            return [
                "Found you, \(name) — record matched on name and birthday. ✓",
                "Your treatment plan is here: AC-T, cycle 3 of 6, with every infusion date.",
                "Labs synced — your counts have recovered on time, every single cycle.",
                "That's your whole story, assembled. Your team and I are reading the same page now.",
            ]
        case .procedure:
            return [
                "Found you, \(name) — record matched on name and birthday. ✓",
                "June 23 is on the books at Midtown Surgical, with Dr. Chen's full pre-op plan.",
                "The med rules came too — I've flagged the June 16 ibuprofen cut-off already.",
                "That's everything in one place. From here, we just count down together.",
            ]
        case .cardiometabolic:
            return [
                "Found you, \(name) — record matched on name and birthday. ✓",
                "Three teams, one record: primary care, cardiology and nephrology, all reconciled.",
                "Labs synced — and I caught the early kidney-risk signal in your eGFR trend.",
                "That's your whole story in one place, with everyone finally reading the same page.",
            ]
        }
    }

    private var filteredProviders: [Provider] {
        guard !search.isEmpty else { return providers }
        return providers.filter { $0.name.localizedStandardContains(search) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch phase {
            case .pick:
                pickPhase.transition(.opacity)
            case .signIn(let provider):
                signInPhase(provider).transition(.opacity.combined(with: .move(edge: .trailing)))
            case .match(let provider):
                matchPhase(provider).transition(.opacity)
            case .discovering:
                discoveringPhase.transition(.opacity)
            }
        }
        .animation(NudgeSpring.gentle, value: narrationCount)
    }

    private var narrationCount: Int { narration.count }

    // MARK: Phase 1 — find your people

    private var pickPhase: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shall I read up on you?")
                    .font(NudgeType.serif(25))
                    .foregroundStyle(Theme.ink)
                Text("Point me at your providers and I'll quietly gather your story — labs, meds, visits — so you never retell it twice.")
                    .font(NudgeType.rounded(14))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Theme.inkMuted)
                TextField("Search your hospital or pharmacy…", text: $search)
                    .font(NudgeType.rounded(14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface.opacity(0.95), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9))
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(filteredProviders) { provider in
                        Button {
                            Haptics.tick()
                            SoundEngine.shared.tick()
                            withAnimation(NudgeSpring.gentle) { phase = .signIn(provider) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.name)
                                        .font(NudgeType.rounded(15, .medium))
                                        .foregroundStyle(Theme.ink)
                                    Text("\(provider.portal) · \(provider.rail)")
                                        .font(NudgeType.rounded(11.5))
                                        .foregroundStyle(Theme.inkMuted)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 17, weight: .light))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                            .padding(15)
                            .background(Theme.surface.opacity(0.88), in: .rect(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            Button(action: onDone) {
                Text("I'll do this later")
                    .font(NudgeType.rounded(14, .medium))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(NudgeButtonStyle())
            .padding(.bottom, 24)
        }
    }

    // MARK: Phase 2 — the portal sign-in (the real-world step, made gentle)

    private func signInPhase(_ provider: Provider) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(text: "\(provider.portal) · secure sign-in", color: Theme.sky)
                Text(provider.name)
                    .font(NudgeType.serif(24))
                    .foregroundStyle(Theme.ink)
                Text("This is the same login you'd use on their patient portal. It goes straight to them — I never see your password.")
                    .font(NudgeType.rounded(13.5))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            VStack(spacing: 12) {
                TextField("\(provider.portal) username", text: $portalUser)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .font(NudgeType.rounded(15))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9))

                SecureField("Password", text: $portalPass)
                    .textContentType(.password)
                    .font(NudgeType.rounded(15))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9))
            }
            .padding(.horizontal, 26)
            .padding(.top, 20)

            HStack(spacing: 7) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.life)
                Text("Read-only access. You can disconnect any time in the Privacy Center.")
                    .font(NudgeType.rounded(11.5))
                    .foregroundStyle(Theme.inkMuted)
            }
            .padding(.horizontal, 30)
            .padding(.top, 12)

            Spacer()

            VStack(spacing: 11) {
                Button {
                    Haptics.glass()
                    withAnimation(NudgeSpring.gentle) { phase = .match(provider) }
                } label: {
                    Text("Sign in securely")
                        .font(NudgeType.rounded(16, .semibold))
                        .foregroundStyle(Theme.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())
                .disabled(portalUser.isEmpty)
                .opacity(portalUser.isEmpty ? 0.5 : 1)

                Button {
                    withAnimation(NudgeSpring.gentle) { phase = .pick }
                } label: {
                    Text("Back")
                        .font(NudgeType.rounded(14, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                .buttonStyle(NudgeButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
    }

    // MARK: Phase 3 — confirm it's really you

    private func matchPhase(_ provider: Provider) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(text: "One record found", color: Theme.life)
                Text("Is this you?")
                    .font(NudgeType.serif(25))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)

            OrganicSurface(radius: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    matchRow("Name", value: matchedName)
                    matchRow("Birthday", value: matchedDOB)
                    matchRow("System", value: provider.name)
                    matchRow("Record since", value: "2017")
                }
                .padding(18)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Text("Matched on your name and birthday. If anything looks off, say so — wrong-chart mix-ups are exactly what this step prevents.")
                .font(NudgeType.rounded(12.5))
                .foregroundStyle(Theme.inkMuted)
                .lineSpacing(3)
                .padding(.horizontal, 30)
                .padding(.top, 12)

            Spacer()

            VStack(spacing: 11) {
                Button {
                    Haptics.success()
                    var profile = model.profile
                    if !profile.connectedSystems.contains(provider.name) {
                        profile.connectedSystems.append(provider.name)
                    }
                    model.profile = profile
                    withAnimation(NudgeSpring.gentle) { phase = .discovering }
                    startDiscovering()
                } label: {
                    Text("Yes — that's me")
                        .font(NudgeType.rounded(16, .semibold))
                        .foregroundStyle(Theme.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())

                Button {
                    withAnimation(NudgeSpring.gentle) { phase = .pick }
                } label: {
                    Text("That's not me")
                        .font(NudgeType.rounded(14, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                .buttonStyle(NudgeButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
    }

    private var matchedName: String {
        let first = model.profile.firstName.isEmpty ? model.persona.firstName : model.profile.firstName
        let last = model.profile.lastName.isEmpty ? "W." : model.profile.lastName
        return "\(first) \(last)"
    }

    private var matchedDOB: String {
        model.profile.birthDate?.formatted(.dateTime.month(.wide).day().year()) ?? "On file with provider"
    }

    private func matchRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(NudgeType.rounded(13))
                .foregroundStyle(Theme.inkMuted)
            Spacer()
            Text(value)
                .font(NudgeType.rounded(13.5, .semibold))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: Phase 4 — the companion narrates what it found

    private var discoveringPhase: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Gathering your story…")
                    .font(NudgeType.serif(25))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(narration, id: \.self) { line in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Theme.life)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            Text(line)
                                .font(NudgeType.rounded(14.5))
                                .foregroundStyle(Theme.ink.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
            }
            .scrollIndicators(.hidden)

            Spacer()

            if finished {
                Button(action: onDone) {
                    Text("Beautiful — keep going")
                        .font(NudgeType.rounded(16, .semibold))
                        .foregroundStyle(Theme.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 34)
                .transition(.opacity)
            }
        }
    }

    private func startDiscovering() {
        model.orb.set(.thinking)
        Task {
            for line in discoveries {
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(NudgeSpring.gentle) { narration.append(line) }
                Haptics.tick()
                SoundEngine.shared.tick()
            }
            model.orb.set(.ambient)
            withAnimation(NudgeSpring.gentle) { finished = true }
        }
    }
}

/// Purpose-led permission ask — only the read types we actually use, each one
/// switchable before anything connects. Never the full kitchen sink.
struct HealthKitAskView: View {
    @Environment(AppModel.self) private var model
    var onDone: () -> Void

    @State private var grants: [String: Bool] = [
        "Steps & workouts": true,
        "Sleep": true,
        "Heart rate & blood pressure": true,
        "Blood glucose, if you track it": true,
        "Weight": true,
    ]
    @State private var connecting = false

    private let order = ["Steps & workouts", "Sleep", "Heart rate & blood pressure",
                         "Blood glucose, if you track it", "Weight"]
    private let glyphs = ["Steps & workouts": "figure.walk", "Sleep": "bed.double",
                          "Heart rate & blood pressure": "heart",
                          "Blood glucose, if you track it": "drop", "Weight": "scalemass"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your body already keeps notes.")
                    .font(NudgeType.serif(25))
                    .foregroundStyle(Theme.ink)
                Text("With Apple Health, your cuff, watch and scale chat with me directly — you never type a thing. Untick anything you'd rather keep to yourself:")
                    .font(NudgeType.rounded(14))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            VStack(spacing: 2) {
                ForEach(order, id: \.self) { key in
                    Toggle(isOn: binding(for: key)) {
                        HStack(spacing: 12) {
                            Image(systemName: glyphs[key] ?? "heart")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Theme.life)
                                .frame(width: 32, height: 32)
                                .background(Theme.life.opacity(0.12), in: .circle)
                            Text(key)
                                .font(NudgeType.rounded(14.5, .medium))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .tint(Theme.life)
                    .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)

            Spacer()

            VStack(spacing: 11) {
                Button {
                    connecting = true
                    Haptics.success()
                    var profile = model.profile
                    profile.healthConnected = true
                    model.profile = profile
                    Task {
                        try? await Task.sleep(for: .seconds(1.0))
                        onDone()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if connecting { ProgressView().tint(Theme.base) }
                        Text(connecting ? "Connecting…" : "Connect Apple Health")
                            .font(NudgeType.rounded(16, .semibold))
                    }
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())

                Button(action: onDone) {
                    Text("Not now")
                        .font(NudgeType.rounded(14, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                .buttonStyle(NudgeButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
    }

    private func binding(for key: String) -> Binding<Bool> {
        Binding(get: { grants[key] ?? true }, set: { grants[key] = $0 })
    }
}

/// Epsilon consent — separate, explicit, plain. Decline is one equal-weight
/// tap and is respected everywhere.
struct EpsilonConsentView: View {
    var onChoice: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("One more thing — want me to really get you?")
                    .font(NudgeType.serif(25))
                    .foregroundStyle(Theme.ink)
                Text("Evenings that run late, mornings that run wild, the game you never miss — with your blessing I can use those everyday rhythms to time things kindly. A gentle word after the game ends, never during. It's only ever used *for* you; nothing is sold and nothing here advertises.")
                    .font(NudgeType.rounded(14.5))
                    .foregroundStyle(Theme.ink.opacity(0.82))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Say no and everything still works — I'll just be a little more generic about timing. Change your mind anytime in the Privacy Center.")
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.inkMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Spacer()

            // Equal visual weight — by design, not accident.
            HStack(spacing: 11) {
                consentButton("Yes, tune it to me", consent: true)
                consentButton("No thanks", consent: false)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private func consentButton(_ label: String, consent: Bool) -> some View {
        Button {
            onChoice(consent)
        } label: {
            Text(label)
                .font(NudgeType.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .capsuleGlass()
        }
        .buttonStyle(NudgeButtonStyle())
    }
}
