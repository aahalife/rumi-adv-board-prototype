import SwiftUI

/// Care team and appointments — people, not list rows. Calling or messaging
/// the office is one tap, and visit prep lives right beside the visit.
struct CareTeamView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Care team")
                    .font(NudgeType.serif(28))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)

                VStack(spacing: 11) {
                    ForEach(model.careTeam) { member in
                        OrganicSurface(radius: 26) {
                            HStack(spacing: 13) {
                                Circle()
                                    .fill(Theme.life.opacity(0.16))
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Text(initials(member.name))
                                            .font(NudgeType.rounded(14, .semibold))
                                            .foregroundStyle(Theme.life)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name)
                                        .font(NudgeType.serif(16.5))
                                        .foregroundStyle(Theme.ink)
                                    Text("\(member.role) · \(member.org)")
                                        .font(NudgeType.rounded(12))
                                        .foregroundStyle(Theme.inkMuted)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Button {
                                    Haptics.tick()
                                    model.callOffice()
                                } label: {
                                    Image(systemName: "phone")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundStyle(Theme.life)
                                        .frame(width: 36, height: 36)
                                        .background(Theme.life.opacity(0.12), in: .circle)
                                }
                                .buttonStyle(NudgeButtonStyle())
                                .accessibilityLabel("Call \(member.name)")
                            }
                            .padding(15)
                        }
                    }
                }

                Text("Coming up")
                    .font(NudgeType.serif(20))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 6)

                ForEach(model.appointments) { appointment in
                    OrganicSurface(radius: 28) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(appointment.with)
                                        .font(NudgeType.serif(17))
                                        .foregroundStyle(Theme.ink)
                                    Text("\(appointment.date.formatted(.dateTime.weekday(.wide).month(.wide).day())) · \(appointment.location)")
                                        .font(NudgeType.rounded(12.5))
                                        .foregroundStyle(Theme.inkMuted)
                                }
                                Spacer()
                                Text(daysAway(appointment.date))
                                    .font(NudgeType.number(11, .medium))
                                    .foregroundStyle(Theme.gold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.gold.opacity(0.13), in: .capsule)
                            }
                            if appointment.prepReady {
                                NavigationLink(value: YouDestination.visitPrep) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Your visit prep is ready")
                                            .font(NudgeType.rounded(13.5, .semibold))
                                    }
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 9)
                                    .background(.ultraThinMaterial, in: .capsule)
                                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8))
                                }
                                .buttonStyle(NudgeButtonStyle())
                            }
                        }
                        .padding(17)
                    }
                }

                NavigationLink(value: YouDestination.guide) {
                    OrganicSurface(radius: 28) {
                        HStack(spacing: 13) {
                            Image(systemName: "text.book.closed")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Theme.gold)
                                .frame(width: 38, height: 38)
                                .background(Theme.gold.opacity(0.13), in: .circle)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Discussion guide")
                                    .font(NudgeType.serif(17))
                                    .foregroundStyle(Theme.ink)
                                Text("\(model.guideItems.filter { !$0.resolved }.count) things waiting for the visit")
                                    .font(NudgeType.rounded(12))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .padding(16)
                    }
                }
                .buttonStyle(NudgeButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").filter { $0 != "Dr." }
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters)
    }

    private func daysAway(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        if days <= 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "in \(days) days"
    }
}

/// One-screen brief: what's changed, what to ask, what to bring. The "ask"
/// list IS the discussion guide — one source of truth. Every outbound message
/// requires explicit user approval — hard rule.
struct VisitPrepView: View {
    @Environment(AppModel.self) private var model
    @State private var sent = false
    @State private var confirming = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Visit prep")
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text(visitLine)
                        .font(NudgeType.rounded(13.5))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                prepSection(kicker: "What's changed", color: Theme.sky, items: changedItems)
                prepSection(
                    kicker: "Worth asking — from your guide", color: Theme.warm,
                    items: model.guideItems.filter { $0.kind == .question && !$0.resolved }.map(\.text)
                )
                prepSection(kicker: "Bring", color: Theme.life, items: bringItems)

                if sent {
                    Label("Topics sent ahead — they'll be on the desk before you are.", systemImage: "checkmark")
                        .font(NudgeType.rounded(13.5, .medium))
                        .foregroundStyle(Theme.life)
                } else {
                    Button {
                        confirming = true
                    } label: {
                        Text("Send these topics ahead")
                            .font(NudgeType.rounded(15, .semibold))
                            .foregroundStyle(Theme.base)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.ink, in: .capsule)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .confirmationDialog(
                        "Send these topics to \(model.persona.officeName)? You can edit them first in your discussion guide.",
                        isPresented: $confirming,
                        titleVisibility: .visible
                    ) {
                        Button("Send ahead") {
                            sent = true
                            Haptics.success()
                        }
                        Button("Not now", role: .cancel) {}
                    }
                }

                ProvenanceChip(text: "Built from your records, logs, and our conversations")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var visitLine: String {
        if let next = model.appointments.first {
            return "\(next.with) · \(next.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))"
        }
        return "Your next visit"
    }

    private var changedItems: [String] {
        switch model.pathway {
        case .metabolic:
            return [
                "A1c 8.4 — fifth reading in a row moving down",
                "Steadiest home-BP week in a month (this week)",
                "90 days of steady metformin behind you",
            ]
        case .oncology:
            return [
                "Cycle 3 was the smoothest yet — scheduled anti-nausea worked",
                "Counts recovered on time, third cycle running",
                "Weight holding steady through treatment",
            ]
        case .procedure:
            return [
                "Evening pain down two points on prehab days",
                "9 of 10 prehab days kept",
                "Home recovery setup — 2 of 3 items done",
            ]
        case .cardiometabolic:
            return [
                "Two steady weeks on the scale — fluid in check",
                "A1c 7.1, holding near target",
                "eGFR steady at 66 — kidney protection working",
            ]
        }
    }

    private var bringItems: [String] {
        switch model.pathway {
        case .metabolic:
            return [
                "Home cuff readings (I'll have them charted)",
                "The current med list — including the ibuprofen question",
            ]
        case .oncology:
            return [
                "Your symptom log — nausea and tingling, charted by cycle day",
                "The med list, including anything over-the-counter",
            ]
        case .procedure:
            return [
                "Your full med and supplement list — for the anesthesia team",
                "Insurance card and the surgical packet",
            ]
        case .cardiometabolic:
            return [
                "Your daily-weight and home-BP trends (I'll have them charted)",
                "The full med list — and the kidney-risk question for your team",
            ]
        }
    }

    private func prepSection(kicker: String, color: Color, items: [String]) -> some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 10) {
                Kicker(text: kicker, color: color)
                if items.isEmpty {
                    Text("Nothing waiting here — your guide is clear.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                }
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 9) {
                        Circle()
                            .fill(color.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(NudgeType.rounded(14))
                            .foregroundStyle(Theme.ink.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(17)
        }
    }
}
