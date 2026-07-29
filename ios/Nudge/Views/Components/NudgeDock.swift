import SwiftUI

/// The floating liquid-glass dock — five destinations. A single capsule of
/// true Liquid Glass on iOS 26; the selected tab is marked only by a quiet
/// tinted highlight behind its icon — no big sliding pill.
/// The companion is not here; it lives everywhere.
struct NudgeDock: View {
    @Environment(AppModel.self) private var model
    @State private var tapped = false

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                // A soft cool/bright tint lifts the glass off the warm living
                // ground so the refraction and edge actually read — untinted
                // glass over the warm gradient nearly vanished.
                bar
                    .glassEffect(.regular.tint(Theme.dockTint), in: .capsule)
                    .overlay(
                        Capsule().strokeBorder(
                            .linearGradient(
                                colors: [Color.white.opacity(0.55), Color.white.opacity(0.08)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 0.9
                        )
                    )
            } else {
                GlassSurface(radius: 34) { bar }
            }
        }
        .padding(.horizontal, 28)
        .shadow(color: Theme.shadow.opacity(0.22), radius: 24, y: 11)
        .sensoryFeedback(.impact(weight: .light), trigger: tapped)
    }

    private var bar: some View {
        HStack(spacing: 0) {
            ForEach(AppModel.Tab.allCases, id: \.self) { tab in
                dockItem(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
    }

    private func dockItem(_ tab: AppModel.Tab) -> some View {
        let selected = model.tab == tab
        let badge = tab == .care ? model.careUnreadCount : 0
        return Button {
            tapped.toggle()
            withAnimation(NudgeSpring.ui) { model.tab = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.glyph)
                    .font(.system(size: 17, weight: selected ? .medium : .light))
                    .symbolVariant(selected ? .fill : .none)
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Circle()
                                .fill(Theme.warm)
                                .frame(width: 7, height: 7)
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1))
                                .offset(x: 6, y: -3)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                Text(tab.rawValue)
                    .font(NudgeType.rounded(9.5, .medium))
            }
            .foregroundStyle(selected ? Theme.ink : Theme.inkMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if selected {
                    Capsule(style: .continuous)
                        .fill(Theme.warm.opacity(0.16))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                }
            }
            .animation(NudgeSpring.ui, value: selected)
            .contentShape(Rectangle())
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel(badge > 0 ? "\(tab.rawValue), \(badge) new" : tab.rawValue)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
