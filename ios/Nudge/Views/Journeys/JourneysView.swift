import SwiftUI

/// Where behavior change lives. No streaks, no broken chains, no guilt —
/// progress is a growing light-garden.
struct JourneysView: View {
    @Environment(AppModel.self) private var model
    @State private var sponsorExplain: Program? = nil
    @State private var arcSelection: Int? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Journeys")
                        .font(NudgeType.display(34))
                        .foregroundStyle(Theme.ink)
                    Text("Small things, placed where your life actually is.")
                        .font(NudgeType.rounded(13.5))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 14)

                // Held moments — photographs in glass, the proof of good days.
                VStack(alignment: .leading, spacing: 10) {
                    Kicker(text: "Held moments", color: Theme.rose)
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            ForEach(Array(model.memories.enumerated()), id: \.element.id) { index, memory in
                                MemoryOrbView(memory: memory) {
                                    arcSelection = index
                                }
                            }
                            AddMemoryOrb()
                        }
                        .padding(.vertical, 10)
                    }
                    .scrollIndicators(.hidden)
                    .contentMargins(.horizontal, 2)
                }

                OrganicSurface(radius: 36) {
                    VStack(alignment: .leading, spacing: 8) {
                        LightGardenView(seed: 42, entries: gardenEntries, height: 160)
                            .rippleOnTap(glow: 0.5)
                        Text("Your light garden — every kept habit adds a glow. Tap a light to remember its day. \(totalKept) and growing.")
                            .font(NudgeType.rounded(12.5))
                            .foregroundStyle(Theme.inkMuted)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                    }
                    .padding(.top, 6)
                }

                ForEach(model.journeys) { journey in
                    journeyCard(journey)
                }

                Text("Programs")
                    .font(NudgeType.serif(21))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)
                Text("Structured support, offered only when clinically right for you.")
                    .font(NudgeType.rounded(12.5))
                    .foregroundStyle(Theme.inkMuted)
                    .padding(.top, -10)

                // GOVERNANCE LAW (§3.14, restated at the ranking site): programs are
                // ordered by clinical relevance ONLY. Sponsorship never alters
                // eligibility, ranking among clinically-equivalent options, or the
                // language used. The sponsored experience differs only by the
                // disclosure chip below.
                ForEach(model.programs.filter { !$0.declined }) { program in
                    programCard(program)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $sponsorExplain) { program in
            SponsorExplainSheet(program: program)
                .presentationDetents([.medium])
                .presentationBackground(Theme.base)
        }
        .fullScreenCover(item: Binding(
            get: { arcSelection.map { ArcSelection(index: $0) } },
            set: { arcSelection = $0?.index }
        )) { selection in
            MemoryArcViewer(memories: model.memories, selection: selection.index)
        }
    }

    private struct ArcSelection: Identifiable {
        let index: Int
        var id: Int { index }
    }

    private var totalKept: Int {
        model.journeys.reduce(0) { $0 + $1.keptCount }
    }

    /// Every kept habit, newest first — the garden's memory.
    private var gardenEntries: [GardenEntry] {
        model.journeys
            .flatMap { journey in
                journey.habits.flatMap { habit in
                    habit.keptDates.map { GardenEntry(title: habit.title, date: $0) }
                }
            }
            .sorted { $0.date > $1.date }
    }

    private func journeyCard(_ journey: Journey) -> some View {
        OrganicSurface(radius: 32) {
            VStack(alignment: .leading, spacing: 11) {
                Text(journey.title)
                    .font(NudgeType.serif(19))
                    .foregroundStyle(Theme.ink)
                Text(journey.why)
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(journey.habits) { habit in
                    habitRow(journey: journey, habit: habit)
                }
            }
            .padding(18)
        }
    }

    private func habitRow(journey: Journey, habit: AtomicHabit) -> some View {
        let keptToday = model.keptToday(journeyID: journey.id, habitID: habit.id)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(NudgeType.rounded(14.5, .medium))
                    .foregroundStyle(Theme.ink)
                Text(habit.contextLine)
                    .font(NudgeType.rounded(12))
                    .foregroundStyle(Theme.inkMuted)
            }
            Spacer()
            Button {
                if !keptToday {
                    model.keepHabit(journeyID: journey.id, habitID: habit.id)
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(keptToday ? Theme.gold : Theme.inkMuted.opacity(0.4), lineWidth: 1.4)
                        .frame(width: 40, height: 40)
                    if keptToday {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Theme.gold.opacity(0.85), Theme.gold.opacity(0.1)],
                                    center: .center, startRadius: 0, endRadius: 17
                                )
                            )
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(NudgeButtonStyle())
            .animation(NudgeSpring.delight, value: keptToday)
            .accessibilityLabel(keptToday ? "Kept today" : "Mark kept")
        }
        .padding(.vertical, 4)
    }

    private func programCard(_ program: Program) -> some View {
        OrganicSurface(radius: 32) {
            VStack(alignment: .leading, spacing: 11) {
                Text(program.title)
                    .font(NudgeType.serif(19))
                    .foregroundStyle(Theme.ink)
                Text(program.summary)
                    .font(NudgeType.rounded(13.5))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                // Presentation grammar: clinical why → personal fit → action → disclosure.
                VStack(alignment: .leading, spacing: 7) {
                    grammarLine(glyph: "checkmark.seal", text: program.clinicalWhy, color: Theme.sky)
                    grammarLine(glyph: "person", text: program.personalFit, color: Theme.life)
                    if let dividend = program.patientDividend {
                        grammarLine(glyph: "arrow.down.circle", text: dividend, color: Theme.gold)
                    }
                }

                if program.enrolled {
                    Label("You're in — the first step is on Today", systemImage: "checkmark")
                        .font(NudgeType.rounded(13.5, .medium))
                        .foregroundStyle(Theme.life)
                } else {
                    HStack(spacing: 10) {
                        Button {
                            withAnimation(NudgeSpring.ui) { model.enroll(program.id) }
                        } label: {
                            Text("Count me in")
                                .font(NudgeType.rounded(13.5, .semibold))
                                .foregroundStyle(Theme.base)
                                .padding(.horizontal, 17)
                                .padding(.vertical, 9)
                                .background(Theme.ink, in: .capsule)
                        }
                        .buttonStyle(NudgeButtonStyle())

                        // Decline is one equal-weight tap, remembered.
                        Button {
                            withAnimation(NudgeSpring.ui) { model.decline(program.id) }
                        } label: {
                            Text("Not for me")
                                .font(NudgeType.rounded(13.5, .semibold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 17)
                                .padding(.vertical, 9)
                                .background(.ultraThinMaterial, in: .capsule)
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8))
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }

                HStack {
                    ProvenanceChip(text: program.provenance)
                    if let sponsor = program.sponsor {
                        SponsorChip(sponsor: sponsor) {
                            sponsorExplain = program
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func grammarLine(glyph: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: glyph)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
                .padding(.top, 2)
            Text(text)
                .font(NudgeType.rounded(12.5))
                .foregroundStyle(Theme.ink.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Plain-language sponsorship explanation — exactly what the sponsor funds
/// and what they receive.
private struct SponsorExplainSheet: View {
    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule().fill(Theme.inkMuted.opacity(0.3)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Kicker(text: "About this sponsorship", color: Theme.gold)
            Text(program.sponsor ?? "")
                .font(NudgeType.serif(23))
                .foregroundStyle(Theme.ink)
            Text(program.sponsorDetail ?? "")
                .font(NudgeType.rounded(15))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
