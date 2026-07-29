import SwiftUI

/// "Care" — the clinical action center (v5 §4.4). Messages, appointments, the
/// care plan, medications & refills, records, bills, and documents, all drawn
/// from the one data spine. Calm but capable: nothing consequential happens
/// without an explicit, equal-weight tap, and every value carries provenance.
struct CareHubView: View {
    @Environment(AppModel.self) private var model
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LivingGradientView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if !model.needsYou.isEmpty {
                            needsYouSection
                        }

                        surfacesGrid

                        if model.showsLookingAhead, let nudge = model.lookingAhead {
                            LookingAheadCard(nudge: nudge) {
                                model.addGuideItem(kind: .question, text: nudge.guideQuestion,
                                                   from: "A look ahead")
                                path.append(YouDestination.guide)
                            }
                        }

                        ProvenanceChip(text: "One secure place — synced from your providers and plan")
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 132)
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(for: CareDestination.self) { careDestination($0) }
            .navigationDestination(for: YouDestination.self) { youDestination($0) }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { consumePending() }
            .onChange(of: model.pendingCareDestination) { _, _ in consumePending() }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Care")
                .font(NudgeType.serif(32))
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(NudgeType.rounded(14))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
        .padding(.trailing, 52) // clear the global companion orb (top-right)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        switch model.pathway {
        case .metabolic: return "Your team, your plan, and the day-to-day — handled."
        case .oncology: return "Treatment, your team, and the logistics — carried with you."
        case .procedure: return "Getting you to the day ready, and through the other side."
        case .cardiometabolic: return "Three teams, one plan — heart, sugar and kidneys, in sync."
        }
    }

    // MARK: Needs you — the attention band (§3.2, TDY-3)

    private var needsYouSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Kicker(text: "Needs you", color: Theme.warm)
            ForEach(model.needsYou) { item in
                Button {
                    Haptics.tick()
                    SoundEngine.shared.tick()
                    path.append(item.destination)
                } label: {
                    OrganicSurface(radius: 24) {
                        HStack(spacing: 13) {
                            Image(systemName: item.kind.glyph)
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(Theme.warm)
                                .frame(width: 40, height: 40)
                                .background(Theme.warm.opacity(0.13), in: .circle)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(NudgeType.rounded(14.5, .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text(item.detail)
                                    .font(NudgeType.rounded(12.5))
                                    .foregroundStyle(Theme.inkMuted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 6)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .padding(14)
                    }
                }
                .buttonStyle(NudgeButtonStyle())
            }
        }
    }

    // MARK: The surfaces

    private var surfacesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)], spacing: 12) {
            CareTile(glyph: "bubble.left.and.bubble.right", title: "Messages",
                     status: messagesStatus, accent: Theme.sky, badge: unreadCount) {
                path.append(CareDestination.messages)
            }
            CareTile(glyph: "calendar", title: "Appointments",
                     status: appointmentsStatus, accent: Theme.gold) {
                path.append(CareDestination.appointments)
            }
            CareTile(glyph: "list.bullet.clipboard", title: "Care plan",
                     status: "\(model.persona.carePlan.goals.count) goals from your team", accent: Theme.life) {
                path.append(CareDestination.carePlan)
            }
            CareTile(glyph: "pills", title: "Meds & refills",
                     status: medsStatus, accent: Theme.warm) {
                path.append(CareDestination.medications)
            }
            CareTile(glyph: "waveform.path.ecg", title: "Records",
                     status: recordsStatus, accent: Theme.rose,
                     badge: model.resultAcknowledged ? 0 : 1) {
                path.append(CareDestination.records)
            }
            CareTile(glyph: "dollarsign.circle", title: "Bills",
                     status: billsStatus, accent: Theme.gold) {
                path.append(CareDestination.bills)
            }
            CareTile(glyph: "doc.on.doc", title: "Documents",
                     status: "\(model.careDocuments.count) saved", accent: Theme.sky) {
                path.append(CareDestination.documents)
            }
            CareTile(glyph: "checklist", title: "Visit prep",
                     status: prepStatus, accent: Theme.warm) {
                path.append(CareDestination.visitPrep)
            }
            CareTile(glyph: "doc.text", title: "Visit reports",
                     status: reportsStatus, accent: Theme.sky) {
                path.append(CareDestination.reports)
            }
            CareTile(glyph: "creditcard", title: "Wallet",
                     status: walletStatus, accent: Theme.life) {
                path.append(CareDestination.wallet)
            }
            CareTile(glyph: "link", title: "Connections",
                     status: connectionsStatus, accent: Theme.rose) {
                path.append(CareDestination.connections)
            }
        }
    }

    // MARK: Surface status lines

    private var unreadCount: Int { model.threads.filter(\.unread).count }

    private var messagesStatus: String {
        unreadCount > 0 ? "\(unreadCount) waiting for you" : "All caught up"
    }

    private var appointmentsStatus: String {
        let upcoming = model.appointments.filter { $0.date > .now }.min(by: { $0.date < $1.date })
        guard let next = upcoming ?? model.appointments.first else { return "Nothing booked" }
        return "Next \(Self.relativeDay(next.date))"
    }

    private var medsStatus: String {
        let low = model.medications.filter { $0.supplyDaysRemaining <= 7 }.count
        return low > 0 ? "\(low) running low" : "All stocked"
    }

    private var recordsStatus: String {
        if !model.resultAcknowledged, let result = model.resultToAck {
            return "New: \(result.title)"
        }
        return "Up to date"
    }

    private var billsStatus: String {
        let total = model.openBillsTotal
        return total > 0 ? "$\(Int(total)) to review" : "Nothing due"
    }

    private var prepStatus: String {
        model.appointments.contains(where: { $0.prepReady }) ? "Ready for your visit" : "Build your next one"
    }

    private var reportsStatus: String {
        let count = model.careTeam.filter { !$0.role.lowercased().contains("pharmacy") }.count
        return count > 0 ? "\(count) ready to review" : "For your visits"
    }

    private var walletStatus: String {
        model.openBillsTotal > 0 ? "$\(Int(model.openBillsTotal)) ready to pay" : "\(model.walletCards.count) cards on file"
    }

    private var connectionsStatus: String {
        let connected = model.connections.filter(\.connected).count
        return connected > 0 ? "\(connected) connected" : "Bring your world in"
    }

    // MARK: Deep-link from Today's "Needs you"

    private func consumePending() {
        if let destination = model.pendingCareDestination {
            path.append(destination)
            model.pendingCareDestination = nil
        }
    }

    static func relativeDay(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                                   to: Calendar.current.startOfDay(for: date)).day ?? 0
        switch days {
        case ..<0: return "past"
        case 0: return "today"
        case 1: return "tomorrow"
        case 2...6: return date.formatted(.dateTime.weekday(.wide))
        default: return "in \(days) days"
        }
    }

    // MARK: Routing

    @ViewBuilder
    private func careDestination(_ destination: CareDestination) -> some View {
        ZStack {
            LivingGradientView()
            switch destination {
            case .messages: MessagesView()
            case .thread(let id): MessageThreadView(threadID: id)
            case .appointments: AppointmentsView()
            case .appointmentDetail(let id): AppointmentDetailView(appointmentID: id)
            case .trip(let id): TripView(appointmentID: id)
            case .carePlan: CarePlanView()
            case .medications: MedicationsView()
            case .requests: RequestsView()
            case .savings(let medID): SavingsView(medID: medID)
            case .records: RecordsDrawerView()
            case .bills: BillsView()
            case .billDetail(let id): BillDetailView(billID: id)
            case .documents: DocumentsView()
            case .visitPrep: VisitPrepView()
            case .reports: ReportsView()
            case .wallet: WalletView()
            case .connections: ConnectionsView()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    /// Reused "You" surfaces keep their internal links working inside this stack.
    @ViewBuilder
    private func youDestination(_ destination: YouDestination) -> some View {
        ZStack {
            LivingGradientView()
            switch destination {
            case .records: RecordsDrawerView()
            case .category(let category): RecordCategoryView(category: category)
            case .labDetail(let seriesID):
                if let series = model.series(seriesID) { LabDetailView(series: series) }
            case .medications: MedicationsView()
            case .medDetail(let medID):
                if let med = model.medications.first(where: { $0.id == medID }) {
                    MedDetailView(medication: med)
                }
            case .care: CareTeamView()
            case .visitPrep: VisitPrepView()
            case .conditions: ConditionOverviewView()
            case .guide: DiscussionGuideView()
            case .life: LifeCatalogView()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Hub tile

/// One calm door into a Care surface. Icon tile, title, a single live status
/// line, and an optional count — the whole tile is the tap target.
struct CareTile: View {
    let glyph: String
    let title: String
    let status: String
    let accent: Color
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tick()
            SoundEngine.shared.tick()
            action()
        } label: {
            OrganicSurface(radius: 26) {
                VStack(alignment: .leading, spacing: 11) {
                    HStack {
                        Image(systemName: glyph)
                            .font(.system(size: 17, weight: .light))
                            .foregroundStyle(accent)
                            .frame(width: 42, height: 42)
                            .background(accent.opacity(0.14), in: .circle)
                        Spacer()
                        if badge > 0 {
                            Text("\(badge)")
                                .font(NudgeType.number(11, .semibold))
                                .foregroundStyle(Theme.base)
                                .frame(minWidth: 18)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(accent, in: .capsule)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(NudgeType.serif(17))
                            .foregroundStyle(Theme.ink)
                        Text(status)
                            .font(NudgeType.rounded(12))
                            .foregroundStyle(Theme.inkMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                .padding(15)
            }
        }
        .buttonStyle(NudgeButtonStyle())
    }
}

// MARK: - Looking ahead (population-level, route-to-care · §4.10)

/// The only patient-facing expression of the prediction model: a gentle,
/// population-level prompt that routes to a real conversation — never an
/// individual prediction, probability, or date.
struct LookingAheadCard: View {
    let nudge: LookingAheadNudge
    let onAddToGuide: () -> Void

    @State private var showBasis = false
    @State private var added = false

    var body: some View {
        OrganicSurface(radius: 30) {
            VStack(alignment: .leading, spacing: 11) {
                Kicker(text: "A gentle look ahead", color: Theme.sky)
                Text(nudge.headline)
                    .font(NudgeType.serif(19))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(nudge.body)
                    .font(NudgeType.rounded(13.5))
                    .foregroundStyle(Theme.inkMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if showBasis {
                    Text(nudge.basis)
                        .font(NudgeType.rounded(12))
                        .foregroundStyle(Theme.inkMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack(spacing: 10) {
                    if added {
                        Label("Added to your guide", systemImage: "checkmark")
                            .font(NudgeType.rounded(13, .semibold))
                            .foregroundStyle(Theme.life)
                    } else {
                        Button {
                            withAnimation(NudgeSpring.gentle) { added = true }
                            onAddToGuide()
                        } label: {
                            Text("Add to my guide")
                                .font(NudgeType.rounded(13.5, .semibold))
                                .foregroundStyle(Theme.base)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 9)
                                .background(Theme.ink, in: .capsule)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                    Button {
                        withAnimation(NudgeSpring.gentle) { showBasis.toggle() }
                    } label: {
                        Text(showBasis ? "Hide why" : "Why am I seeing this?")
                            .font(NudgeType.rounded(12.5, .medium))
                            .foregroundStyle(Theme.inkMuted)
                            .underline()
                    }
                    .buttonStyle(NudgeButtonStyle())
                }
                .padding(.top, 2)
            }
            .padding(18)
        }
    }
}
