import SwiftUI

/// Requests (§4.4.6) — refills, appointments, records copies, and forms, all
/// tracked end to end in one place. Each routes the smart way: a true in-app
/// channel where the practice supports it, otherwise a clean draft for the
/// portal. The user always sees where it went.
struct RequestsView: View {
    @Environment(AppModel.self) private var model
    @State private var composing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requests")
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text("Refills, records, forms — asked once, tracked through.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                Button {
                    Haptics.tick()
                    composing = true
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 18, weight: .light))
                        Text("Start a request").font(NudgeType.rounded(14.5, .semibold))
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .light))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8))
                }
                .buttonStyle(NudgeButtonStyle())

                if model.requests.isEmpty {
                    Text("Nothing in flight right now.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                        .padding(.top, 6)
                } else {
                    ForEach(model.requests) { request in
                        requestRow(request)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $composing) {
            ComposeRequestSheet { kind, subject, detail in
                model.submitRequest(kind: kind, subject: subject, detail: detail,
                                    routedTo: routing(for: kind))
                composing = false
            }
            .presentationDetents([.height(520)])
            .presentationBackground(Theme.base)
        }
    }

    private func requestRow(_ request: CareRequest) -> some View {
        OrganicSurface(radius: 26) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 12) {
                    Image(systemName: request.kind.glyph)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Theme.gold)
                        .frame(width: 38, height: 38)
                        .background(Theme.gold.opacity(0.13), in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.subject)
                            .font(NudgeType.serif(16))
                            .foregroundStyle(Theme.ink)
                        Text(request.detail)
                            .font(NudgeType.rounded(12.5))
                            .foregroundStyle(Theme.inkMuted)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                RequestProgress(state: request.state)
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.right")
                        .font(.system(size: 9, weight: .medium))
                    Text(request.routedTo)
                        .font(NudgeType.rounded(11, .medium))
                    Spacer()
                    Text(request.at.formatted(.dateTime.month().day()))
                        .font(NudgeType.rounded(11))
                }
                .foregroundStyle(Theme.inkMuted)
            }
            .padding(15)
        }
    }

    private func routing(for kind: RequestKind) -> String {
        switch kind {
        case .refill: return "\(model.medications.first?.pharmacy ?? "Your pharmacy") (in-app)"
        case .appointment: return "\(model.persona.officeName) (in-app)"
        case .records: return "Medical records (drafted for portal)"
        case .form: return "\(model.persona.officeName) (in-app)"
        }
    }
}

/// A three-step progress rail for a request's life — submitted, acknowledged,
/// resolved — luminous and calm.
struct RequestProgress: View {
    let state: RequestState
    private var step: Int {
        switch state {
        case .submitted: return 0
        case .acknowledged: return 1
        case .resolved: return 2
        }
    }
    private let labels = ["Submitted", "Acknowledged", "Resolved"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                let active = index <= step
                Capsule()
                    .fill(active ? Theme.life : Theme.base.opacity(0.8))
                    .frame(height: 5)
                    .overlay(alignment: .leading) {
                        if active && index == step {
                            Circle().fill(Theme.life).frame(width: 7, height: 7)
                                .shadow(color: Theme.life.opacity(0.6), radius: 4)
                                .offset(x: -1)
                        }
                    }
            }
        }
        .overlay(alignment: .leading) {
            Text(labels[step])
                .font(NudgeType.rounded(10.5, .semibold))
                .foregroundStyle(Theme.life)
                .offset(y: 13)
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Compose

struct ComposeRequestSheet: View {
    let onSubmit: (RequestKind, String, String) -> Void
    @State private var kind: RequestKind = .refill
    @State private var subject = ""
    @State private var detail = ""
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Start a request")
                    .font(NudgeType.serif(22))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Kicker(text: "What do you need?", color: Theme.gold)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(RequestKind.allCases) { option in
                            let selected = kind == option
                            Button {
                                Haptics.tick()
                                kind = option
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: option.glyph).font(.system(size: 12, weight: .medium))
                                    Text(option.rawValue).font(NudgeType.rounded(13, .medium))
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(selected ? Theme.base : Theme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .background(selected ? Theme.ink : Color.clear, in: .rect(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Theme.edge.opacity(selected ? 0 : 0.7), lineWidth: 0.8))
                            }
                            .buttonStyle(NudgeButtonStyle())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Kicker(text: "Subject", color: Theme.sky)
                    TextField(subjectPlaceholder, text: $subject)
                        .font(NudgeType.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .focused($focused)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Kicker(text: "Anything to add?", color: Theme.life)
                    TextField("Optional detail…", text: $detail, axis: .vertical)
                        .font(NudgeType.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2...4)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
                }

                Button {
                    let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSubmit(kind, trimmedSubject.isEmpty ? kind.rawValue : trimmedSubject,
                             detail.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Text("Send request")
                        .font(NudgeType.rounded(15, .semibold))
                        .foregroundStyle(Theme.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())
                .padding(.top, 2)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear { focused = true }
    }

    private var subjectPlaceholder: String {
        switch kind {
        case .refill: return "Which medication?"
        case .appointment: return "What kind of visit?"
        case .records: return "Which records?"
        case .form: return "Which form?"
        }
    }
}
