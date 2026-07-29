import SwiftUI

/// Medication savings (§4.4.7) — copay cards, assistance, cash prices, and
/// lower-cost options. Sponsorship is disclosed but never changes clinical
/// ranking or the neutral answer to "are there other options?" (SAV-4).
/// Applying submits personal info only after an explicit, pre-filled confirm
/// (SAV-3). Rumi never enters or stores payment credentials (SAV-6).
struct SavingsView: View {
    @Environment(AppModel.self) private var model
    /// Empty string means "show every option across medications".
    let medID: String

    @State private var sponsorExplain: String?

    private var options: [MedicationSaving] {
        medID.isEmpty ? model.savings : model.savings(for: medID)
    }

    private var medName: String? {
        model.medications.first { $0.id == medID }?.name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ways to save")
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text(medName.map { "On \($0) — and what else is out there." }
                        ?? "Across your medications — neutral, with the basis shown.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                if options.isEmpty {
                    OrganicSurface(radius: 26) {
                        Text("Nothing to flag right now — you're already on a low-cost option.")
                            .font(NudgeType.rounded(14))
                            .foregroundStyle(Theme.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(17)
                    }
                } else {
                    ForEach(options) { saving in
                        savingCard(saving)
                    }
                }

                OrganicSurface(radius: 24) {
                    HStack(spacing: 11) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Theme.life)
                        Text("These never change which medication is right for you. The clinical answer stays the same — this is only about cost.")
                            .font(NudgeType.rounded(12))
                            .foregroundStyle(Theme.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .alert("How this is supported", isPresented: Binding(
            get: { sponsorExplain != nil },
            set: { if !$0 { sponsorExplain = nil } }
        )) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text(sponsorExplain ?? "")
        }
    }

    private func savingCard(_ saving: MedicationSaving) -> some View {
        OrganicSurface(radius: 28) {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 12) {
                    Image(systemName: saving.kind.glyph)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Theme.gold)
                        .frame(width: 40, height: 40)
                        .background(Theme.gold.opacity(0.13), in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(saving.kind.rawValue)
                            .font(NudgeType.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkMuted)
                        Text(saving.title)
                            .font(NudgeType.serif(16.5))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                Text(saving.estimateLine)
                    .font(NudgeType.serif(19))
                    .foregroundStyle(Theme.life)

                Text(saving.basis)
                    .font(NudgeType.rounded(12))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if let sponsor = saving.sponsor {
                    SponsorChip(sponsor: sponsor) {
                        sponsorExplain = "\(saving.title) is supported by \(sponsor). Support like this can lower your cost, but it never changes which medication your care team recommends, or whether a lower-cost option exists. You'll always see those neutrally."
                    }
                }

                if saving.applied {
                    Label("Applied — savings will show on your next fill", systemImage: "checkmark.seal.fill")
                        .font(NudgeType.rounded(13, .semibold))
                        .foregroundStyle(Theme.life)
                } else {
                    Button {
                        if saving.requiresPII {
                            // Surfaced as a confirm — handled in the alert below via dialog.
                            apply(saving, requiresConfirm: true)
                        } else {
                            apply(saving, requiresConfirm: false)
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: saving.requiresPII ? "person.text.rectangle" : "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text(saving.requiresPII ? "Review & apply" : "Use this")
                                .font(NudgeType.rounded(14, .semibold))
                        }
                        .foregroundStyle(Theme.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.ink, in: .capsule)
                    }
                    .buttonStyle(NudgeButtonStyle())
                    .confirmationDialog(confirmPrompt(saving),
                                        isPresented: confirmBinding(for: saving),
                                        titleVisibility: .visible) {
                        Button("Apply with my details") { model.applySaving(saving.id) }
                        Button("Not now", role: .cancel) { pendingConfirmID = nil }
                    }
                }
            }
            .padding(16)
        }
    }

    // A single pending-confirm id keeps the PII confirm scoped per card.
    @State private var pendingConfirmID: UUID?

    private func apply(_ saving: MedicationSaving, requiresConfirm: Bool) {
        if requiresConfirm {
            pendingConfirmID = saving.id
        } else {
            model.applySaving(saving.id)
        }
    }

    private func confirmBinding(for saving: MedicationSaving) -> Binding<Bool> {
        Binding(get: { pendingConfirmID == saving.id },
                set: { if !$0 { pendingConfirmID = nil } })
    }

    private func confirmPrompt(_ saving: MedicationSaving) -> String {
        "Apply \(saving.title)? This shares your name and date of birth with the program to check eligibility. Nothing is submitted until you tap below, and Rumi never enters payment details."
    }
}
