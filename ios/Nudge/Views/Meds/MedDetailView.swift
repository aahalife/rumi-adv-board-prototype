import SwiftUI

/// Full med depth: dose history, watchlist tuned to conditions, guidance,
/// refill intelligence with barrier-first fixes.
struct MedDetailView: View {
    @Environment(AppModel.self) private var model
    let medication: Medication

    @State private var showPDC = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text("\(medication.dose) · \(medication.purposeLine)")
                        .font(NudgeType.rounded(13.5))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                // Refill intelligence — barrier-first, never a guilt trip.
                if medication.supplyDaysRemaining <= 7 && model.pathway == .metabolic {
                    OrganicSurface(radius: 30) {
                        VStack(alignment: .leading, spacing: 9) {
                            Kicker(text: "Heads-up", color: Theme.attention)
                            Text("You'll run out next Thursday")
                                .font(NudgeType.serif(18))
                                .foregroundStyle(Theme.ink)
                            Text("The refill is ready at \(medication.pharmacy). If getting there is the hard part this week, delivery is one tap away.")
                                .font(NudgeType.rounded(13.5))
                                .foregroundStyle(Theme.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                            Button {
                                model.openConversation(seed: "refill")
                            } label: {
                                Text("Sort it with me")
                                    .font(NudgeType.rounded(13.5, .semibold))
                                    .foregroundStyle(Theme.base)
                                    .padding(.horizontal, 17)
                                    .padding(.vertical, 9)
                                    .background(Theme.ink, in: .capsule)
                            }
                            .buttonStyle(NudgeButtonStyle())
                        }
                        .padding(17)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    TideView(level: medication.tideLevel, height: 90)
                    HStack {
                        Text("Your tide, last 30 days")
                            .font(NudgeType.rounded(12))
                            .foregroundStyle(Theme.inkMuted)
                        Spacer()
                        Button {
                            withAnimation(NudgeSpring.ui) { showPDC.toggle() }
                        } label: {
                            Text(showPDC ? pdcLine : "For the data-curious")
                                .font(NudgeType.rounded(11.5, .medium))
                                .foregroundStyle(Theme.inkMuted)
                                .underline(!showPDC)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }

                detailSection(kicker: "Good to know", color: Theme.sky, items: medication.guidance)
                detailSection(kicker: "We watch for", color: Theme.warm, items: medication.watchlist)
                detailSection(kicker: "Dose history", color: Theme.life, items: medication.history)

                logSection

                ProvenanceChip(text: "Dispense data from \(medication.pharmacy) · checked against your full med list")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var pdcLine: String {
        let pdc = Int((medication.tideLevel * 100).rounded())
        return "PDC \(pdc)% — solidly covered"
    }

    /// Symptoms logged in this med's orbit — and the door to add one.
    private var logSection: some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Kicker(text: "How it's been feeling", color: Theme.rose)
                    Spacer()
                    Button {
                        Haptics.tick()
                        model.quickLogMedID = medication.id
                        model.showQuickLog = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .medium))
                            Text("Log near this med")
                                .font(NudgeType.rounded(11.5, .medium))
                        }
                        .foregroundStyle(Theme.warm)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.warm.opacity(0.11), in: .capsule)
                    }
                    .buttonStyle(NudgeButtonStyle())
                }

                let related = model.logs(near: medication.id)
                if related.isEmpty {
                    Text("Nothing logged here yet. Anything you notice around doses — cramps, dizziness, anything — lands here and sharpens the pattern.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(related) { log in
                        HStack(spacing: 9) {
                            Circle()
                                .fill(Theme.rose.opacity(0.6))
                                .frame(width: 5, height: 5)
                            Text(log.kind)
                                .font(NudgeType.rounded(13.5, .medium))
                                .foregroundStyle(Theme.ink)
                            if let region = log.bodyRegion {
                                Text(region.lowercased())
                                    .font(NudgeType.rounded(11.5))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                            Spacer()
                            Text(log.at.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(NudgeType.rounded(11))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(17)
        }
    }

    private func detailSection(kicker: String, color: Color, items: [String]) -> some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 10) {
                Kicker(text: kicker, color: color)
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 9) {
                        Circle()
                            .fill(color.opacity(0.55))
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
