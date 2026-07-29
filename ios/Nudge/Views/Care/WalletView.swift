import SwiftUI

/// Wallet — the cards the companion can use, with a one-tap approval each time.
/// Only a label and last four live here; full card data never touches the app.
/// This is where the agentic bill-pay draws from.
struct WalletView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(spacing: 14) {
                    ForEach(model.walletCards) { card in
                        WalletCardView(card: card)
                    }
                }

                if model.openBillsTotal > 0 {
                    openBillsCard
                }

                OrganicSurface(radius: 22) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Theme.life)
                        Text("Rumi only keeps a label and the last four digits. It asks before every payment.")
                            .font(NudgeType.rounded(12.5))
                            .foregroundStyle(Theme.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Wallet")
                .font(NudgeType.serif(30))
                .foregroundStyle(Theme.ink)
            Text("Cards on file for bills and copays — used only with your tap.")
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.trailing, 40)
    }

    private var openBillsCard: some View {
        OrganicSurface(radius: 26) {
            VStack(alignment: .leading, spacing: 10) {
                Kicker(text: "Waiting to pay", color: Theme.warm)
                ForEach(model.bills.filter { $0.status == .open }) { bill in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(bill.provider)
                                .font(NudgeType.rounded(14, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(bill.encounter)
                                .font(NudgeType.rounded(11.5))
                                .foregroundStyle(Theme.inkMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("$\(Int(bill.amount))")
                            .font(NudgeType.number(16, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                }
                Text("Open a bill to pay it from a card here.")
                    .font(NudgeType.rounded(12))
                    .foregroundStyle(Theme.inkMuted)
            }
            .padding(16)
        }
    }
}

/// A single card — a soft, dimensional tile in the card's accent.
struct WalletCardView: View {
    let card: WalletCard

    private var accent: Color {
        switch card.accent {
        case .warm: return Theme.warm
        case .life: return Theme.life
        case .sky: return Theme.sky
        case .gold: return Theme.gold
        case .rose: return Theme.rose
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.55)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
                )
                .shadow(color: accent.opacity(0.35), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: card.kind.glyph)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(card.kind.label.uppercased())
                        .font(NudgeType.kicker())
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Text(card.name)
                    .font(NudgeType.serif(19))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Text("•••• \(card.last4)")
                        .font(NudgeType.number(13, .medium))
                        .foregroundStyle(.white.opacity(0.92))
                    Text(card.issuer)
                        .font(NudgeType.rounded(11.5, .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    if let balance = card.balanceLine {
                        Text(balance)
                            .font(NudgeType.rounded(11.5, .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.18), in: .capsule)
                    }
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
        .frame(height: 132)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.name), ending \(card.last4)\(card.balanceLine.map { ", \($0)" } ?? "")")
    }
}
