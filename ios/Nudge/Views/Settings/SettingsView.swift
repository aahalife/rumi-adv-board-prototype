import SwiftUI

/// Settings — tone, appearance, notification classes, sound, era warmth, and
/// the journey previewer (see the whole experience through another life).
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var showPrivacy = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ZStack {
                LivingGradientView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("Settings")
                                .font(NudgeType.serif(28))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundStyle(Theme.inkMuted)
                                    .frame(width: 34, height: 34)
                                    .background(.ultraThinMaterial, in: .circle)
                            }
                            .buttonStyle(NudgeButtonStyle())
                        }
                        .padding(.top, 16)

                        section("You") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    TextField("First name", text: Binding(
                                        get: { model.profile.firstName },
                                        set: { model.profile.firstName = $0 }
                                    ))
                                    .font(NudgeType.rounded(14.5))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial, in: .capsule)

                                    TextField("Last name", text: Binding(
                                        get: { model.profile.lastName },
                                        set: { model.profile.lastName = $0 }
                                    ))
                                    .font(NudgeType.rounded(14.5))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial, in: .capsule)
                                }
                                Text("Your name shapes the greeting; your birthday (set during setup) is what matches hospital records to you.")
                                    .font(NudgeType.rounded(11.5))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                        }

                        section("How I speak with you") {
                            choiceRow(options: ["Gentle nudges", "Straight talk"], selection: $model.tonePreference)
                        }

                        section("Day & night") {
                            VStack(alignment: .leading, spacing: 10) {
                                choiceRow(options: ["Auto", "Day", "Night"], selection: $model.appearance)
                                Text("Two worlds, one soul — Clay & Dawn by day, Indigo Night after dark. Auto follows your phone.")
                                    .font(NudgeType.rounded(11.5))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                        }

                        // The previewer — feel how the experience re-shapes
                        // itself around a different life.
                        section("Preview another journey") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(CarePathway.allCases) { pathway in
                                    let persona = PersonaFixtures.persona(for: pathway)
                                    let selected = model.pathway == pathway
                                    Button {
                                        Haptics.glass()
                                        model.switchPathway(pathway)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: pathway.glyph)
                                                .font(.system(size: 14, weight: .light))
                                                .foregroundStyle(selected ? Theme.warm : Theme.inkMuted)
                                                .frame(width: 34, height: 34)
                                                .background((selected ? Theme.warm : Theme.inkMuted).opacity(0.12), in: .circle)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(persona.switcherLine)
                                                    .font(NudgeType.rounded(13.5, selected ? .semibold : .medium))
                                                    .foregroundStyle(Theme.ink)
                                                Text(pathway.choiceDetail)
                                                    .font(NudgeType.rounded(11.5))
                                                    .foregroundStyle(Theme.inkMuted)
                                            }
                                            Spacer()
                                            if selected {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(Theme.life)
                                            }
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(NudgeButtonStyle())
                                }
                                Text("Everything adapts — symptoms, metrics, the plan, what I watch for. Same calm world, different life inside it.")
                                    .font(NudgeType.rounded(11.5))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                        }

                        section("When I reach out") {
                            VStack(spacing: 2) {
                                ForEach(Array(model.notificationClasses.keys.sorted()), id: \.self) { key in
                                    Toggle(isOn: binding(for: key)) {
                                        Text(key)
                                            .font(NudgeType.rounded(14.5))
                                            .foregroundStyle(Theme.ink)
                                    }
                                    .tint(Theme.life)
                                    .padding(.vertical, 7)
                                }
                                HStack {
                                    Text("Quiet hours")
                                        .font(NudgeType.rounded(14.5))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Text("\(format(model.quietStart)) – \(format(model.quietEnd))")
                                        .font(NudgeType.number(14))
                                        .foregroundStyle(Theme.inkMuted)
                                }
                                .padding(.vertical, 9)
                                Text("Never more than 2 a day, 8 a week — that's a promise, not a setting.")
                                    .font(NudgeType.rounded(11.5))
                                    .foregroundStyle(Theme.inkMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        section("Appearance") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Era warmth")
                                    .font(NudgeType.rounded(13, .medium))
                                    .foregroundStyle(Theme.inkMuted)
                                choiceRow(options: ["Off", "Subtle", "Full"], selection: $model.eraWarmth)
                                Text("A faint echo of your formative years in the ambiance — never on clinical screens.")
                                    .font(NudgeType.rounded(11.5))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                        }

                        section("Sound & score") {
                            VStack(spacing: 10) {
                                Toggle(isOn: $model.musicOn) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Music")
                                            .font(NudgeType.rounded(14.5))
                                            .foregroundStyle(Theme.ink)
                                        Text("Stone Kintsugi carries the app; Barley Thunder welcomes you in. One tap and it all goes quiet.")
                                            .font(NudgeType.rounded(11.5))
                                            .foregroundStyle(Theme.inkMuted)
                                    }
                                }
                                .tint(Theme.gold)

                                Toggle(isOn: $model.soundOn) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Touch notes & moments")
                                            .font(NudgeType.rounded(14.5))
                                            .foregroundStyle(Theme.ink)
                                        Text("Taps sing tiny sung notes — ordinary use composes a little melody. Off means truly silent.")
                                            .font(NudgeType.rounded(11.5))
                                            .foregroundStyle(Theme.inkMuted)
                                    }
                                }
                                .tint(Theme.life)
                            }
                        }

                        Button {
                            showPrivacy = true
                        } label: {
                            OrganicSurface(radius: 28) {
                                HStack(spacing: 13) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Theme.sky)
                                        .frame(width: 38, height: 38)
                                        .background(Theme.sky.opacity(0.13), in: .circle)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Privacy Center")
                                            .font(NudgeType.serif(17))
                                            .foregroundStyle(Theme.ink)
                                        Text("Every source, every scope, what I remember — all yours to see and change.")
                                            .font(NudgeType.rounded(12))
                                            .foregroundStyle(Theme.inkMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(Theme.inkMuted)
                                }
                                .padding(16)
                            }
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 50)
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(isPresented: $showPrivacy) {
                PrivacyCenterView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func binding(for key: String) -> Binding<Bool> {
        Binding(
            get: { model.notificationClasses[key] ?? true },
            set: { model.notificationClasses[key] = $0 }
        )
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        OrganicSurface(radius: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: title)
                content()
            }
            .padding(17)
        }
    }

    private func choiceRow(options: [String], selection: Binding<String>) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = selection.wrappedValue == option
                Button {
                    Haptics.tick()
                    withAnimation(NudgeSpring.ui) { selection.wrappedValue = option }
                } label: {
                    Text(option)
                        .font(NudgeType.rounded(13, selected ? .semibold : .medium))
                        .foregroundStyle(selected ? Theme.ink : Theme.inkMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            selected ? AnyShapeStyle(Theme.surface) : AnyShapeStyle(.ultraThinMaterial),
                            in: .capsule
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                selected ? Theme.ink.opacity(0.3) : Color.white.opacity(0.2),
                                lineWidth: 0.9
                            )
                        )
                }
                .buttonStyle(NudgeButtonStyle())
            }
        }
    }

    private func format(_ hour: Int) -> String {
        let h = hour % 24
        let suffix = h < 12 ? "am" : "pm"
        let display = h % 12 == 0 ? 12 : h % 12
        return "\(display)\(suffix)"
    }
}
