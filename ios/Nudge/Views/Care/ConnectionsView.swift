import SwiftUI

/// Connections — link Google and your channels so the companion becomes
/// omnichannel: it can read context (a bill in email, a free slot on your
/// calendar), reach you where you already are, and still keep everything
/// logged inside the app. The companion's helpers are shown as one family.
struct ConnectionsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                group(title: "Google", subtitle: "Context and sending, with your permission",
                      items: model.connections.filter { $0.group == .google })

                group(title: "Your channels", subtitle: "Where Rumi can reach you, and you can reply",
                      items: model.connections.filter { $0.group == .channel })

                agentFamily

                ProvenanceChip(text: "Connect or disconnect any time — Rumi only uses what you allow")
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Connections")
                .font(NudgeType.serif(30))
                .foregroundStyle(Theme.ink)
            Text("Bring your world in — Rumi gets smarter and meets you where you already are.")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.trailing, 40)
    }

    private func group(title: String, subtitle: String, items: [Connection]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(NudgeType.serif(19))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(NudgeType.rounded(12.5))
                    .foregroundStyle(Theme.inkMuted)
            }
            VStack(spacing: 10) {
                ForEach(items) { connection in
                    ConnectionRow(connection: connection)
                }
            }
        }
    }

    private var agentFamily: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Your Rumi network")
                        .font(NudgeType.serif(19))
                        .foregroundStyle(Theme.ink)
                    Text("A family of specialized agents working quietly behind Rumi. Tap any one to see what it's doing.")
                        .font(NudgeType.rounded(12.5))
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Button {
                    model.openAgentNetwork()
                } label: {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(NudgeType.rounded(12, .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(Theme.sky)
                }
                .buttonStyle(NudgeButtonStyle())
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(model.agentServices) { service in
                    AgentServiceTile(service: service) {
                        model.openAgentNetwork(focus: service.id)
                    }
                }
            }
        }
    }
}

struct ConnectionRow: View {
    @Environment(AppModel.self) private var model
    let connection: Connection

    private var accent: Color {
        switch connection.accent {
        case .warm: return Theme.warm
        case .life: return Theme.life
        case .sky: return Theme.sky
        case .gold: return Theme.gold
        case .rose: return Theme.rose
        }
    }

    var body: some View {
        OrganicSurface(radius: 24) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: connection.glyph)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(accent)
                        .frame(width: 42, height: 42)
                        .background(accent.opacity(0.14), in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(connection.name)
                            .font(NudgeType.serif(16))
                            .foregroundStyle(Theme.ink)
                        Text(connection.connected ? (connection.accountLine ?? "Connected") : connection.detail)
                            .font(NudgeType.rounded(12))
                            .foregroundStyle(connection.connected ? Theme.life : Theme.inkMuted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    Button {
                        model.toggleConnection(connection.id)
                    } label: {
                        Text(connection.connected ? "Connected" : "Connect")
                            .font(NudgeType.rounded(12.5, .semibold))
                            .foregroundStyle(connection.connected ? Theme.life : Theme.base)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(connection.connected ? AnyShapeStyle(Theme.life.opacity(0.14)) : AnyShapeStyle(Theme.ink),
                                        in: .capsule)
                            .overlay {
                                if connection.connected {
                                    Capsule().strokeBorder(Theme.life.opacity(0.4), lineWidth: 0.9)
                                }
                            }
                    }
                    .buttonStyle(NudgeButtonStyle())
                }

                if connection.connected {
                    Text(connection.enables)
                        .font(NudgeType.rounded(12))
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
        }
    }
}

struct AgentServiceTile: View {
    @Environment(AppModel.self) private var model
    let service: AgentService
    var onTap: () -> Void

    private var accent: Color { agentAccentColor(service.accent) }
    private var waiting: Int { model.waitingCount(forAgent: service.id) }
    private var active: Int { model.activeTaskCount(forAgent: service.id) }

    var body: some View {
        Button {
            Haptics.tick()
            onTap()
        } label: {
            OrganicSurface(radius: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: service.glyph)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(service.active ? accent : Theme.inkMuted)
                            .frame(width: 36, height: 36)
                            .background((service.active ? accent : Theme.inkMuted).opacity(0.13), in: .circle)
                        Spacer()
                        if waiting > 0 {
                            Text("\(waiting)")
                                .font(NudgeType.number(10.5, .semibold))
                                .foregroundStyle(Theme.base)
                                .frame(minWidth: 16)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.warm, in: .capsule)
                        } else {
                            Circle()
                                .fill(service.active ? Theme.life : Theme.inkMuted.opacity(0.35))
                                .frame(width: 8, height: 8)
                        }
                    }
                    Text(service.name)
                        .font(NudgeType.serif(15))
                        .foregroundStyle(Theme.ink)
                    Text(tileStatus)
                        .font(NudgeType.rounded(11.5))
                        .foregroundStyle(waiting > 0 ? Theme.warm : Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
                .padding(13)
                .opacity(service.active ? 1 : 0.62)
            }
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel("\(service.name), \(service.active ? "active" : "paused"), \(active) in motion")
    }

    private var tileStatus: String {
        if !service.active { return "Paused" }
        if waiting > 0 { return "\(waiting) waiting · \(active) in motion" }
        return active > 0 ? "\(active) in motion" : service.role
    }
}
