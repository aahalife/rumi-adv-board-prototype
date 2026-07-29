import SwiftUI

/// Bills & costs (§4.4.9) — the statement in plain language, what counts as
/// "yours" and why, and where you stand on the deductible. The app prepares and
/// routes; the user always authorizes payment. Rumi never stores card details.
struct BillsView: View {
    @Environment(AppModel.self) private var model

    private var openBills: [Bill] { model.bills.filter { $0.status != .paid } }
    private var settledBills: [Bill] { model.bills.filter { $0.status == .paid } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bills & costs")
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text("What you owe, what's covered, and why — no surprises.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                costCard

                if !openBills.isEmpty {
                    Text("Worth a look")
                        .font(NudgeType.serif(19))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 2)
                    ForEach(openBills) { bill in
                        NavigationLink(value: CareDestination.billDetail(bill.id)) {
                            billRow(bill)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }

                if !settledBills.isEmpty {
                    Text("Settled")
                        .font(NudgeType.serif(19))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 4)
                    ForEach(settledBills) { bill in
                        NavigationLink(value: CareDestination.billDetail(bill.id)) {
                            billRow(bill)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var costCard: some View {
        let cost = model.cost
        return OrganicSurface(radius: 30) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Kicker(text: "This year so far", color: Theme.sky)
                    Spacer()
                    Text(cost.planName)
                        .font(NudgeType.rounded(11.5, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                ProgressBar(label: "Deductible", met: cost.deductibleMet,
                            total: cost.deductibleTotal, tint: Theme.gold)
                ProgressBar(label: "Out-of-pocket max", met: cost.oopMet,
                            total: cost.oopTotal, tint: Theme.life)

                if let estimate = cost.upcomingEstimate, let label = cost.upcomingLabel {
                    Divider().overlay(Theme.edge.opacity(0.5))
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(label)
                                .font(NudgeType.rounded(12.5))
                                .foregroundStyle(Theme.inkMuted)
                            Text("Estimate")
                                .font(NudgeType.rounded(10.5, .medium))
                                .foregroundStyle(Theme.attention)
                        }
                        Spacer()
                        Text("$\(Int(estimate))")
                            .font(NudgeType.number(20, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
            .padding(18)
        }
    }

    private func billRow(_ bill: Bill) -> some View {
        OrganicSurface(radius: 26) {
            HStack(spacing: 13) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(bill.provider)
                        .font(NudgeType.serif(16.5))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(bill.encounter)
                        .font(NudgeType.rounded(12))
                        .foregroundStyle(Theme.inkMuted)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        BillStatusChip(status: bill.status)
                        if bill.flag != nil {
                            HStack(spacing: 3) {
                                Image(systemName: "exclamationmark.bubble")
                                    .font(.system(size: 8.5, weight: .semibold))
                                Text("Worth checking")
                                    .font(NudgeType.rounded(10.5, .medium))
                            }
                            .foregroundStyle(Theme.attention)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.attention.opacity(0.12), in: .capsule)
                        }
                    }
                    .padding(.top, 1)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(bill.status == .paid ? "$0" : "$\(Int(bill.amount))")
                        .font(NudgeType.number(18, .semibold))
                        .foregroundStyle(bill.status == .paid ? Theme.inkMuted : Theme.ink)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Theme.inkMuted)
                }
            }
            .padding(15)
        }
    }
}

struct BillStatusChip: View {
    let status: BillStatus
    private var color: Color {
        switch status {
        case .open: return Theme.attention
        case .paid: return Theme.life
        case .inDispute: return Theme.sky
        }
    }
    var body: some View {
        Text(status.label)
            .font(NudgeType.rounded(10.5, .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: .capsule)
    }
}

/// A soft progress bar for deductible / out-of-pocket — luminous, never red.
struct ProgressBar: View {
    let label: String
    let met: Double
    let total: Double
    let tint: Color

    private var fraction: Double { total > 0 ? min(1, met / total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(NudgeType.rounded(13, .medium))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                Spacer()
                Text("$\(Int(met)) of $\(Int(total))")
                    .font(NudgeType.number(12))
                    .foregroundStyle(Theme.inkMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.base.opacity(0.8))
                    Capsule()
                        .fill(LinearGradient(colors: [tint.opacity(0.85), tint],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(10, geo.size.width * fraction))
                        .shadow(color: tint.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 9)
        }
    }
}

// MARK: - Detail

/// One statement, fully explained — the companion's plain-language read, the
/// line items with why-you-owe, any likely billing error flagged, and the
/// honest path to settle it.
struct BillDetailView: View {
    @Environment(AppModel.self) private var model
    let billID: UUID

    @State private var confirmingPaid = false
    @State private var payingFromWallet = false

    private var bill: Bill? { model.bills.first { $0.id == billID } }

    var body: some View {
        Group {
            if let bill {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(bill)
                        summaryCard(bill)
                        if let flag = bill.flag { flagCard(flag) }
                        lineItemsCard(bill)
                        if bill.status != .paid { payActions(bill) }
                        ProvenanceChip(text: bill.source)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            } else {
                ContentUnavailableView("This bill isn't available", systemImage: "dollarsign.circle")
            }
        }
    }

    private func header(_ bill: Bill) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BillStatusChip(status: bill.status)
            Text(bill.provider)
                .font(NudgeType.serif(26))
                .foregroundStyle(Theme.ink)
            Text(bill.encounter)
                .font(NudgeType.rounded(13))
                .foregroundStyle(Theme.inkMuted)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(bill.status == .paid ? "$0" : "$\(Int(bill.amount))")
                    .font(NudgeType.serif(38))
                    .foregroundStyle(Theme.ink)
                Text(bill.status == .paid ? "settled" : "your share")
                    .font(NudgeType.rounded(13))
                    .foregroundStyle(Theme.inkMuted)
            }
            if let due = bill.dueDate, bill.status != .paid {
                Label("Due \(due.formatted(.dateTime.month(.wide).day()))", systemImage: "calendar")
                    .font(NudgeType.rounded(12.5, .medium))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryCard(_ bill: Bill) -> some View {
        OrganicSurface(radius: 28) {
            HStack(alignment: .top, spacing: 12) {
                OrbView(size: 30, state: model.orb)
                VStack(alignment: .leading, spacing: 4) {
                    Kicker(text: "In plain words", color: Theme.warm)
                    Text(bill.plainSummary)
                        .font(NudgeType.rounded(14))
                        .foregroundStyle(Theme.ink.opacity(0.9))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(17)
        }
    }

    private func flagCard(_ flag: String) -> some View {
        OrganicSurface(radius: 26) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.magnifyingglass")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Theme.attention)
                    .frame(width: 38, height: 38)
                    .background(Theme.attention.opacity(0.13), in: .circle)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Worth a closer look")
                        .font(NudgeType.rounded(13.5, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(flag)
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(15)
        }
    }

    private func lineItemsCard(_ bill: Bill) -> some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: "The breakdown", color: Theme.sky)
                ForEach(bill.lineItems) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(item.label)
                                .font(NudgeType.rounded(14, .medium))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("$\(Int(item.youOwe))")
                                .font(NudgeType.number(15, .semibold))
                                .foregroundStyle(item.youOwe > 0 ? Theme.ink : Theme.life)
                        }
                        HStack(spacing: 8) {
                            Text("Billed $\(Int(item.billed))")
                            Text("·")
                            Text("Plan paid $\(Int(item.planPaid))")
                        }
                        .font(NudgeType.rounded(11.5))
                        .foregroundStyle(Theme.inkMuted)
                        Text(item.reason)
                            .font(NudgeType.rounded(11.5, .medium))
                            .foregroundStyle(Theme.inkMuted)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Theme.base.opacity(0.7), in: .capsule)
                    }
                    if item.id != bill.lineItems.last?.id {
                        Divider().overlay(Theme.edge.opacity(0.4))
                    }
                }
            }
            .padding(17)
        }
    }

    private func payActions(_ bill: Bill) -> some View {
        VStack(spacing: 10) {
            // The agentic path — one tap, Rumi pays it from a card you pick.
            Button {
                Haptics.tick()
                payingFromWallet = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles").font(.system(size: 13, weight: .semibold))
                    Text("Pay $\(Int(bill.amount)) from your wallet").font(NudgeType.rounded(15, .semibold))
                }
                .foregroundStyle(Theme.base)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.ink, in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())
            .confirmationDialog("Pay $\(Int(bill.amount)) to \(bill.provider)?",
                                isPresented: $payingFromWallet, titleVisibility: .visible) {
                ForEach(model.walletCards) { card in
                    Button("\(card.name) •••• \(card.last4)\(card.balanceLine.map { " — \($0)" } ?? "")") {
                        model.payBill(bill.id, with: card)
                    }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Rumi will pay this from the card you choose and file the receipt. You approve the card right here.")
            }

            Button {
                Haptics.tick()
                if let url = URL(string: "https://pay.example/\(bill.key)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Pay on the provider's secure page instead")
                    .font(NudgeType.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: .capsule)
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8))
            }
            .buttonStyle(NudgeButtonStyle())

            Button {
                Haptics.tick()
                confirmingPaid = true
            } label: {
                Text("I've already paid this")
                    .font(NudgeType.rounded(13, .medium))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(NudgeButtonStyle())
            .confirmationDialog("Mark this bill as paid?",
                                isPresented: $confirmingPaid, titleVisibility: .visible) {
                Button("Mark as paid") { model.markBillPaid(bill.id) }
                Button("Not yet", role: .cancel) {}
            }

            Text("Rumi keeps only a label and the last four digits, and asks before every payment.")
                .font(NudgeType.rounded(11))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
    }
}
