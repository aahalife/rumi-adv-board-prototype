import SwiftUI

/// Quick Log — what → where (when it matters) → how much → context → and then
/// the part that counts: the companion shows up. Support, tips that fit your
/// condition, and paths that go somewhere — the guide, the office, a call.
struct QuickLogView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    /// Pre-linked medication when logging from a med surface.
    var linkedMedID: String? = nil

    enum Step {
        case choose, what, place, severity, context, support, quickAdd
    }

    @State private var step: Step = .choose
    @State private var quickKind: CareEntry.Kind = .meal
    @State private var quickText = ""
    @State private var quickMedID: String? = nil
    @State private var quickKept = false
    @State private var kind: SymptomKind? = nil
    @State private var region: BodyRegion? = nil
    @State private var severity: Double = 0.4
    @State private var note = ""
    @State private var plan: SupportPlan? = nil
    @State private var addedToGuide = false
    @State private var messageSent = false
    @State private var confirmingMessage = false
    @State private var logged = false

    private let columns = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]

    var body: some View {
        ZStack {
            LivingGradientView()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Capsule().fill(Theme.inkMuted.opacity(0.3)).frame(width: 36, height: 4)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 12)
                .padding(.bottom, 14)

                if let med = linkedMed {
                    HStack(spacing: 6) {
                        Image(systemName: "pills")
                            .font(.system(size: 10, weight: .medium))
                        Text("Logging alongside \(med.name)")
                            .font(NudgeType.rounded(11.5, .medium))
                    }
                    .foregroundStyle(Theme.inkMuted)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: .capsule)
                    .padding(.bottom, 10)
                }

                ScrollView {
                    Group {
                        switch step {
                        case .choose: chooseStep.transition(stepTransition)
                        case .what: whatStep.transition(stepTransition)
                        case .place: placeStep.transition(stepTransition)
                        case .severity: severityStep.transition(stepTransition)
                        case .context: contextStep.transition(stepTransition)
                        case .support: supportStep.transition(stepTransition)
                        case .quickAdd: quickAddStep.transition(stepTransition)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 24)
            .animation(NudgeSpring.ui, value: step)
        }
        .sensoryFeedback(.success, trigger: logged)
        .onAppear {
            // Logging from a med surface goes straight to the symptom flow.
            if linkedMedID != nil { step = .what }
        }
    }

    // MARK: Step — what kind of moment is this?

    private var chooseStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What are we keeping?")
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)
            Text("A feeling gets the full conversation. Everything else takes ten seconds.")
                .font(NudgeType.rounded(13.5))
                .foregroundStyle(Theme.inkMuted)

            VStack(spacing: 11) {
                chooseRow(imageName: model.persona.heroImage, title: "How I'm feeling",
                          detail: "A symptom, a worry — I'll meet you there", accent: Theme.warm) {
                    step = .what
                }
                chooseRow(imageName: "grain_bowl_chicken_quinoa", title: "A meal",
                          detail: "Tell me what you ate — I'll make it beautiful", accent: Theme.life) {
                    quickKind = .meal
                    step = .quickAdd
                }
                chooseRow(imageName: "yoga_mat_rolled", title: "Activity",
                          detail: "A walk, yoga, gardening — any active moment", accent: Theme.sky) {
                    quickKind = .move
                    step = .quickAdd
                }
                chooseRow(imageName: "medicine_bottle_pills", title: "A med, taken",
                          detail: "One tap — it lands next to your day", accent: Theme.gold) {
                    quickKind = .med
                    quickMedID = model.medications.first?.id
                    step = .quickAdd
                }
            }
        }
    }

    private func chooseRow(imageName: String, title: String, detail: String,
                           accent: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tick()
            SoundEngine.shared.tick()
            withAnimation(NudgeSpring.ui) { action() }
        } label: {
            HStack(spacing: 13) {
                Color(.secondarySystemBackground)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(accent.opacity(0.28), lineWidth: 0.9)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NudgeType.serif(17))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
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
                    .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
            )
        }
        .buttonStyle(NudgeButtonStyle())
    }

    // MARK: Step — the ten-second log (meal · activity · med)

    private var quickPreview: LifeLibrary.Match {
        switch quickKind {
        case .meal: return LifeLibrary.matchMeal(quickText)
        case .move: return LifeLibrary.matchMove(quickText)
        case .med:
            let med = model.medications.first { $0.id == quickMedID }
            return LifeLibrary.Match(imageName: LifeLibrary.medImage(for: med?.id ?? ""),
                                     suggestedTitle: med?.name ?? "Medication")
        }
    }

    private var quickAddStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(quickKind.addPrompt)
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)

            HStack(spacing: 16) {
                Color(.secondarySystemBackground)
                    .frame(width: 104, height: 104)
                    .overlay {
                        Image(quickPreview.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 24))
                    .shadow(color: Theme.shadow.opacity(0.18), radius: 12, y: 5)
                    .id(quickPreview.imageName)
                    .animation(NudgeSpring.delight, value: quickPreview.imageName)

                Text(quickPreview.suggestedTitle.capitalizedFirst)
                    .font(NudgeType.serif(18))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            if quickKind == .med {
                VStack(spacing: 8) {
                    ForEach(model.medications) { med in
                        let active = quickMedID == med.id
                        Button {
                            Haptics.tick()
                            withAnimation(NudgeSpring.ui) { quickMedID = med.id }
                        } label: {
                            HStack {
                                Text(med.name)
                                    .font(NudgeType.rounded(14.5, active ? .semibold : .medium))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                if active {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.life)
                                }
                            }
                            .padding(13)
                            .background(Theme.surface.opacity(active ? 1 : 0.85), in: .rect(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(active ? Theme.life.opacity(0.4) : Theme.edge.opacity(0.5), lineWidth: 0.9)
                            )
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }
            } else {
                LifeLibraryPicker(kind: quickKind, query: $quickText, selectedName: quickText) { item in
                    withAnimation(NudgeSpring.ui) { quickText = item.name }
                }
            }

            Button {
                quickKept = true
                model.addEntry(kind: quickKind, text: quickText,
                               linkedMedID: quickKind == .med ? quickMedID : nil)
                model.quickLogAck = quickKind == .med
                    ? "Logged — and I'll watch how the day sits with it."
                    : "Kept. It's on your table in Life."
                dismiss()
            } label: {
                Text("Keep it")
                    .font(NudgeType.rounded(15, .semibold))
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.ink, in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())
            .padding(.top, 6)

            Button {
                withAnimation(NudgeSpring.ui) { step = .choose }
            } label: {
                Text("Back")
                    .font(NudgeType.rounded(14, .medium))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NudgeButtonStyle())
        }
        .sensoryFeedback(.success, trigger: quickKept)
    }

    private var linkedMed: Medication? {
        guard let linkedMedID else { return nil }
        return model.medications.first { $0.id == linkedMedID }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: Step — what (adapted to the condition)

    private var whatStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's going on?")
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)

            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(model.persona.symptomKinds) { item in
                    Button {
                        Haptics.tick()
                        kind = item
                        step = item.needsBodyMap ? .place : .severity
                    } label: {
                        VStack(spacing: 9) {
                            Color(.secondarySystemBackground)
                                .frame(height: 72)
                                .overlay {
                                    Image(symptomImageName(for: item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .allowsHitTesting(false)
                                }
                                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                            Text(item.name)
                                .font(NudgeType.rounded(13.5, .medium))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(9)
                        .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
                        )
                    }
                    .buttonStyle(NudgeButtonStyle())
                }
            }
        }
    }

    private func symptomImageName(for item: SymptomKind) -> String {
        LifeLibrary.feelingImage(for: item.name)
    }

    // MARK: Step — where on the body

    private var placeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(kind?.name ?? "")
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)
            Text("Show me where — it sharpens the pattern.")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)

            BodyMapView(selection: $region)
                .frame(maxWidth: .infinity)

            Button {
                step = .severity
            } label: {
                Text(region == nil ? "Skip — it's everywhere" : "Next")
                    .font(NudgeType.rounded(15, .semibold))
                    .foregroundStyle(region == nil ? Theme.ink : Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(region == nil ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Theme.ink), in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())
        }
    }

    // MARK: Step — how much

    private var severityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(kind?.name ?? "")
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)
            Text("How much is it making itself known?")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)

            FluidSeveritySlider(value: $severity)
                .padding(.top, 10)

            Button {
                step = .context
            } label: {
                Text("Next")
                    .font(NudgeType.rounded(15, .semibold))
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.ink, in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())
            .padding(.top, 18)
        }
    }

    // MARK: Step — context

    private var contextStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Anything I should know?")
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)
            Text("Optional — a word of context makes patterns sharper.")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)

            TextField("e.g. started after lunch…", text: $note, axis: .vertical)
                .font(NudgeType.rounded(15))
                .lineLimit(2...4)
                .padding(16)
                .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
                )

            Button {
                logged = true
                Haptics.success()
                SoundEngine.shared.send()
                plan = model.addLog(
                    kind: kind?.name ?? "Something",
                    severity: severity,
                    note: note,
                    bodyRegion: region?.rawValue,
                    linkedMedID: linkedMedID
                )
                step = .support
            } label: {
                Text("Log it")
                    .font(NudgeType.rounded(15, .semibold))
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.ink, in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())
            .padding(.top, 10)
        }
    }

    // MARK: Step — the companion shows up

    @ViewBuilder
    private var supportStep: some View {
        if let plan {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    OrbView(size: 44, state: model.orb)
                    Text(plan.message)
                        .font(NudgeType.rounded(15.5))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: Theme.warm.opacity(0.15), radius: 12)
                }

                if plan.urgent {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("This one's worth a call to \(model.persona.officeName) today.")
                            .font(NudgeType.rounded(13, .semibold))
                    }
                    .foregroundStyle(Theme.attention)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.attention.opacity(0.12), in: .rect(cornerRadius: 20, style: .continuous))
                }

                OrganicSurface(radius: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Kicker(text: "While we watch it", color: Theme.life)
                        ForEach(plan.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 9) {
                                Circle()
                                    .fill(Theme.life.opacity(0.6))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                Text(tip)
                                    .font(NudgeType.rounded(13.5))
                                    .foregroundStyle(Theme.ink.opacity(0.88))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(16)
                }

                VStack(spacing: 10) {
                    supportAction(
                        glyph: addedToGuide ? "checkmark" : "text.badge.plus",
                        title: addedToGuide ? "In your discussion guide" : "Add to my questions for the visit",
                        detail: addedToGuide ? "It'll be there when you sit down with them" : plan.guideQuestion,
                        accent: Theme.gold,
                        done: addedToGuide
                    ) {
                        model.addGuideItem(kind: .question, text: plan.guideQuestion,
                                           from: "From your \(kind?.name.lowercased() ?? "symptom") log · \(Date.now.formatted(.dateTime.month(.abbreviated).day()))")
                        withAnimation(NudgeSpring.ui) { addedToGuide = true }
                    }

                    supportAction(
                        glyph: messageSent ? "checkmark" : "paperplane",
                        title: messageSent ? "Note sent to \(model.persona.officeName)" : "Send a note to \(model.persona.officeName)",
                        detail: messageSent ? "They'll see it before your next visit" : "I've drafted it — you approve before anything goes",
                        accent: Theme.sky,
                        done: messageSent
                    ) {
                        confirmingMessage = true
                    }
                    .confirmationDialog(
                        plan.draftMessage,
                        isPresented: $confirmingMessage,
                        titleVisibility: .visible
                    ) {
                        Button("Send it") {
                            withAnimation(NudgeSpring.ui) { messageSent = true }
                            Haptics.success()
                        }
                        Button("Not now", role: .cancel) {}
                    }

                    supportAction(
                        glyph: "phone",
                        title: "Call \(model.persona.officeName)",
                        detail: model.persona.officePhone,
                        accent: plan.urgent ? Theme.attention : Theme.warm,
                        done: false
                    ) {
                        model.callOffice()
                    }

                    supportAction(
                        glyph: "bubble",
                        title: "Talk it through with me",
                        detail: "I'll hold it against your meds, readings, and the week",
                        accent: Theme.rose,
                        done: false
                    ) {
                        dismiss()
                        Task {
                            try? await Task.sleep(for: .milliseconds(350))
                            model.openConversation(seed: "symptom:\(kind?.name.lowercased() ?? "this")")
                        }
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Text("That's all for now")
                        .font(NudgeType.rounded(14, .medium))
                        .foregroundStyle(Theme.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(NudgeButtonStyle())
            }
            .onAppear {
                model.orb.set(.speaking)
                Task {
                    try? await Task.sleep(for: .seconds(1.4))
                    model.orb.set(.ambient)
                }
            }
        }
    }

    private func supportAction(glyph: String, title: String, detail: String,
                               accent: Color, done: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: glyph)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(done ? Theme.life : accent)
                    .frame(width: 38, height: 38)
                    .background((done ? Theme.life : accent).opacity(0.13), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NudgeType.rounded(14.5, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(NudgeType.rounded(12))
                        .foregroundStyle(Theme.inkMuted)
                        .lineLimit(2)
                }
                Spacer()
                if !done {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Theme.inkMuted)
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.edge.opacity(0.55), lineWidth: 0.9)
            )
        }
        .buttonStyle(NudgeButtonStyle())
        .disabled(done)
    }
}

/// A fluid slider that morphs color temperature — sage through gold to warm.
struct FluidSeveritySlider: View {
    @Binding var value: Double
    @State private var quantized = 0

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surface.opacity(0.9))
                        .overlay(Capsule().strokeBorder(Theme.edge.opacity(0.5), lineWidth: 0.8))

                    LinearGradient(
                        colors: [Theme.life, Theme.gold, Theme.attention],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(Capsule())
                    .mask(alignment: .leading) {
                        Capsule().frame(width: max(58, value * width))
                    }

                    Circle()
                        .fill(.white)
                        .frame(width: 42, height: 42)
                        .shadow(color: currentColor.opacity(0.65), radius: 13)
                        .overlay(Circle().strokeBorder(currentColor.opacity(0.5), lineWidth: 1.5))
                        .offset(x: min(max(value * width - 21, 8), width - 50))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            value = min(max(drag.location.x / width, 0), 1)
                            quantized = Int(value * 4)
                        }
                )
            }
            .frame(height: 58)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: quantized)

            HStack {
                Text("Barely there")
                Spacer()
                Text(label)
                    .font(NudgeType.rounded(13, .semibold))
                    .foregroundStyle(currentColor)
                Spacer()
                Text("A lot")
            }
            .font(NudgeType.rounded(12))
            .foregroundStyle(Theme.inkMuted)
        }
        .accessibilityElement()
        .accessibilityLabel("Severity")
        .accessibilityValue(label)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 0.1, 1)
            case .decrement: value = max(value - 0.1, 0)
            @unknown default: break
            }
        }
    }

    private var currentColor: Color {
        if value < 0.35 { return Theme.life }
        if value < 0.7 { return Theme.gold }
        return Theme.attention
    }

    private var label: String {
        if value < 0.25 { return "barely there" }
        if value < 0.5 { return "noticeable" }
        if value < 0.75 { return "hard to ignore" }
        return "a lot"
    }
}
