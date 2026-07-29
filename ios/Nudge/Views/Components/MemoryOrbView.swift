import SwiftUI
import PhotosUI

/// A held moment — a photograph suspended inside true Liquid Glass. On
/// iOS 26 the lens is the real thing: native glass refracting the photo
/// beneath it. Earlier systems get the hand-shaded illusion. Tap to open
/// the arc viewer, where moments swing past like beads of light.
struct MemoryOrbView: View {
    let memory: MemoryGlimpse
    var size: CGFloat = 118
    var onTap: (() -> Void)? = nil

    @State private var bob = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                Haptics.glass()
                SoundEngine.shared.glass()
                onTap?()
            } label: {
                MemoryOrbGlass(memory: memory, size: size)
            }
            .buttonStyle(NudgeButtonStyle())
            .offset(y: bob ? -3 : 3)
            .animation(.easeInOut(duration: Double.random(in: 2.6...3.6)).repeatForever(autoreverses: true), value: bob)

            VStack(spacing: 1) {
                Text(memory.caption)
                    .font(NudgeType.rounded(11.5, .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(memory.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(NudgeType.number(10, .medium))
                    .foregroundStyle(Theme.inkMuted)
            }
            .frame(width: size + 14)
        }
        .onAppear { bob = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Held moment: \(memory.caption). Tap to open.")
    }
}

/// The glass bead itself — photo beneath, native glass lens above.
struct MemoryOrbGlass: View {
    let memory: MemoryGlimpse
    var size: CGFloat

    var body: some View {
        ZStack {
            MemoryPhoto(memory: memory)
                .frame(width: size, height: size)
                .clipShape(.circle)

            if #available(iOS 26.0, *) {
                // The real lens — native Liquid Glass refracting the photo.
                Color.clear
                    .frame(width: size, height: size)
                    .glassEffect(.clear, in: .circle)
            } else {
                legacyShading
            }
        }
        .overlay(
            Circle().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.85), .white.opacity(0.08), .white.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
        .shadow(color: Theme.shadow.opacity(0.25), radius: 12, y: 8)
    }

    /// Pre-26 bubble illusion: refraction shading + specular kiss.
    private var legacyShading: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.62),
                            .init(color: .black.opacity(0.18), location: 0.92),
                            .init(color: .white.opacity(0.16), location: 1.0),
                        ],
                        center: .center, startRadius: 0, endRadius: size / 2
                    )
                )
            Ellipse()
                .fill(
                    LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.46, height: size * 0.2)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.16, y: -size * 0.3)
                .blur(radius: 1.5)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

/// Resolves a memory's photo from Documents or the bundle.
struct MemoryPhoto: View {
    let memory: MemoryGlimpse

    var body: some View {
        if let filename = memory.photoFilename,
           let image = UIImage(contentsOfFile: URL.documentsDirectory.appendingPathComponent(filename).path) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let name = memory.imageName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            LinearGradient(colors: [Theme.rose.opacity(0.5), Theme.sky.opacity(0.4)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - The arc viewer

/// Held moments on a swinging arc. The chosen one rises into a large glass
/// lens; the rest wait along the curve below. Drag anywhere to swing the
/// arc — beads sweep past in a circular motion and snap to the nearest.
struct MemoryArcViewer: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let memories: [MemoryGlimpse]
    @State private var selection: Int

    /// Continuous arc position in "indices" — selection + drag fraction.
    @State private var dragOffset: Double = 0
    @State private var snapTick = 0

    private let step: Double = 0.42   // radians between beads

    init(memories: [MemoryGlimpse], selection: Int) {
        self.memories = memories
        _selection = State(initialValue: min(max(selection, 0), max(memories.count - 1, 0)))
    }

    var body: some View {
        ZStack {
            ConversationScene()

            VStack(spacing: 0) {
                HStack {
                    ChromeIcon(systemName: "chevron.down", accessibilityText: "Close held moments") {
                        dismiss()
                    }
                    Spacer()
                    Text("Held moments")
                        .font(NudgeType.display(22))
                        .foregroundStyle(Theme.ink.opacity(0.9))
                    Spacer()
                    // Symmetry spacer
                    Color.clear.frame(width: 38, height: 38)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                heroOrb
                    .padding(.top, 6)

                VStack(spacing: 3) {
                    Text(current.caption)
                        .font(NudgeType.serif(21, .medium))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                    Text(current.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(NudgeType.rounded(12.5, .medium))
                        .foregroundStyle(Theme.inkMuted)
                        .contentTransition(.opacity)
                }
                .padding(.horizontal, 40)
                .padding(.top, 22)
                .animation(NudgeSpring.ui, value: selection)

                Spacer()

                arc
                    .frame(height: 190)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: snapTick)
        .gesture(arcDrag)
    }

    private var current: MemoryGlimpse {
        memories[min(max(selection, 0), memories.count - 1)]
    }

    /// The big lens — the chosen moment, large and luminous.
    private var heroOrb: some View {
        MemoryOrbGlass(memory: current, size: 300)
            .id(current.id)
            .transition(.scale(scale: 0.86).combined(with: .opacity))
            .animation(NudgeSpring.delight, value: selection)
            .shadow(color: Theme.shadow.opacity(0.3), radius: 26, y: 16)
    }

    /// Beads along a circle whose center sits far below the screen — drag
    /// swings them past in a true arc.
    private var arc: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let radius: CGFloat = 320
            let centerX = width / 2
            let centerY: CGFloat = radius + 60

            ZStack {
                ForEach(Array(memories.enumerated()), id: \.element.id) { index, memory in
                    let angle = (Double(index - selection) - dragOffset) * step
                    let visible = abs(angle) < 1.5
                    if visible {
                        let x = centerX + radius * CGFloat(sin(angle))
                        let y = centerY - radius * CGFloat(cos(angle))
                        let focus = max(0, 1 - abs(angle) / step)   // 1 at center
                        MemoryOrbGlass(memory: memory, size: 64 + 26 * CGFloat(focus))
                            .opacity(0.45 + 0.55 * focus)
                            .position(x: x, y: y)
                            .onTapGesture {
                                Haptics.tick()
                                SoundEngine.shared.tick()
                                withAnimation(NudgeSpring.delight) { selection = index }
                            }
                    }
                }
            }
        }
    }

    private var arcDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = -Double(value.translation.width) / 150
            }
            .onEnded { value in
                let projected = dragOffset - Double(value.predictedEndTranslation.width - value.translation.width) / 400
                let target = (Double(selection) + projected).rounded()
                let clamped = Int(min(max(target, 0), Double(memories.count - 1)))
                snapTick += 1
                SoundEngine.shared.glass()
                withAnimation(NudgeSpring.delight) {
                    selection = clamped
                    dragOffset = 0
                }
            }
    }
}

/// The add-bubble: pick a photo of a good moment and it joins the glass.
struct AddMemoryOrb: View {
    @Environment(AppModel.self) private var model
    var size: CGFloat = 118

    @State private var pickedItem: PhotosPickerItem? = nil
    @State private var caption = ""
    @State private var pendingFilename: String? = nil
    @State private var namingMoment = false

    var body: some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [5, 6]))
                        .foregroundStyle(Theme.inkMuted.opacity(0.5))
                    Image(systemName: "camera")
                        .font(.system(size: size * 0.2, weight: .light))
                        .foregroundStyle(Theme.inkMuted)
                }
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: .circle)
            }
            .buttonStyle(NudgeButtonStyle())
            .accessibilityLabel("Add a held moment — a selfie or photo of a good day")

            Text("Hold a moment")
                .font(NudgeType.rounded(11.5, .medium))
                .foregroundStyle(Theme.inkMuted)
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let filename = AppModel.saveMemoryPhoto(data) {
                    pendingFilename = filename
                    namingMoment = true
                }
                pickedItem = nil
            }
        }
        .alert("What made this one good?", isPresented: $namingMoment) {
            TextField("e.g. First walk after cycle 3", text: $caption)
            Button("Hold it") {
                if let filename = pendingFilename {
                    model.addMemory(photoFilename: filename,
                                    caption: caption.isEmpty ? "A good moment" : caption)
                }
                caption = ""
                pendingFilename = nil
            }
            Button("Cancel", role: .cancel) {
                caption = ""
                pendingFilename = nil
            }
        } message: {
            Text("A few words — future-you will want to remember why.")
        }
    }
}
