import SwiftUI

/// The conversation, out loud. The orb takes the whole stage; your voice
/// becomes a halo of light around it; the companion answers in a real voice.
/// Once it opens, turns are hands-free: silence commits a turn, then Rumi
/// answers and starts listening again.
struct VoiceModeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var session = VoiceSession()

    var body: some View {
        ZStack {
            ConversationScene()

            VoiceGradientGlow(
                level: session.level,
                active: session.phase == .listening || session.phase == .speaking
            )

            VStack(spacing: 0) {
                header

                Spacer()

                orbStage

                VStack(spacing: 10) {
                    Text(statusLine)
                        .font(NudgeType.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkMuted)
                        .tracking(0.4)
                        .contentTransition(.opacity)
                        .animation(NudgeSpring.ui, value: session.phase)

                    if !session.heardText.isEmpty {
                        TypewriterText(text: "“\(session.heardText)”")
                            .font(NudgeType.serifItalic(15))
                            .foregroundStyle(Theme.inkMuted)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if !session.replyText.isEmpty {
                        Text(session.replyText)
                            .font(NudgeType.serif(19, .medium))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .shadow(color: Theme.warm.opacity(0.22), radius: 16)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if case .unavailable(let message) = session.phase {
                        Text(message)
                            .font(NudgeType.rounded(13.5))
                            .foregroundStyle(Theme.inkMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 36)
                .padding(.top, 26)
                .animation(NudgeSpring.gentle, value: session.heardText)
                .animation(NudgeSpring.gentle, value: session.replyText)
                .frame(minHeight: 150, alignment: .top)

                Spacer()

                micButton
                    .padding(.bottom, 44)
            }
        }
        .onAppear {
            session.start(model: model)
        }
        .onDisappear {
            session.teardown(orb: model.orb)
        }
    }

    private var header: some View {
        HStack {
            ChromeIcon(systemName: "chevron.down", accessibilityText: "Back to the conversation") {
                session.stop(model: model)
                dismiss()
            }
            Spacer()
            Text("Out loud")
                .font(NudgeType.display(22))
                .foregroundStyle(Theme.ink.opacity(0.9))
            Spacer()
            ChromeIcon(
                systemName: model.musicOn ? "speaker.wave.2.fill" : "speaker.slash",
                tint: model.musicOn ? Theme.gold : Theme.ink,
                accessibilityText: model.musicOn ? "Mute music" : "Play music"
            ) {
                model.musicOn.toggle()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    /// The orb with a breathing voice-halo — your loudness becomes light.
    private var orbStage: some View {
        ZStack {
            // Voice level halo — three soft rings that swell with the mic.
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .strokeBorder(
                        Theme.companion(.light)[ring].opacity(haloOpacity(ring)),
                        lineWidth: 1.4
                    )
                    .frame(width: 230 + CGFloat(ring) * 36, height: 230 + CGFloat(ring) * 36)
                    .scaleEffect(1 + session.level * (0.06 + Double(ring) * 0.05))
                    .animation(.spring(response: 0.32, dampingFraction: 0.6), value: session.level)
            }

            Button {
                session.toggle(model: model)
            } label: {
                VideoOrbView(size: 210, state: model.orb, showsHalo: true)
            }
            .buttonStyle(NudgeButtonStyle())
            .accessibilityLabel("Start or stop hands-free voice")
        }
        .frame(height: 330)
    }

    private func haloOpacity(_ ring: Int) -> Double {
        guard session.phase == .listening else { return 0 }
        return (0.5 - Double(ring) * 0.13) * (0.35 + session.level)
    }

    private var statusLine: String {
        switch session.phase {
        case .idle: return "STARTING HANDS-FREE VOICE"
        case .listening: return "LISTENING — I'LL PAUSE WHEN YOU'RE DONE"
        case .transcribing: return "GOT IT…"
        case .thinking: return "THINKING…"
        case .speaking: return "RUMI IS SPEAKING — TAP TO END"
        case .unavailable: return "VOICE UNAVAILABLE HERE"
        }
    }

    private var micButton: some View {
        Button {
            session.toggle(model: model)
        } label: {
            ZStack {
                if session.phase == .listening {
                    Circle()
                        .fill(Theme.warm.opacity(0.25))
                        .frame(width: 86, height: 86)
                        .scaleEffect(1 + session.level * 0.3)
                        .animation(.spring(response: 0.3, dampingFraction: 0.62), value: session.level)
                }
                Image(systemName: micGlyph)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(session.phase == .listening ? Theme.warm : Theme.ink)
                    .frame(width: 72, height: 72)
                    .modifier(CircularGlass())
                    .contentShape(Circle().inset(by: -10))
            }
        }
        .buttonStyle(NudgeButtonStyle())
        .opacity(session.phase == .transcribing || session.phase == .thinking ? 0.72 : 1)
        .accessibilityLabel(statusLine.capitalized)
    }

    private var micGlyph: String {
        switch session.phase {
        case .listening: return "waveform"
        case .speaking, .thinking, .transcribing: return "xmark"
        default: return "mic.fill"
        }
    }
}

/// Reveals text character by character so a freshly-heard transcript reads as
/// if it's being written down live, even though recognition commits at once.
private struct TypewriterText: View {
    let text: String
    @State private var shown = ""

    var body: some View {
        Text(shown)
            .task(id: text) {
                shown = ""
                for character in text {
                    shown.append(character)
                    try? await Task.sleep(for: .milliseconds(16))
                }
            }
    }
}
