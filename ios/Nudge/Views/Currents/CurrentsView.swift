import SwiftUI

/// Currents — a finite, flowing daily set. Full-bleed scenes, four formats,
/// an honest end. No infinite feed. Ever.
struct CurrentsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.currents) { piece in
                        CurrentPage(piece: piece)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    endScene
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var endScene: some View {
        VStack(spacing: 18) {
            Spacer()
            SceneVisual(seed: 99, height: 160)
            Text("That's today's current.")
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)
            Text("I'd rather you live your life than scroll.\nAnything unread rolls forward — nothing expires.")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 36)
    }
}

/// One piece — a scene, not a card.
private struct CurrentPage: View {
    @Environment(AppModel.self) private var model
    let piece: CurrentsPiece

    @State private var saveFired = false
    @State private var listening = false
    @State private var watching = false

    var body: some View {
        ZStack {
            scene
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: piece.formatGlyph)
                                .font(.system(size: 10, weight: .medium))
                            Text("\(piece.format.rawValue) · \(piece.durationLabel)")
                                .font(NudgeType.rounded(11, .medium))
                        }
                        .foregroundStyle(Theme.inkMuted)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: .capsule)

                        if piece.aiGenerated {
                            Text("AI-crafted for you")
                                .font(NudgeType.rounded(10.5, .medium))
                                .foregroundStyle(Theme.inkMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: .capsule)
                        }
                    }

                    Kicker(text: piece.kicker, color: Theme.warm)

                    Text(piece.headline)
                        .font(NudgeType.serif(piece.format == .read ? 30 : 27))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if piece.format == .watch {
                        watchChrome
                    } else if piece.format == .listen {
                        listenChrome
                    }

                    Text(piece.body)
                        .font(piece.format == .read ? NudgeType.serif(16.5, .regular) : NudgeType.rounded(15))
                        .foregroundStyle(Theme.ink.opacity(0.85))
                        .lineSpacing(piece.format == .read ? 7 : 4)
                        .lineLimit(piece.format == .read ? 14 : 6)
                }

                actionRow
                    .padding(.top, 22)
                    .padding(.bottom, 110)
            }
            .padding(.horizontal, 26)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: saveFired)
        .sheet(isPresented: $listening) {
            ListenSheet(piece: piece)
                .presentationDetents([.large])
                .presentationBackground(Theme.base)
        }
        .fullScreenCover(isPresented: $watching) {
            WatchSheet(piece: piece)
        }
    }

    /// Every piece is a scene — a full-bleed illustration in the app's own
    /// light, falling back to the generative ground.
    @ViewBuilder
    private var scene: some View {
        if let name = piece.imageName, UIImage(named: name) != nil {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Color.clear
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height * 0.62)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, Theme.base.opacity(0.35), Theme.base],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
            }
            .allowsHitTesting(false)
        } else {
            SceneVisual(seed: piece.sceneSeed, height: 700)
                .opacity(0.85)
                .allowsHitTesting(false)
        }
    }

    private var watchChrome: some View {
        Button {
            Haptics.glass()
            SoundEngine.shared.glass()
            watching = true
        } label: {
            GlassSurface(radius: 28, interactive: true) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44)
                        .background(Theme.surface.opacity(0.9), in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tap to watch · captioned by default")
                            .font(NudgeType.rounded(12.5, .medium))
                            .foregroundStyle(Theme.ink)
                        Text("90 seconds · scored")
                            .font(NudgeType.rounded(11))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    Spacer()
                }
                .padding(12)
            }
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel("Watch this piece")
    }

    private var listenChrome: some View {
        Button {
            Haptics.glass()
            SoundEngine.shared.glass()
            listening = true
        } label: {
            GlassSurface(radius: 28, interactive: true) {
                HStack(spacing: 12) {
                    OrbView(size: 38, state: model.orb)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("A scored couple of minutes")
                            .font(NudgeType.rounded(12.5, .medium))
                            .foregroundStyle(Theme.ink)
                        Text("Tap to listen · transcript below")
                            .font(NudgeType.rounded(11))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.ink)
                }
                .padding(12)
            }
        }
        .buttonStyle(NudgeButtonStyle())
        .accessibilityLabel("Listen to this piece")
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionChip(
                glyph: piece.saved ? "bookmark.fill" : "bookmark",
                label: piece.saved ? "Saved to story" : "Save",
                active: piece.saved
            ) {
                saveFired.toggle()
                withAnimation(NudgeSpring.ui) { model.toggleCurrentSaved(piece.id) }
            }
            actionChip(glyph: "hand.thumbsup", label: "More", active: piece.taste == 1) {
                withAnimation(NudgeSpring.ui) { model.setTaste(piece.id, value: 1) }
            }
            actionChip(glyph: "hand.thumbsdown", label: "Less", active: piece.taste == -1) {
                withAnimation(NudgeSpring.ui) { model.setTaste(piece.id, value: -1) }
            }
            actionChip(glyph: "bubble", label: "Ask", active: false) {
                model.openConversation(seed: piece.headline.lowercased())
            }
        }
    }

    private func actionChip(glyph: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: glyph)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(NudgeType.rounded(12, .medium))
            }
            .foregroundStyle(active ? Theme.gold : Theme.ink)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: .capsule)
            .overlay(
                Capsule().strokeBorder(
                    active ? Theme.gold.opacity(0.5) : Color.white.opacity(0.25),
                    lineWidth: 0.9
                )
            )
        }
        .buttonStyle(NudgeButtonStyle())
    }
}
