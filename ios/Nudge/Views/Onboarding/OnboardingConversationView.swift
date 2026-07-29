import SwiftUI

/// The first conversation — three questions, ninety seconds, zero forms.
struct OnboardingConversationView: View {
    @Environment(AppModel.self) private var model
    @Binding var values: String
    @Binding var barrier: String
    @Binding var tone: String
    var onDone: () -> Void

    @State private var question = 0
    @State private var shownText = ""
    @State private var input = ""
    @FocusState private var focused: Bool

    private let questions = [
        "If we're going to be friends, I should know — what matters most in your life right now? Not health stuff. Life stuff.",
        "Love that. And what's the part of looking after yourself that just never gets easier?",
        "Last one, promise. How should I talk with you?",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(shownText)
                .font(NudgeType.serif(20, .medium))
                .foregroundStyle(Theme.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 34)
                .animation(nil, value: shownText)

            Spacer()

            if question < 2 {
                HStack(spacing: 10) {
                    TextField("However it comes out is right…", text: $input, axis: .vertical)
                        .font(NudgeType.rounded(15))
                        .lineLimit(1...3)
                        .focused($focused)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 26, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
                        )
                        .onSubmit(submitText)

                    Button(action: submitText) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.base)
                            .frame(width: 46, height: 46)
                            .background(Theme.ink.opacity(input.isEmpty ? 0.35 : 1), in: .circle)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .disabled(input.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            } else {
                VStack(spacing: 11) {
                    toneChoice("Gentle nudges", detail: "Soft suggestions, easy pace, plenty of grace")
                    toneChoice("Straight talk", detail: "Honest and direct — always with warmth")
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .onAppear { streamQuestion() }
    }

    private func toneChoice(_ label: String, detail: String) -> some View {
        Button {
            tone = label
            model.orb.set(.ambient)
            Haptics.glass()
            onDone()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(NudgeType.serif(17))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(NudgeType.rounded(12.5))
                    .foregroundStyle(Theme.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(Theme.surface.opacity(0.95), in: .rect(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
            )
        }
        .buttonStyle(NudgeButtonStyle())
    }

    private func submitText() {
        let answer = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return }
        if question == 0 { values = answer } else { barrier = answer }
        input = ""
        question += 1
        Haptics.tick()
        streamQuestion()
    }

    private func streamQuestion() {
        let full = questions[min(question, questions.count - 1)]
        shownText = ""
        model.orb.set(.speaking)
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            let words = full.split(separator: " ")
            for (index, word) in words.enumerated() {
                shownText += (index == 0 ? "" : " ") + word
                try? await Task.sleep(for: .milliseconds(45))
            }
            model.orb.set(.listening)
        }
    }
}
