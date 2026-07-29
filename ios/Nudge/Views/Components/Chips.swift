import SwiftUI

/// Provenance chip — every clinical statement carries one. Trust is a design
/// primitive, rendered beautifully, never as legal lint.
struct ProvenanceChip: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(NudgeType.rounded(11, .medium))
                .lineLimit(2)
        }
        .foregroundStyle(Theme.inkMuted)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8))
    }
}

/// Quiet glass sponsorship disclosure — tap for plain-language explanation.
struct SponsorChip: View {
    let sponsor: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10, weight: .medium))
                Text("Supported by \(sponsor)")
                    .font(NudgeType.rounded(11, .medium))
            }
            .foregroundStyle(Theme.inkMuted)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: .capsule)
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8))
        }
        .buttonStyle(NudgeButtonStyle())
    }
}

/// Sync freshness state per source.
struct FreshnessChip: View {
    let date: Date

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Theme.life)
                .frame(width: 5, height: 5)
            Text(relative)
                .font(NudgeType.rounded(11, .medium))
                .foregroundStyle(Theme.inkMuted)
        }
    }

    private var relative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

/// Small caps kicker label.
struct Kicker: View {
    let text: String
    var color: Color = Theme.inkMuted

    var body: some View {
        Text(text.uppercased())
            .font(NudgeType.kicker())
            .tracking(1.6)
            .foregroundStyle(color)
    }
}
