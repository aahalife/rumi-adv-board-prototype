import SwiftUI

/// The discussion guide — every question and observation worth ten minutes of
/// a doctor's full attention, captured the moment it happens. A fresh take on
/// "bring a list": the list writes itself, you just approve it.
struct DiscussionGuideView: View {
    @Environment(AppModel.self) private var model

    @State private var newText = ""
    @State private var newKind: GuideItem.Kind = .question
    @State private var sent = false
    @State private var confirming = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discussion guide")
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text(nextVisitLine)
                        .font(NudgeType.rounded(13.5))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                composer

                if model.guideItems.isEmpty {
                    VStack(spacing: 10) {
                        SceneVisual(seed: 55, height: 90)
                        Text("Nothing waiting — questions land here from your logs,\nor whenever one occurs to you.")
                            .font(NudgeType.rounded(13))
                            .foregroundStyle(Theme.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    let questions = model.guideItems.filter { $0.kind == .question }
                    let observations = model.guideItems.filter { $0.kind == .observation }

                    if !questions.isEmpty {
                        Text("Worth asking")
                            .font(NudgeType.serif(19))
                            .foregroundStyle(Theme.ink)
                        ForEach(questions) { item in
                            guideRow(item)
                        }
                    }
                    if !observations.isEmpty {
                        Text("Worth telling them")
                            .font(NudgeType.serif(19))
                            .foregroundStyle(Theme.ink)
                            .padding(.top, 4)
                        ForEach(observations) { item in
                            guideRow(item)
                        }
                    }

                    sendAhead
                }

                ProvenanceChip(text: "Built from your logs, patterns, and the things you tell me")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var nextVisitLine: String {
        if let next = model.appointments.first {
            return "For \(next.with) · \(next.date.formatted(.dateTime.month(.wide).day()))"
        }
        return "For whenever you next sit down with your care team"
    }

    // MARK: Add your own

    private var composer: some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    kindChip(.question, label: "A question")
                    kindChip(.observation, label: "Something to tell them")
                }
                HStack(spacing: 10) {
                    TextField("It lands here so it can't slip away…", text: $newText, axis: .vertical)
                        .font(NudgeType.rounded(14))
                        .lineLimit(1...3)
                        .focused($focused)
                    Button {
                        let text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        model.addGuideItem(kind: newKind, text: text, from: "You added it · \(Date.now.formatted(.dateTime.month(.abbreviated).day()))")
                        newText = ""
                        focused = false
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.base)
                            .frame(width: 36, height: 36)
                            .background(Theme.ink.opacity(newText.isEmpty ? 0.35 : 1), in: .circle)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .disabled(newText.isEmpty)
                }
            }
            .padding(14)
        }
    }

    private func kindChip(_ kind: GuideItem.Kind, label: String) -> some View {
        let selected = newKind == kind
        return Button {
            Haptics.tick()
            withAnimation(NudgeSpring.ui) { newKind = kind }
        } label: {
            Text(label)
                .font(NudgeType.rounded(12, selected ? .semibold : .medium))
                .foregroundStyle(selected ? Theme.ink : Theme.inkMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    selected ? AnyShapeStyle(Theme.gold.opacity(0.18)) : AnyShapeStyle(.ultraThinMaterial),
                    in: .capsule
                )
                .overlay(
                    Capsule().strokeBorder(selected ? Theme.gold.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 0.9)
                )
        }
        .buttonStyle(NudgeButtonStyle())
    }

    private func guideRow(_ item: GuideItem) -> some View {
        OrganicSurface(radius: 26) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    Haptics.tick()
                    withAnimation(NudgeSpring.ui) { model.toggleGuideResolved(item.id) }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(item.resolved ? Theme.life : Theme.inkMuted.opacity(0.4), lineWidth: 1.3)
                            .frame(width: 26, height: 26)
                        if item.resolved {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.life)
                        }
                    }
                }
                .buttonStyle(NudgeButtonStyle())
                .accessibilityLabel(item.resolved ? "Covered" : "Mark covered")

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.text)
                        .font(NudgeType.rounded(14))
                        .foregroundStyle(item.resolved ? Theme.inkMuted : Theme.ink)
                        .strikethrough(item.resolved, color: Theme.inkMuted.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.addedFrom)
                        .font(NudgeType.rounded(11))
                        .foregroundStyle(Theme.inkMuted.opacity(0.8))
                }

                Spacer(minLength: 0)

                Button {
                    withAnimation(NudgeSpring.ui) { model.removeGuideItem(item.id) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Theme.inkMuted.opacity(0.7))
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(NudgeButtonStyle())
                .accessibilityLabel("Remove")
            }
            .padding(14)
        }
    }

    private var sendAhead: some View {
        Group {
            if sent {
                Label("Sent ahead — the visit starts where it matters.", systemImage: "checkmark")
                    .font(NudgeType.rounded(13.5, .medium))
                    .foregroundStyle(Theme.life)
            } else {
                Button {
                    confirming = true
                } label: {
                    Text("Send these ahead to \(model.persona.officeName)")
                        .font(NudgeType.rounded(15, .semibold))
                        .foregroundStyle(Theme.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())
                .confirmationDialog(
                    "Send your open questions and observations to \(model.persona.officeName)? Nothing goes without this yes.",
                    isPresented: $confirming,
                    titleVisibility: .visible
                ) {
                    Button("Send ahead") {
                        sent = true
                        Haptics.success()
                        SoundEngine.shared.tick()
                    }
                    Button("Not now", role: .cancel) {}
                }
            }
        }
        .padding(.top, 6)
    }
}
