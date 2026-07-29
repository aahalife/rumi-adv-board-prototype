import SwiftUI

/// A calm, editorial space — insights as small magazine spreads, not a feed
/// of boxes. Honest epistemics on every pattern.
struct InsightsHubView: View {
    @Environment(AppModel.self) private var model
    @State private var filter: Insight.Category? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                filterChips
                    .padding(.top, 10)

                ForEach(filtered) { insight in
                    InsightSpread(insight: insight)
                        .onAppear { model.markInsightSeen(insight.id) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var filtered: [Insight] {
        let pool = filter == nil ? model.insights : model.insights.filter { $0.category == filter }
        return pool.sorted { lhs, rhs in
            (lhs.status == .saved ? 0 : 1) < (rhs.status == .saved ? 0 : 1)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(nil, label: "All")
                ForEach(Insight.Category.allCases) { category in
                    chip(category, label: category.rawValue)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 0)
    }

    private func chip(_ category: Insight.Category?, label: String) -> some View {
        let selected = filter == category
        return Button {
            withAnimation(NudgeSpring.ui) { filter = category }
        } label: {
            Text(label)
                .font(NudgeType.rounded(13, selected ? .semibold : .medium))
                .foregroundStyle(selected ? Theme.ink : Theme.inkMuted)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: .capsule)
                .overlay(
                    Capsule().strokeBorder(
                        selected ? Theme.ink.opacity(0.35) : Color.white.opacity(0.2),
                        lineWidth: 0.9
                    )
                )
        }
        .buttonStyle(NudgeButtonStyle())
    }
}

/// One insight, composed like a small magazine spread.
private struct InsightSpread: View {
    @Environment(AppModel.self) private var model
    let insight: Insight

    @State private var showWhy = false

    var body: some View {
        OrganicSurface(radius: 36) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Kicker(text: insight.category.rawValue, color: accent)
                    Spacer()
                    Button {
                        withAnimation(NudgeSpring.ui) { model.toggleInsightSaved(insight.id) }
                    } label: {
                        Image(systemName: insight.status == .saved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(insight.status == .saved ? Theme.gold : Theme.inkMuted)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .accessibilityLabel(insight.status == .saved ? "Saved" : "Save insight")
                }

                Text(insight.headline)
                    .font(NudgeType.serif(22))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                visual

                Text(insight.body)
                    .font(NudgeType.rounded(14.5))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let confidence = insight.confidence {
                    Text(confidence)
                        .font(NudgeType.rounded(12))
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if case .acted(let outcome) = insight.status {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.life)
                            .padding(.top, 1)
                        Text(outcome)
                            .font(NudgeType.rounded(13, .medium))
                            .foregroundStyle(Theme.life)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.life.opacity(0.1), in: .rect(cornerRadius: 18, style: .continuous))
                } else if let action = insight.actionLabel {
                    Button {
                        act()
                    } label: {
                        Text(action)
                            .font(NudgeType.rounded(13.5, .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(.ultraThinMaterial, in: .capsule)
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8))
                    }
                    .buttonStyle(NudgeButtonStyle())
                }

                HStack {
                    ProvenanceChip(text: insight.provenance)
                    Spacer()
                    Button {
                        withAnimation(NudgeSpring.ui) { showWhy.toggle() }
                    } label: {
                        Text("Why am I seeing this?")
                            .font(NudgeType.rounded(11.5, .medium))
                            .foregroundStyle(Theme.inkMuted)
                            .underline()
                    }
                    .buttonStyle(NudgeButtonStyle())
                }

                if showWhy {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(insight.sources, id: \.self) { source in
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(Theme.inkMuted.opacity(0.5)).frame(width: 4, height: 4).padding(.top, 6)
                                Text(source)
                                    .font(NudgeType.rounded(12))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface.opacity(0.7), in: .rect(cornerRadius: 18, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var visual: some View {
        switch insight.visual {
        case .chart(let seriesID):
            if let series = model.series(seriesID) {
                GlowChart(series: series, accent: accent, height: 120, compact: true)
            }
        case .scene(let seed):
            SceneVisual(seed: seed, height: 110)
                .clipShape(.rect(cornerRadius: 22, style: .continuous))
        case .tide:
            TideView(level: model.medications.first(where: { $0.id == "atorvastatin" })?.tideLevel ?? 0.8, height: 90)
        }
    }

    private var accent: Color {
        switch insight.category {
        case .pattern: return Theme.sky
        case .milestone: return Theme.gold
        case .headsUp: return Theme.attention
        case .opportunity: return Theme.life
        }
    }

    private func act() {
        switch insight.category {
        case .headsUp:
            model.openConversation(seed: "refill")
        case .pattern:
            model.openConversation(seed: "visit")
        default:
            model.openConversation(seed: insight.headline.lowercased())
        }
    }
}
