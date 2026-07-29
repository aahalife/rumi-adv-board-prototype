import Foundation

// MARK: - Wallet

enum WalletCardKind: String {
    case hsa, card, insurance

    var label: String {
        switch self {
        case .hsa: return "HSA card"
        case .card: return "Card"
        case .insurance: return "Insurance"
        }
    }
    var glyph: String {
        switch self {
        case .hsa: return "heart.text.square"
        case .card: return "creditcard"
        case .insurance: return "cross.case"
        }
    }
}

/// A payment or coverage card the companion can use — with a one-tap approval.
/// Only a label and last four are ever held; never full card data.
struct WalletCard: Identifiable, Equatable {
    let id: String
    let kind: WalletCardKind
    let name: String
    let issuer: String
    let last4: String
    let accent: AccentKey
    /// HSA/FSA balance hint, when relevant.
    var balanceLine: String? = nil
}

// MARK: - Connections (Google + channels)

enum ConnectionGroup: String {
    case google, channel
}

/// A consumer account the companion can connect to become omnichannel —
/// Gmail and Calendar for context and sending; iMessage/SMS/Instagram so Rumi
/// can reach the user where they already are.
struct Connection: Identifiable, Equatable {
    let id: String
    let name: String
    let group: ConnectionGroup
    let glyph: String
    let detail: String
    let accent: AccentKey
    var connected: Bool = false
    /// The linked handle once connected, e.g. an email or phone.
    var accountLine: String? = nil
    /// What the companion will do once this is connected.
    let enables: String
}

// MARK: - Agent family (the omnichannel care network)

/// One specialized helper in the companion's network. Presented together so the
/// agentic value reads as one cohesive family, not scattered features.
struct AgentService: Identifiable, Equatable {
    let id: String
    let name: String
    let role: String
    let glyph: String
    let accent: AccentKey
    var active: Bool = true
}

// MARK: - Per-doctor summary reports

/// One line in a report — a value and an optional plain context note.
struct ReportLine: Identifiable, Equatable {
    let id = UUID()
    let primary: String
    var secondary: String? = nil
    var emphasis: Bool = false
}

/// A titled block of a report.
struct ReportSection: Identifiable, Equatable {
    enum Kind { case headline, numbers, meds, logging, crossRef, questions }
    let id = UUID()
    let title: String
    let kind: Kind
    let lines: [ReportLine]
}

/// A clean, PDF-style visit summary tailored to one doctor's focus while
/// cross-referencing the rest of the care team — so everyone shares one picture.
struct DoctorReport: Identifiable, Equatable {
    let id: String
    let doctorName: String
    let doctorRole: String
    let org: String
    let title: String
    let focusLine: String
    let preparedLine: String
    let sections: [ReportSection]
}

// MARK: - Fixtures + report builder

enum AgentNetwork {
    static func wallet(for pathway: CarePathway) -> [WalletCard] {
        let insurer: (String, String)
        switch pathway {
        case .metabolic: insurer = ("Anthem Blue Cross", "PPO")
        case .oncology: insurer = ("Aetna", "PPO")
        case .procedure: insurer = ("UnitedHealthcare", "PPO")
        case .cardiometabolic: insurer = ("Cigna", "PPO")
        }
        return [
            WalletCard(id: "hsa", kind: .hsa, name: "HSA card", issuer: "HealthEquity",
                       last4: "4821", accent: .life, balanceLine: "$1,940 available"),
            WalletCard(id: "visa", kind: .card, name: "Visa", issuer: "Personal",
                       last4: "7390", accent: .sky),
            WalletCard(id: "insurance", kind: .insurance, name: insurer.0, issuer: insurer.1,
                       last4: "0142", accent: .gold),
        ]
    }

    static func connections() -> [Connection] {
        [
            Connection(id: "gmail", name: "Gmail", group: .google, glyph: "envelope",
                       detail: "Spot bills, receipts and results in your inbox", accent: .rose,
                       enables: "Rumi can flag a bill or result the moment it lands, and send on your behalf with one tap."),
            Connection(id: "gcal", name: "Google Calendar", group: .google, glyph: "calendar",
                       detail: "Keep visits and reminders in sync", accent: .sky,
                       enables: "New appointments and stop-med reminders drop straight onto your calendar."),
            Connection(id: "imessage", name: "iMessage", group: .channel, glyph: "message",
                       detail: "Gentle nudges and check-ins by text", accent: .life,
                       enables: "Rumi can reach you with a check-in by text, and you can reply back into the app."),
            Connection(id: "sms", name: "SMS", group: .channel, glyph: "bubble.left",
                       detail: "Reminders even without the app open", accent: .gold,
                       enables: "Time-sensitive reminders arrive by text wherever you are."),
            Connection(id: "instagram", name: "Instagram", group: .channel, glyph: "camera",
                       detail: "Your daily 'for you' care content, where you already scroll", accent: .warm,
                       enables: "Your daily Currents pieces can arrive as saved reels — still logged here."),
        ]
    }

    static func agentServices() -> [AgentService] {
        [
            AgentService(id: "risk", name: "Risk watch", role: "Flags possible issues early from your record and history", glyph: "exclamationmark.shield", accent: .warm),
            AgentService(id: "monitor", name: "Continuous monitoring", role: "Notices warning signs across your day-to-day", glyph: "waveform.path.ecg", accent: .sky),
            AgentService(id: "alerts", name: "Alerts & escalation", role: "Routes time-sensitive things to the right person", glyph: "bell.badge", accent: .rose),
            AgentService(id: "scheduling", name: "Smart scheduling", role: "Books and moves visits around your life", glyph: "calendar.badge.clock", accent: .gold),
            AgentService(id: "education", name: "Support & education", role: "A 24/7 voice for questions, coaching and reassurance", glyph: "bubble.left.and.text.bubble.right", accent: .life),
            AgentService(id: "pathway", name: "Care pathway", role: "Walks you through your plan and keeps your team posted", glyph: "map", accent: .sky),
            AgentService(id: "adherence", name: "Medication adherence", role: "Refills, reminders and insurance navigation", glyph: "pills", accent: .warm),
            AgentService(id: "lifestyle", name: "Lifestyle support", role: "Tiny, sustainable habits tuned to your condition", glyph: "leaf", accent: .life),
        ]
    }

    // MARK: Report builder

    static func reports(persona: Persona, careTeam: [CareTeamMember], labSeries: [LabSeries],
                        medications: [Medication], logs: [SymptomLog], guideItems: [GuideItem],
                        entries: [CareEntry], rangeDays: Int) -> [DoctorReport] {
        careTeam
            .filter { !$0.role.lowercased().contains("pharmacy") }
            .map { member in
                build(for: member, team: careTeam, persona: persona, labSeries: labSeries,
                      medications: medications, logs: logs, guideItems: guideItems,
                      entries: entries, rangeDays: rangeDays)
            }
    }

    private static func build(for member: CareTeamMember, team: [CareTeamMember], persona: Persona,
                              labSeries: [LabSeries], medications: [Medication], logs: [SymptomLog],
                              guideItems: [GuideItem], entries: [CareEntry], rangeDays: Int) -> DoctorReport {
        let cutoff = Date(timeIntervalSinceNow: -Double(rangeDays) * 86_400)
        let focus = focusLine(role: member.role)

        // Headline
        let headline = ReportSection(title: "Summary", kind: .headline, lines: [
            ReportLine(primary: "\(persona.firstName) — \(persona.conditionChip).",
                       secondary: "Prepared for \(member.name) (\(member.role)). Centered on \(focus).", emphasis: true),
        ])

        // Numbers — focus-relevant labs first
        let orderedLabs = labSeries.sorted { relevance($0.name, role: member.role) > relevance($1.name, role: member.role) }
        let numberLines = orderedLabs.map { series -> ReportLine in
            let latest = series.points.last
            let trend = trendLine(series)
            return ReportLine(primary: "\(series.name): \(latest.map { format($0.value) } ?? "—") \(series.unit)",
                              secondary: trend)
        }
        let numbers = ReportSection(title: "Your numbers", kind: .numbers, lines: numberLines)

        // Meds + adherence
        let medLines = medications.map { med -> ReportLine in
            let taken = med.adherence30.reduce(0.0, +)
            let pct = Int(taken * 100 / Double(max(1, med.adherence30.count)))
            return ReportLine(primary: "\(med.name) \(med.dose)",
                              secondary: "\(pct)% taken (30d) · \(med.supplyDaysRemaining) days on hand")
        }
        let meds = ReportSection(title: "Medications", kind: .meds, lines: medLines)

        // What's been logged in range
        let rangeLogs = logs.filter { $0.at > cutoff }
        let mealCount = entries.filter { $0.kind == .meal && $0.at > cutoff }.count
        let moveCount = entries.filter { $0.kind == .move && $0.at > cutoff }.count
        var loggingLines: [ReportLine] = []
        let grouped = Dictionary(grouping: rangeLogs, by: { $0.kind })
        for (kind, items) in grouped.sorted(by: { $0.value.count > $1.value.count }) {
            loggingLines.append(ReportLine(primary: "\(kind): \(items.count) log\(items.count == 1 ? "" : "s")",
                                           secondary: severitySummary(items)))
        }
        loggingLines.append(ReportLine(primary: "Daily life", secondary: "\(mealCount) meals and \(moveCount) active sessions logged"))
        let logging = ReportSection(title: "What \(persona.firstName) has been logging", kind: .logging, lines: loggingLines)

        // Cross-reference the rest of the team — the unifying section
        let others = team.filter { $0.id != member.id }
        let crossLines = others.map { other -> ReportLine in
            ReportLine(primary: "\(other.name) · \(other.role)",
                       secondary: crossRefLine(role: other.role))
        }
        let crossRef = ReportSection(title: "From your wider care team", kind: .crossRef, lines: crossLines)

        // Questions for this visit
        let questionLines = guideItems.filter { !$0.resolved }.map { ReportLine(primary: $0.text) }
        let questions = ReportSection(title: "Worth covering this visit", kind: .questions,
                                      lines: questionLines.isEmpty ? [ReportLine(primary: "Nothing flagged — a steady stretch.")] : questionLines)

        var sections = [headline, numbers, meds, logging, crossRef]
        sections.append(questions)

        return DoctorReport(
            id: "\(member.id.uuidString)-\(rangeDays)",
            doctorName: member.name,
            doctorRole: member.role,
            org: member.org,
            title: "\(roleTitle(member.role)) summary",
            focusLine: focus,
            preparedLine: "Prepared from your last \(rangeDays) days · \(Date.now.formatted(.dateTime.month().day().year()))",
            sections: sections
        )
    }

    // MARK: Builder helpers

    private static func roleTitle(_ role: String) -> String {
        let l = role.lowercased()
        if l.contains("primary") { return "Primary care" }
        if l.contains("oncolog") { return "Oncology" }
        if l.contains("nephro") { return "Nephrology" }
        if l.contains("ortho") || l.contains("surg") { return "Surgical" }
        if l.contains("physical") { return "Physical therapy" }
        if l.contains("nurse") || l.contains("navigator") { return "Care navigation" }
        return role
    }

    private static func focusLine(role: String) -> String {
        let l = role.lowercased()
        if l.contains("primary") { return "the whole picture across your specialists" }
        if l.contains("oncolog") { return "chemo tolerance, counts and symptom burden" }
        if l.contains("nephro") { return "kidney function and protective habits" }
        if l.contains("ortho") || l.contains("surg") { return "the procedure, prehab and recovery readiness" }
        if l.contains("physical") { return "mobility, strength and your pain trend" }
        if l.contains("nurse") || l.contains("navigator") { return "how each cycle is landing day to day" }
        if l.contains("cardio") || l.contains("heart") { return "blood pressure and cardiovascular risk" }
        return "your overall progress"
    }

    private static func crossRefLine(role: String) -> String {
        let l = role.lowercased()
        if l.contains("pharmacy") { return "Keeps refills synced and flags interactions." }
        if l.contains("primary") { return "Holds the whole-person view and reconciles every specialist." }
        if l.contains("oncolog") { return "Leads treatment; watching counts and tolerance." }
        if l.contains("nephro") { return "Protecting kidney function alongside the metabolic plan." }
        if l.contains("ortho") || l.contains("surg") { return "Owns the procedure and recovery milestones." }
        if l.contains("physical") { return "Rebuilding strength and range after the procedure." }
        if l.contains("nurse") || l.contains("navigator") { return "Closest to the day-to-day between visits." }
        return "Part of the shared plan."
    }

    private static func relevance(_ name: String, role: String) -> Int {
        let n = name.lowercased(); let r = role.lowercased()
        if r.contains("nephro") && (n.contains("kidney") || n.contains("egfr") || n.contains("creatinine")) { return 3 }
        if (r.contains("primary") || r.contains("endo")) && (n.contains("a1c") || n.contains("glucose") || n.contains("pressure")) { return 3 }
        if r.contains("oncolog") && (n.contains("anc") || n.contains("count") || n.contains("immune")) { return 3 }
        if (r.contains("ortho") || r.contains("physical") || r.contains("surg")) && n.contains("pain") { return 3 }
        return 1
    }

    private static func trendLine(_ series: LabSeries) -> String? {
        guard series.points.count >= 2 else { return series.bandLabel }
        let first = series.points[series.points.count - 2].value
        let last = series.points[series.points.count - 1].value
        if abs(last - first) < 0.0001 { return "holding steady" }
        return last < first ? "down from \(format(first))" : "up from \(format(first))"
    }

    private static func severitySummary(_ logs: [SymptomLog]) -> String? {
        guard !logs.isEmpty else { return nil }
        let avg = logs.map(\.severity).reduce(0, +) / Double(logs.count)
        if avg < 0.35 { return "mostly mild" }
        if avg < 0.65 { return "moderate on average" }
        return "running high — worth a look"
    }

    private static func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
