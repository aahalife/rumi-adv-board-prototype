import SwiftUI

/// Visit reports — the companion prepares a clean, tailored summary for each
/// doctor on the care team, built from the user's own data over a chosen window.
/// Each report leads with that doctor's focus yet cross-references the rest of
/// the team, so everyone shares one picture. Nothing sends without a review.
struct ReportsView: View {
    @Environment(AppModel.self) private var model
    @State private var rangeDays = 30
    @State private var selected: DoctorReport? = nil

    private let ranges = [30, 60, 90]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                rangePicker

                ForEach(reports) { report in
                    Button {
                        Haptics.glass()
                        SoundEngine.shared.glass()
                        selected = report
                    } label: {
                        ReportCard(report: report, sent: model.reportSent(report))
                    }
                    .buttonStyle(NudgeButtonStyle())
                }

                if reports.isEmpty {
                    emptyState
                }

                ProvenanceChip(text: "Drafted from your record — you review and approve before anything sends")
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selected) { report in
            ReportDetailView(report: report)
                .presentationBackground(Theme.base)
                .presentationContentInteraction(.scrolls)
        }
    }

    private var reports: [DoctorReport] { model.reports(rangeDays: rangeDays) }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Visit reports")
                .font(NudgeType.serif(30))
                .foregroundStyle(Theme.ink)
            Text("A clear summary for each doctor — tailored to them, shared across the team.")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.trailing, 40)
    }

    private var rangePicker: some View {
        HStack(spacing: 8) {
            Text("Window")
                .font(NudgeType.rounded(12.5, .medium))
                .foregroundStyle(Theme.inkMuted)
            ForEach(ranges, id: \.self) { days in
                let active = rangeDays == days
                Button {
                    Haptics.tick()
                    withAnimation(NudgeSpring.ui) { rangeDays = days }
                } label: {
                    Text("\(days) days")
                        .font(NudgeType.rounded(12.5, active ? .semibold : .medium))
                        .foregroundStyle(active ? Theme.ink : Theme.inkMuted)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .capsuleGlass(tint: active ? Theme.warm : nil)
                }
                .buttonStyle(NudgeButtonStyle())
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        OrganicSurface(radius: 26) {
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Theme.sky)
                Text("Your care team will appear here as visit reports.")
                    .font(NudgeType.rounded(13.5))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
        }
    }
}

/// A summary card per doctor on the reports list.
struct ReportCard: View {
    let report: DoctorReport
    let sent: Bool

    var body: some View {
        OrganicSurface(radius: 26) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Theme.sky)
                        .frame(width: 42, height: 42)
                        .background(Theme.sky.opacity(0.14), in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.doctorName)
                            .font(NudgeType.serif(17))
                            .foregroundStyle(Theme.ink)
                        Text(report.doctorRole)
                            .font(NudgeType.rounded(12))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    Spacer()
                    if sent {
                        Label("Sent", systemImage: "checkmark.seal.fill")
                            .font(NudgeType.rounded(11.5, .semibold))
                            .foregroundStyle(Theme.life)
                    }
                }
                Text("Leads with \(report.focusLine).")
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(report.preparedLine)
                        .font(NudgeType.rounded(11))
                        .foregroundStyle(Theme.inkMuted)
                    Spacer()
                    Text("Review")
                        .font(NudgeType.rounded(12.5, .semibold))
                        .foregroundStyle(Theme.warm)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.warm)
                }
            }
            .padding(16)
        }
    }
}

/// The report itself — a calm, PDF-style document the user can read top to
/// bottom, then approve and send with one tap.
struct ReportDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let report: DoctorReport

    @State private var confirming = false

    private var sent: Bool { model.reportSent(report) }

    var body: some View {
        ZStack {
            LivingGradientView()

            VStack(spacing: 0) {
                grabber
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        page
                    }
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }

            VStack {
                Spacer()
                sendBar
            }
        }
    }

    private var grabber: some View {
        Capsule().fill(Theme.inkMuted.opacity(0.3))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    /// The "paper" — a soft document sheet floating on the canvas.
    private var page: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(report.title.uppercased())
                    .font(NudgeType.kicker())
                    .tracking(1.6)
                    .foregroundStyle(Theme.warm)
                Text("For \(report.doctorName)")
                    .font(NudgeType.display(26))
                    .foregroundStyle(Theme.ink)
                Text("\(report.doctorRole) · \(report.org)")
                    .font(NudgeType.rounded(12.5, .medium))
                    .foregroundStyle(Theme.inkMuted)
                Text(report.preparedLine)
                    .font(NudgeType.rounded(11.5))
                    .foregroundStyle(Theme.inkMuted)
            }

            Divider().overlay(Theme.edge)

            ForEach(report.sections) { section in
                sectionView(section)
            }
        }
        .padding(22)
        .background(Theme.surface.opacity(0.96), in: .rect(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9)
        )
        .shadow(color: Theme.shadow.opacity(0.16), radius: 24, y: 10)
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    private func sectionView(_ section: ReportSection) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(section.title)
                .font(NudgeType.serif(17))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: section.kind == .headline ? 6 : 9) {
                ForEach(section.lines) { line in
                    lineView(line, kind: section.kind)
                }
            }
        }
    }

    @ViewBuilder
    private func lineView(_ line: ReportLine, kind: ReportSection.Kind) -> some View {
        if kind == .headline {
            VStack(alignment: .leading, spacing: 4) {
                Text(line.primary)
                    .font(NudgeType.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let secondary = line.secondary {
                    Text(secondary)
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(accent(for: kind).opacity(0.55))
                    .frame(width: 5, height: 5)
                    .padding(.top, 7)
                VStack(alignment: .leading, spacing: 1) {
                    Text(line.primary)
                        .font(NudgeType.rounded(13.5, .medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let secondary = line.secondary {
                        Text(secondary)
                            .font(NudgeType.rounded(12))
                            .foregroundStyle(Theme.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func accent(for kind: ReportSection.Kind) -> Color {
        switch kind {
        case .numbers: return Theme.sky
        case .meds: return Theme.warm
        case .logging: return Theme.life
        case .crossRef: return Theme.gold
        case .questions: return Theme.rose
        case .headline: return Theme.ink
        }
    }

    private var sendBar: some View {
        VStack(spacing: 8) {
            if sent {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.life)
                    Text("Sent to \(report.doctorName)")
                        .font(NudgeType.rounded(14, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: .capsule)
            } else {
                Button {
                    confirming = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Review & send to \(report.doctorName)")
                    }
                    .font(NudgeType.rounded(15, .semibold))
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())
                .confirmationDialog("Send this summary to \(report.doctorName)?",
                                    isPresented: $confirming, titleVisibility: .visible) {
                    Button("Send it") {
                        model.sendReport(report)
                    }
                    Button("Not yet", role: .cancel) {}
                } message: {
                    Text("They'll have your \(report.title.lowercased()) before your visit. Nothing else leaves your phone.")
                }

                Text("Nothing sends without you")
                    .font(NudgeType.rounded(11, .medium))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .padding(.top, 10)
        .background(
            LinearGradient(colors: [Theme.base.opacity(0), Theme.base.opacity(0.85), Theme.base],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}
