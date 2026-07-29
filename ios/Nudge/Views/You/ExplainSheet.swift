import SwiftUI

/// Three-tier disclosure: the reading → the next step → ask. Every clinical
/// statement carries a provenance chip.
struct SeriesExplainSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let series: LabSeries

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Capsule().fill(Theme.inkMuted.opacity(0.3)).frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                Text(series.name + ", in plain words")
                    .font(NudgeType.serif(24))
                    .foregroundStyle(Theme.ink)

                tier(kicker: "The reading", color: Theme.sky, text: series.explainReading)
                tier(kicker: "What to do next", color: Theme.life, text: series.explainNextStep)

                VStack(alignment: .leading, spacing: 10) {
                    Kicker(text: "Ask", color: Theme.warm)
                    Text(series.explainAsk)
                        .font(NudgeType.rounded(15))
                        .foregroundStyle(Theme.ink.opacity(0.85))
                        .lineSpacing(3)
                    Button {
                        dismiss()
                        model.openConversation(seed: series.id)
                    } label: {
                        Text("Talk it through")
                            .font(NudgeType.rounded(14, .semibold))
                            .foregroundStyle(Theme.base)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(Theme.ink, in: .capsule)
                    }
                    .buttonStyle(NudgeButtonStyle())
                }

                ProvenanceChip(text: "\(series.provenance) · explained with your kidney function in mind")
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func tier(kicker: String, color: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(text: kicker, color: color)
            Text(text)
                .font(NudgeType.rounded(15))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(3)
        }
    }
}

/// Generic record explain sheet for non-series rows.
struct ExplainSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let item: RecordItem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(Theme.inkMuted.opacity(0.3)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Text(item.title)
                .font(NudgeType.serif(24))
                .foregroundStyle(Theme.ink)

            Text(explanation)
                .font(NudgeType.rounded(15.5))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(4)

            Button {
                dismiss()
                model.openConversation(seed: item.title.lowercased())
            } label: {
                Text("Ask me anything about this")
                    .font(NudgeType.rounded(14, .semibold))
                    .foregroundStyle(Theme.base)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(Theme.ink, in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())

            ProvenanceChip(text: "From \(item.source) · \(item.date.formatted(.dateTime.month(.wide).year()))")

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var explanation: String {
        switch item.category {
        case .labs:
            return "This is one of your lab results. The number on its own matters less than the direction it's moving and the company it keeps — I read it alongside your kidneys, your meds, and your history before I say anything about it."
        case .medications:
            return "This is on your active list. I check it against everything else you take — including anything over-the-counter you tell me about — and I watch the refill rhythm so running out never sneaks up on you."
        case .conditions:
            return "This is part of your story, not a label. It shapes how I read every other number and which small moves matter most. Nothing here is news to your care team — and nothing about it changes what you're already doing well."
        case .immunizations:
            return "Your protection record. I keep an eye on what's due and when — with your conditions, staying current earns you more than most people get from it."
        case .procedures:
            return "A look-under-the-hood from your history. Results like this set the baseline I compare new signals against."
        case .notes:
            return "Your clinician's own words from a visit. Worth re-reading on the hard weeks — \"real progress\" was written about you."
        case .documents:
            return "Something you added yourself. It's part of the same story as everything else — searchable, shareable when you choose, and yours."
        }
    }
}
