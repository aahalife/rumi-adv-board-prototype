import SwiftUI

/// Life — meals, moves and meds as a floating magazine gallery. Every entry
/// is a lifted studio object sitting directly on the living canvas (no boxes),
/// grouped by day with honest little totals. Tap an object and it glides into
/// its own room — blurred scene, big numbers, soft macro bars.
struct LifeCatalogView: View {
    @Environment(AppModel.self) private var model

    @State private var filter: CareEntry.Kind? = nil
    @State private var showAdd = false
    @State private var addKind: CareEntry.Kind = .meal
    @State private var selected: CareEntry? = nil
    @Namespace private var hero

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    filterRow

                    ForEach(groupedByDay, id: \.day) { group in
                        daySection(group)
                    }

                    if filtered.isEmpty { emptyState }
                    Color.clear.frame(height: 150)
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
            }

            if let entry = selected {
                LifeEntryDetailView(entry: entry, hero: hero) {
                    withAnimation(NudgeSpring.gentle) { selected = nil }
                }
                .zIndex(10)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEntrySheet(kind: $addKind)
                .presentationDetents([.medium, .large])
                .presentationBackground(Theme.base)
                .presentationContentInteraction(.scrolls)
        }
    }

    // MARK: Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Life")
                .font(NudgeType.display(38))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let todayFacts = dayTotal(for: .now), todayFacts > 0 {
                (Text("\(todayFacts) ").font(NudgeType.number(22, .semibold))
                 + Text("cal today").font(NudgeType.rounded(12, .medium)))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    private var filterRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterChip(nil, label: "Everything")
                ForEach(CareEntry.Kind.allCases) { kind in
                    filterChip(kind, label: kind.displayName)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func filterChip(_ kind: CareEntry.Kind?, label: String) -> some View {
        let active = filter == kind
        return Button {
            Haptics.tick()
            SoundEngine.shared.tick()
            withAnimation(NudgeSpring.ui) { filter = kind }
        } label: {
            HStack(spacing: 5) {
                if let kind {
                    Image(systemName: kind.glyph)
                        .font(.system(size: 10, weight: .medium))
                }
                Text(label)
                    .font(NudgeType.rounded(12.5, active ? .semibold : .medium))
            }
            .foregroundStyle(active ? Theme.ink : Theme.inkMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .capsuleGlass(tint: active ? Theme.warm : nil)
        }
        .buttonStyle(NudgeButtonStyle())
    }

    // MARK: Day sections — the spread

    private func daySection(_ group: (day: Date, items: [CareEntry])) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Kicker(text: group.day.formatted(.dateTime.month(.wide).day()), color: Theme.inkMuted.opacity(0.8))
                    Text(dayLabel(group.day))
                        .font(NudgeType.display(30))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                if let total = dayTotal(for: group.day), total > 0 {
                    (Text("\(total)").font(NudgeType.number(19, .semibold)).foregroundStyle(Theme.ink)
                     + Text(" cal").font(NudgeType.rounded(11.5, .medium)).foregroundStyle(Theme.inkMuted))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)

            // Touch ripple lives on the collage only — no glass beneath it,
            // so the shader can bend light without tripping iOS 26 placeholders.
            collage(group.items, daySeed: Calendar.current.ordinality(of: .day, in: .era, for: group.day) ?? 0)
                .rippleOnTap(glow: 0.5)
                .padding(.top, 4)
        }
    }

    /// Alternating organic rows — one generous object beside one smaller,
    /// sides swapping row to row, like a set table photographed from above.
    private func collage(_ items: [CareEntry], daySeed: Int) -> some View {
        let rows = stride(from: 0, to: items.count, by: 2).map { index in
            Array(items[index..<min(index + 2, items.count)])
        }
        return VStack(spacing: 4) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                let bigLeft = (rowIndex + daySeed) % 2 == 0
                HStack(alignment: .top, spacing: 0) {
                    if row.count == 1 {
                        Spacer(minLength: 40)
                        floatingItem(row[0], size: 196)
                        Spacer(minLength: 40)
                    } else if bigLeft {
                        floatingItem(row[0], size: 196)
                            .padding(.leading, 16)
                        Spacer(minLength: 8)
                        floatingItem(row[1], size: 128)
                            .padding(.top, 44)
                            .padding(.trailing, 22)
                    } else {
                        floatingItem(row[0], size: 128)
                            .padding(.top, 44)
                            .padding(.leading, 22)
                        Spacer(minLength: 8)
                        floatingItem(row[1], size: 196)
                            .padding(.trailing, 16)
                    }
                }
            }
        }
    }

    private func floatingItem(_ entry: CareEntry, size: CGFloat) -> some View {
        Button {
            Haptics.glass()
            SoundEngine.shared.glass()
            withAnimation(NudgeSpring.gentle) { selected = entry }
        } label: {
            VStack(spacing: 7) {
                LiftedImage(name: entry.imageName)
                    .frame(width: size, height: size)
                    .matchedGeometryEffect(id: entry.id, in: hero)

                VStack(spacing: 1) {
                    Text(entry.title)
                        .font(NudgeType.serif(size > 150 ? 16 : 13.5))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(subtitle(for: entry))
                        .font(NudgeType.rounded(size > 150 ? 11.5 : 10.5, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel("\(entry.title), \(subtitle(for: entry))")
    }

    private func subtitle(for entry: CareEntry) -> String {
        if let facts = entry.facts {
            if facts.calories > 0 { return "\(facts.calories) cal · \(entry.at.formatted(date: .omitted, time: .shortened))" }
            if facts.minutes > 0 { return "\(facts.minutes) min · \(entry.at.formatted(date: .omitted, time: .shortened))" }
        }
        return "\(entry.detail) · \(entry.at.formatted(date: .omitted, time: .shortened))"
    }

    // MARK: Data shaping

    private var filtered: [CareEntry] {
        guard let filter else { return model.entries }
        return model.entries.filter { $0.kind == filter }
    }

    private var groupedByDay: [(day: Date, items: [CareEntry])] {
        let groups = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.at) }
        return groups.keys.sorted(by: >).map { (day: $0, items: (groups[$0] ?? []).sorted { $0.at > $1.at }) }
    }

    private func dayTotal(for day: Date) -> Int? {
        let cal = Calendar.current
        let total = model.entries
            .filter { cal.isDate($0.at, inSameDayAs: day) && $0.kind == .meal }
            .compactMap { $0.facts?.calories }
            .reduce(0, +)
        return total
    }

    private func dayLabel(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            LiftedImage(name: "grain_bowl_chicken_quinoa")
                .frame(width: 150, height: 150)
                .opacity(0.85)
            Text("Nothing on the table yet — tell me a meal, an activity, or a med and watch it appear.")
                .font(NudgeType.rounded(13.5))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 44)
        .padding(.top, 40)
    }

    private var addButton: some View {
        Menu {
            ForEach(CareEntry.Kind.allCases) { kind in
                Button {
                    addKind = kind
                    showAdd = true
                } label: {
                    Label(kind.displayName, systemImage: kind.glyph)
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Theme.ink)
                .frame(width: 56, height: 56)
                .modifier(CircularGlass())
                .contentShape(Circle().inset(by: -8))
        }
        .accessibilityLabel("Add to your life log")
        .padding(.trailing, 22)
        .padding(.bottom, 96)
    }
}

// MARK: - Detail — the entry's own room

/// One lifted object in its own atmosphere: a blurred scene for its kind,
/// the big honest number, macro bars that breathe in, and warm exits.
/// Drag down anywhere to float back to the table.
struct LifeEntryDetailView: View {
    @Environment(AppModel.self) private var model
    let entry: CareEntry
    var hero: Namespace.ID
    var onClose: () -> Void

    @State private var appeared = false
    @State private var dragY: CGFloat = 0

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                HStack {
                    ChromeIcon(systemName: "chevron.down", accessibilityText: "Back to the table") {
                        onClose()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer(minLength: 8)

                VStack(spacing: 3) {
                    Text(entry.title)
                        .font(NudgeType.display(30))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                    Text(entry.facts?.portion.isEmpty == false ? entry.facts?.portion ?? entry.detail : entry.detail)
                        .font(NudgeType.rounded(13, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                LiftedImage(name: entry.imageName, shadowOpacity: 0.4)
                    .frame(width: 290, height: 290)
                    .matchedGeometryEffect(id: entry.id, in: hero)
                    .padding(.top, 6)

                bigNumber
                    .padding(.top, 12)

                if let facts = entry.facts, facts.calories > 0 {
                    macroBars(facts)
                        .padding(.horizontal, 40)
                        .padding(.top, 18)
                } else if entry.kind == .med, let med = linkedMed {
                    medFacts(med)
                        .padding(.horizontal, 32)
                        .padding(.top, 14)
                }

                Spacer(minLength: 12)

                actions
                    .padding(.horizontal, 28)
                    .padding(.bottom, 34)
            }
        }
        .offset(y: max(dragY, 0))
        .opacity(1 - Double(max(dragY, 0)) / 700)
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard value.translation.height > 0 else { return }
                    dragY = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 130 {
                        Haptics.glass()
                        onClose()
                    } else {
                        withAnimation(NudgeSpring.ui) { dragY = 0 }
                    }
                }
        )
        .onAppear {
            withAnimation(NudgeSpring.gentle.delay(0.12)) { appeared = true }
        }
    }

    /// The room — a soft scene per kind, deeply blurred, tinted to ground.
    private var background: some View {
        ZStack {
            Image(sceneName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 26)
                .overlay(Theme.base.opacity(0.42))
            ProgressiveBlur(edge: .bottom, height: 240, tint: Theme.base)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
        .onTapGesture { onClose() }
    }

    private var sceneName: String {
        switch entry.kind {
        case .meal: return "cozy_dinner_table"
        case .move: return "tree_path_sunset_walk"
        case .med: return "soft_editorial_studio"
        }
    }

    @ViewBuilder
    private var bigNumber: some View {
        if let facts = entry.facts, facts.calories > 0 {
            VStack(spacing: 3) {
                (Text("\(facts.calories)").font(NudgeType.number(52, .bold)).foregroundStyle(Theme.ink)
                 + Text(" cal").font(NudgeType.rounded(15, .medium)).foregroundStyle(Theme.inkMuted))
                Text("\(Int((Double(facts.calories) / 2000.0) * 100))% OF THE DAY · \(entry.at.formatted(date: .omitted, time: .shortened))")
                    .font(NudgeType.kicker())
                    .tracking(1.4)
                    .foregroundStyle(Theme.inkMuted)
            }
            .opacity(appeared ? 1 : 0)
        } else if let facts = entry.facts, facts.minutes > 0 {
            VStack(spacing: 3) {
                (Text("\(facts.minutes)").font(NudgeType.number(52, .bold)).foregroundStyle(Theme.ink)
                 + Text(" min").font(NudgeType.rounded(15, .medium)).foregroundStyle(Theme.inkMuted))
                Text("FELT GOOD TO BE ACTIVE · \(entry.at.formatted(date: .omitted, time: .shortened))")
                    .font(NudgeType.kicker())
                    .tracking(1.4)
                    .foregroundStyle(Theme.inkMuted)
            }
            .opacity(appeared ? 1 : 0)
        } else {
            Text(entry.at.formatted(.dateTime.weekday(.wide).hour().minute()))
                .font(NudgeType.rounded(13, .medium))
                .foregroundStyle(Theme.inkMuted)
                .opacity(appeared ? 1 : 0)
        }
    }

    private func macroBars(_ facts: LifeFacts) -> some View {
        VStack(spacing: 11) {
            macroBar(label: "PROTEIN", grams: facts.protein, max: 50, color: Theme.life)
            macroBar(label: "CARBS", grams: facts.carbs, max: 70, color: Theme.gold)
            macroBar(label: "FAT", grams: facts.fat, max: 35, color: Theme.rose)
        }
    }

    private func macroBar(label: String, grams: Int, max maxGrams: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(NudgeType.kicker())
                .tracking(1.2)
                .foregroundStyle(Theme.inkMuted)
                .frame(width: 64, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.ink.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.85), color.opacity(0.55)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: appeared ? geo.size.width * min(Double(grams) / maxGrams, 1) : 0)
                        .animation(NudgeSpring.gentle.delay(0.25), value: appeared)
                }
            }
            .frame(height: 7)

            Text("\(grams)g")
                .font(NudgeType.number(13, .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func medFacts(_ med: Medication) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(med.purposeLine)
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.ink.opacity(0.85))
            Text("\(med.dose) · \(med.scheduleLine)")
                .font(NudgeType.rounded(12.5, .medium))
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Theme.surface.opacity(0.8), in: .rect(cornerRadius: 22, style: .continuous))
        .opacity(appeared ? 1 : 0)
    }

    private var linkedMed: Medication? {
        guard let medID = entry.linkedMedID else { return nil }
        return model.medications.first { $0.id == medID }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if entry.kind == .med, let medID = entry.linkedMedID {
                Button {
                    onClose()
                    model.quickLogMedID = medID
                    model.showQuickLog = true
                } label: {
                    Label("Log how you felt alongside this dose", systemImage: "waveform.path.ecg")
                        .font(NudgeType.rounded(13.5, .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .capsuleGlass(tint: Theme.sky)
                }
                .buttonStyle(NudgeButtonStyle())
            }

            Button {
                onClose()
                model.openConversation(seed: "I logged \(entry.title.lowercased()) — anything worth noticing?")
            } label: {
                Label("Ask Rumi about it", systemImage: "bubble")
                    .font(NudgeType.rounded(13.5, .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .capsuleGlass(tint: Theme.rose)
            }
            .buttonStyle(NudgeButtonStyle())

            Button(role: .destructive) {
                let id = entry.id
                onClose()
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    model.removeEntry(id)
                }
            } label: {
                Text("Remove from the log")
                    .font(NudgeType.rounded(13, .medium))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NudgeButtonStyle())
        }
        .opacity(appeared ? 1 : 0)
    }
}

// MARK: - Add sheet

/// Logging should feel like telling a friend, not filing a report. Type what
/// it was — the studio object finds itself while you watch.
struct AddEntrySheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Binding var kind: CareEntry.Kind

    @State private var text = ""
    @State private var note = ""
    @State private var selectedMedID: String? = nil
    @FocusState private var focused: Bool

    private var preview: LifeLibrary.Match {
        switch kind {
        case .meal: return LifeLibrary.matchMeal(text)
        case .move: return LifeLibrary.matchMove(text)
        case .med:
            let med = model.medications.first { $0.id == selectedMedID } ?? model.medications.first
            return LifeLibrary.Match(imageName: LifeLibrary.medImage(for: med?.id ?? ""),
                                     suggestedTitle: med?.name ?? "Medication")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Capsule().fill(Theme.inkMuted.opacity(0.3)).frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                HStack(spacing: 8) {
                    ForEach(CareEntry.Kind.allCases) { item in
                        let active = kind == item
                        Button {
                            Haptics.tick()
                            withAnimation(NudgeSpring.ui) { kind = item }
                        } label: {
                            Label(item.displayName, systemImage: item.glyph)
                                .font(NudgeType.rounded(13, active ? .semibold : .medium))
                                .foregroundStyle(active ? Theme.ink : Theme.inkMuted)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 9)
                                .capsuleGlass(tint: active ? Theme.warm : nil)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }

                Text(kind.addPrompt)
                    .font(NudgeType.serif(24))
                    .foregroundStyle(Theme.ink)

                // The live studio preview — the delight moment.
                HStack(spacing: 16) {
                    LiftedImage(name: preview.imageName)
                        .frame(width: 124, height: 124)
                        .id(preview.imageName)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                        .animation(NudgeSpring.delight, value: preview.imageName)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(preview.suggestedTitle.capitalizedFirst)
                            .font(NudgeType.serif(17))
                            .foregroundStyle(Theme.ink)
                        if let facts = LifeLibrary.facts(for: preview.imageName), facts.calories > 0 {
                            Text("about \(facts.calories) cal")
                                .font(NudgeType.number(12, .medium))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        Text("I'll keep the picture — you keep the moment.")
                            .font(NudgeType.rounded(12))
                            .foregroundStyle(Theme.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                if kind == .med {
                    VStack(spacing: 8) {
                        ForEach(model.medications) { med in
                            let active = (selectedMedID ?? model.medications.first?.id) == med.id
                            Button {
                                Haptics.tick()
                                withAnimation(NudgeSpring.ui) { selectedMedID = med.id }
                            } label: {
                                HStack {
                                    Text(med.name)
                                        .font(NudgeType.rounded(14.5, active ? .semibold : .medium))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Text(med.dose)
                                        .font(NudgeType.rounded(12))
                                        .foregroundStyle(Theme.inkMuted)
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
                    LifeLibraryPicker(kind: kind, query: $text, selectedName: text) { item in
                        withAnimation(NudgeSpring.ui) { text = item.name }
                    }
                }

                Button {
                    model.addEntry(kind: kind, text: text, note: note.isEmpty ? nil : note,
                                   linkedMedID: kind == .med ? (selectedMedID ?? model.medications.first?.id) : nil)
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
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(LivingGradientView())
        .onAppear { focused = kind != .med }
    }
}
