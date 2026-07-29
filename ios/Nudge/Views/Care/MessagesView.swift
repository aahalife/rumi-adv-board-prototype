import SwiftUI

/// Messages — every care team in one calm inbox. The mode (true in-app thread
/// vs. drafted-for-the-portal) is always visible, so the user knows where their
/// words go. Nothing ever sends without an explicit tap (MSG-3).
struct MessagesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Messages")
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text("Your care teams, one place. Tap to read or reply.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                ForEach(model.threads.sorted { $0.lastAt > $1.lastAt }) { thread in
                    NavigationLink(value: CareDestination.thread(thread.id)) {
                        threadRow(thread)
                    }
                    .buttonStyle(NudgeButtonStyle())
                }

                NavigationLink(value: CareDestination.requests) {
                    HStack(spacing: 11) {
                        Image(systemName: "tray.full")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Theme.gold)
                            .frame(width: 36, height: 36)
                            .background(Theme.gold.opacity(0.13), in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Requests")
                                .font(NudgeType.rounded(14.5, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("Refills, records, forms — tracked end to end")
                                .font(NudgeType.rounded(12))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(NudgeButtonStyle())
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private func threadRow(_ thread: MessageThread) -> some View {
        OrganicSurface(radius: 26) {
            HStack(spacing: 13) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Theme.sky.opacity(0.16))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Text(initials(thread.memberName))
                                .font(NudgeType.rounded(15, .semibold))
                                .foregroundStyle(Theme.sky)
                        )
                    if thread.unread {
                        Circle()
                            .fill(Theme.warm)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().strokeBorder(Theme.surface, lineWidth: 2))
                            .offset(x: 2, y: -2)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(thread.memberName)
                            .font(NudgeType.serif(16.5))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(Self.shortTime(thread.lastAt))
                            .font(NudgeType.rounded(11))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    Text(thread.preview)
                        .font(NudgeType.rounded(12.5, thread.unread ? .medium : .regular))
                        .foregroundStyle(thread.unread ? Theme.ink.opacity(0.85) : Theme.inkMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    ModeChip(mode: thread.mode)
                        .padding(.top, 1)
                }
            }
            .padding(15)
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").filter { $0 != "Dr." && $0 != "RN," }
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    static func shortTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

/// Tiny glass chip stating where a message actually goes — secure in-app or
/// drafted for the portal. Trust the user with the mechanism (MSG-4).
struct ModeChip: View {
    let mode: MessageChannelMode

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mode == .inApp ? "lock.fill" : "arrow.up.forward.app")
                .font(.system(size: 8.5, weight: .semibold))
            Text(mode.label)
                .font(NudgeType.rounded(10.5, .medium))
        }
        .foregroundStyle(mode == .inApp ? Theme.life : Theme.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((mode == .inApp ? Theme.life : Theme.gold).opacity(0.12), in: .capsule)
    }
}

// MARK: - Thread detail

/// A single conversation. Origin context rides along on messages that began
/// elsewhere (a pattern, a result), so the care team always sees the why.
struct MessageThreadView: View {
    @Environment(AppModel.self) private var model
    let threadID: UUID

    @State private var draft = ""
    @FocusState private var composing: Bool

    private var thread: MessageThread? { model.threads.first { $0.id == threadID } }

    var body: some View {
        Group {
            if let thread {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            threadHeader(thread)
                            ForEach(thread.messages.sorted { $0.at < $1.at }) { message in
                                MessageBubble(message: message, mode: thread.mode)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 14)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: thread.messages.count) { _, _ in
                        if let last = thread.messages.sorted(by: { $0.at < $1.at }).last {
                            withAnimation(NudgeSpring.gentle) { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) { composeBar(thread) }
            } else {
                ContentUnavailableView("This conversation isn't available",
                                       systemImage: "bubble.left")
            }
        }
        .onAppear { model.markThreadRead(threadID) }
    }

    private func threadHeader(_ thread: MessageThread) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(thread.memberName)
                .font(NudgeType.serif(24))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                Text(thread.memberRole)
                    .font(NudgeType.rounded(12.5))
                    .foregroundStyle(Theme.inkMuted)
                ModeChip(mode: thread.mode)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private func composeBar(_ thread: MessageThread) -> some View {
        VStack(spacing: 0) {
            if thread.mode == .portal {
                Text("This practice doesn't take secure replies in-app. I'll draft it cleanly for you to send from their portal.")
                    .font(NudgeType.rounded(11.5))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 8)
            }
            GlassSurface(radius: 26) {
                HStack(alignment: .bottom, spacing: 10) {
                    TextField(thread.mode == .inApp ? "Write a reply…" : "Draft a message…",
                              text: $draft, axis: .vertical)
                        .font(NudgeType.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1...5)
                        .focused($composing)
                        .padding(.vertical, 9)
                        .padding(.leading, 6)
                    Button {
                        send(in: thread)
                    } label: {
                        Image(systemName: thread.mode == .inApp ? "arrow.up" : "tray.and.arrow.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.base)
                            .frame(width: 38, height: 38)
                            .background(canSend ? Theme.ink : Theme.inkMuted.opacity(0.4), in: .circle)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .disabled(!canSend)
                    .accessibilityLabel(thread.mode == .inApp ? "Send reply" : "Save draft")
                }
                .padding(7)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send(in thread: MessageThread) {
        guard canSend else { return }
        model.sendMessage(threadID: thread.id, text: draft)
        draft = ""
        composing = false
    }
}

/// One message — the user's words lean warm and right; the team's sit calm and
/// left. Origin and attachment provenance render above, never buried.
struct MessageBubble: View {
    let message: CareMessage
    let mode: MessageChannelMode

    private var isUser: Bool { message.author == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 44) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if let origin = message.origin {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 9, weight: .medium))
                        Text(origin)
                            .font(NudgeType.rounded(10.5, .medium))
                    }
                    .foregroundStyle(Theme.inkMuted)
                }
                Text(message.text)
                    .font(NudgeType.rounded(14.5))
                    .foregroundStyle(isUser ? Theme.base : Theme.ink)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(bubbleBackground)
                    .clipShape(.rect(cornerRadius: 22, style: .continuous))
                if let attachment = message.attachment {
                    HStack(spacing: 4) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 9, weight: .medium))
                        Text(attachment)
                            .font(NudgeType.rounded(10.5, .medium))
                    }
                    .foregroundStyle(Theme.inkMuted)
                }
                Text(stateLine)
                    .font(NudgeType.rounded(10.5))
                    .foregroundStyle(Theme.inkMuted)
            }
            if !isUser { Spacer(minLength: 44) }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isUser {
            LinearGradient(colors: [Theme.ink, Theme.ink.opacity(0.86)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Theme.surface.opacity(0.96)
        }
    }

    private var stateLine: String {
        let time = message.at.formatted(.dateTime.hour().minute())
        if isUser {
            switch message.state {
            case .draft: return "Drafted · \(time)"
            case .sending: return "Sending…"
            case .sent: return mode == .inApp ? "Sent · \(time)" : "Ready for the portal · \(time)"
            case .delivered: return "Delivered · \(time)"
            case .replied: return "Replied · \(time)"
            }
        }
        return time
    }
}
