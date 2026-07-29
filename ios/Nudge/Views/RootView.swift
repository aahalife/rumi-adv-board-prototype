import SwiftUI

/// The shell after onboarding: tab scenes, floating dock, the persistent
/// minimized orb, the conversation morph, quick-log sheet, and the recap film.
/// The whole canvas answers touch — every tap sends a fluid wave through the
/// world, not just one corner of it.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Namespace private var orbSpace

    var body: some View {
        @Bindable var model = model

        ZStack {
            Group {
                switch model.tab {
                case .today:
                    TodayCanvasView(orbSpace: orbSpace)
                case .care:
                    CareHubView()
                case .you:
                    YouView()
                case .journeys:
                    JourneysView()
                case .currents:
                    CurrentsView()
                }
            }
            .opacity(model.showConversation ? 0 : 1)

            // The companion is not a tab — it is everywhere.
            if !model.showConversation && model.tab != .today {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            Haptics.glass()
                            SoundEngine.shared.glass()
                            model.openConversation()
                        } label: {
                            OrbView(size: 34, state: model.orb)
                                .padding(5)
                                .modifier(CircularGlass())
                        }
                        .buttonStyle(NudgeButtonStyle())
                        .accessibilityLabel("Talk with Rumi")
                    }
                    .padding(.trailing, 20)
                    Spacer()
                }
            }

            if !model.showConversation {
                VStack {
                    Spacer()
                    NudgeDock()
                        .padding(.bottom, 6)
                }
            }

            if model.showConversation {
                ConversationView(orbSpace: orbSpace)
                    .transition(.opacity)
            }

            if let ack = model.quickLogAck {
                VStack {
                    Spacer()
                    CompanionAckToast(text: ack)
                        .padding(.bottom, 112)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(NudgeSpring.gentle, value: model.quickLogAck)
            }
        }
        .sheet(isPresented: $model.showQuickLog) {
            QuickLogView(linkedMedID: model.quickLogMedID)
                .presentationDetents([.large])
                .presentationBackground(Theme.base)
        }
        .sheet(isPresented: $model.showSettings) {
            SettingsView()
                .presentationBackground(Theme.base)
        }
        .sheet(isPresented: $model.showAgentNetwork) {
            AgentNetworkView()
                .presentationBackground(Theme.base)
        }
        .fullScreenCover(isPresented: $model.showRecap) {
            RecapPlayerView()
        }
        .onChange(of: model.showConversation) { _, open in
            if open {
                SoundEngine.shared.playBed(.ambient)
            }
        }
    }
}

/// Every log gets a companion response within seconds — never a mute write.
struct CompanionAckToast: View {
    @Environment(AppModel.self) private var model
    let text: String

    var body: some View {
        GlassSurface(radius: 30) {
            HStack(alignment: .top, spacing: 12) {
                OrbView(size: 34, state: model.orb)
                Text(text)
                    .font(NudgeType.rounded(14))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .padding(.horizontal, 24)
        .onTapGesture {
            model.quickLogAck = nil
            model.openConversation(seed: "pattern")
        }
    }
}
