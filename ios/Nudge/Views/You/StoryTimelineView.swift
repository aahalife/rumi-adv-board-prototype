import SwiftUI

/// The record reimagined as a narrative — a flowing vertical timeline with an
/// organic curved spine, chapters by year.
struct StoryTimelineView: View {
    @Environment(AppModel.self) private var model

    private let rowHeight: CGFloat = 116
    private let spineLeft: CGFloat = 38

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your story")
                    .font(NudgeType.display(32))
                    .foregroundStyle(Theme.ink)
                Text("Everything that brought you here — assembled, not filed.")
                    .font(NudgeType.rounded(13.5))
                    .foregroundStyle(Theme.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 14)

            recapDoor
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            timeline
                .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    /// The premier reward surface — offered, never auto-played.
    private var recapDoor: some View {
        Button {
            Haptics.glass()
            SoundEngine.shared.glass()
            model.showRecap = true
        } label: {
            Color(.secondarySystemBackground)
                .frame(height: 92)
                .overlay {
                    if UIImage(named: "recap_path") != nil {
                        Image("recap_path")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } else {
                        SceneVisual(seed: 64, height: 92)
                    }
                }
                .clipShape(.rect(cornerRadius: 30, style: .continuous))
                .overlay {
                    LinearGradient(colors: [.black.opacity(0.45), .black.opacity(0.15)],
                                   startPoint: .leading, endPoint: .trailing)
                        .clipShape(.rect(cornerRadius: 30, style: .continuous))
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .leading) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.22), in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Play your chapter")
                                .font(NudgeType.serif(17))
                                .foregroundStyle(.white)
                            Text("30 seconds · scored · yours")
                                .font(NudgeType.rounded(12))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.leading, 16)
                    .allowsHitTesting(false)
                }
                .contentShape(.rect(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel("Play your cinematic recap")
    }

    private var timeline: some View {
        let events = model.storyEvents
        return ZStack(alignment: .top) {
            Canvas { context, size in
                // The spine is a curved line, not a straight one.
                var spine = Path()
                spine.move(to: CGPoint(x: spineX(y: 0), y: 0))
                var y: CGFloat = 0
                while y <= size.height {
                    spine.addLine(to: CGPoint(x: spineX(y: y), y: y))
                    y += 6
                }
                context.stroke(
                    spine,
                    with: .linearGradient(
                        Gradient(colors: [Theme.warm.opacity(0.45), Theme.sky.opacity(0.4), Theme.gold.opacity(0.35)]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )

                for (index, event) in events.enumerated() {
                    let nodeY = CGFloat(index) * rowHeight + rowHeight / 2
                    let nodeX = spineX(y: nodeY)
                    let color = nodeColor(event.kind)
                    let glowRect = CGRect(x: nodeX - 11, y: nodeY - 11, width: 22, height: 22)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(0.55), color.opacity(0)]),
                            center: CGPoint(x: nodeX, y: nodeY),
                            startRadius: 0,
                            endRadius: 11
                        )
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: nodeX - 3.5, y: nodeY - 3.5, width: 7, height: 7)),
                        with: .color(color)
                    )
                }
            }
            .frame(height: CGFloat(events.count) * rowHeight)
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    storyRow(event, showYear: index == 0 || yearOf(events[index - 1].date) != yearOf(event.date))
                        .frame(height: rowHeight)
                }
            }
        }
    }

    private func storyRow(_ event: StoryEvent, showYear: Bool) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Color.clear.frame(width: spineLeft + 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if showYear {
                        Text(yearOf(event.date))
                            .font(NudgeType.serif(13, .bold))
                            .foregroundStyle(Theme.warm)
                    }
                    Text(monthDay(event.date))
                        .font(NudgeType.rounded(11, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                Text(event.title)
                    .font(NudgeType.serif(17))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(event.detail)
                    .font(NudgeType.rounded(12.5))
                    .foregroundStyle(Theme.inkMuted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 24)
        }
        .accessibilityElement(children: .combine)
    }

    private func spineX(y: CGFloat) -> CGFloat {
        spineLeft + sin(y * 0.012) * 13
    }

    private func nodeColor(_ kind: StoryEvent.Kind) -> Color {
        switch kind {
        case .milestone: return Theme.gold
        case .result: return Theme.sky
        case .visit: return Theme.life
        case .diagnosis: return Theme.warm
        case .companion: return Theme.gold
        }
    }

    private func yearOf(_ date: Date) -> String {
        String(Calendar.current.component(.year, from: date))
    }

    private func monthDay(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}
