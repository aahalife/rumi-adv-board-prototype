import Foundation

// MARK: - Agent activity: what each helper is actually doing

/// How a piece of an agent's work runs — quietly on its own, or held for one
/// human tap. This distinction is the heart of trust: Rumi shows exactly what
/// it will do, runs the safe things itself, and asks before anything that
/// leaves the phone or touches the care team.
enum AgentTaskMode: String {
    case automatic       // Rumi handles it
    case needsApproval   // waiting for your okay

    var label: String {
        switch self {
        case .automatic: return "Automatic"
        case .needsApproval: return "Needs your ok"
        }
    }
}

/// Where a single task sits in its life.
enum AgentTaskStatus: String {
    case working    // in motion right now
    case waiting    // needs the user's approval
    case scheduled  // queued for a moment that hasn't come yet
    case done       // finished
}

/// A source the agents read from. When it maps to a linkable account it carries
/// that connection's id, so the UI can show whether it's live or still an
/// invitation to connect — the visible thread between data and action.
struct AgentSource: Identifiable, Equatable {
    var id: String { label }
    let label: String
    /// Ties to a `Connection.id` when this is a linkable account; nil means it's
    /// always-on (your record, Apple Health, your pharmacy).
    let connectionID: String?

    init(_ label: String, _ connectionID: String? = nil) {
        self.label = label
        self.connectionID = connectionID
    }
}

/// One concrete thing a specific agent is doing — drawing on the connected
/// sources, with empathetic, plain-spoken copy. This is what turns "a family of
/// helpers" into a visibly working machine: each agent has real work, and you
/// can see what it's touching and why.
struct AgentTask: Identifiable, Equatable {
    let id: String
    /// Ties to `AgentService.id`.
    let agentID: String
    var title: String
    var detail: String
    var mode: AgentTaskMode
    var status: AgentTaskStatus
    var sources: [AgentSource]
    /// Human cadence — "every morning", "before June 24", "just now".
    var cadence: String
    /// What lands when it's done or approved.
    var outcomeLine: String
}

// MARK: - Seeds

extension AgentNetwork {

    /// The live work of the agent network, per pathway. A mix of quiet automatic
    /// work and a few things genuinely worth a tap — each one referencing the
    /// data it acts on, so the whole thing reads like one well-oiled machine.
    static func agentTasks(for pathway: CarePathway) -> [AgentTask] {
        switch pathway {
        case .metabolic: return metabolicTasks
        case .oncology: return oncologyTasks
        case .procedure: return procedureTasks
        case .cardiometabolic: return cardiometabolicTasks
        }
    }

    // Shared source shorthands
    private static let sRecord = AgentSource("Your record")
    private static let sHealth = AgentSource("Apple Health")
    private static let sLogs = AgentSource("Your logs")
    private static let sPharmacy = AgentSource("Your pharmacy")
    private static let sGmail = AgentSource("Gmail", "gmail")
    private static let sCalendar = AgentSource("Google Calendar", "gcal")
    private static let sInstagram = AgentSource("Instagram", "instagram")

    private static func t(_ id: String, _ agent: String, _ title: String, _ detail: String,
                          _ mode: AgentTaskMode, _ status: AgentTaskStatus,
                          _ sources: [AgentSource], _ cadence: String, _ outcome: String) -> AgentTask {
        AgentTask(id: id, agentID: agent, title: title, detail: detail, mode: mode,
                  status: status, sources: sources, cadence: cadence, outcomeLine: outcome)
    }

    // MARK: Marcus · metabolic

    private static var metabolicTasks: [AgentTask] {
        [
            t("m-risk-1", "risk", "Watching your kidney trend",
              "Your eGFR has held at stage 2 for a year. I read every new panel the moment it lands — and your blood pressure right alongside it — so a real drift never sneaks up.",
              .automatic, .working, [sRecord, sHealth], "Always on",
              "I'll flag the first true change, gently."),
            t("m-mon-1", "monitor", "Reading your morning BP",
              "Each home-cuff reading syncs straight to me. I'm tracking the slow drift toward your calm zone — and how a night-shift week bends it.",
              .automatic, .working, [sHealth], "Every morning",
              "A heads-up only when a week runs high."),
            t("m-mon-2", "monitor", "The late-statin cramp pattern",
              "I'm holding your atorvastatin dose times against your cramp logs. It's clustered 4 of 5 times — already drafted as a question for Dr. Patterson.",
              .automatic, .working, [sLogs], "Ongoing",
              "Caught, so you don't have to remember it."),
            t("m-adh-1", "adherence", "Your statin is low — delivery's ready",
              "Five days left at CVS Peachtree. I can switch Thursday's refill to free delivery so it simply arrives — no errand.",
              .needsApproval, .waiting, [sPharmacy, sGmail], "By Thursday",
              "Done — it lands Thursday afternoon."),
            t("m-adh-2", "adherence", "Folding three refills into one day",
              "Metformin, lisinopril and the statin have drifted apart. I'm lining them up to a single monthly pickup.",
              .automatic, .working, [sPharmacy], "This month",
              "One trip instead of three."),
            t("m-sch-1", "scheduling", "Holding a lab slot before June 24",
              "Your A1c and kidney panel are due. I'm holding an early-morning draw so the results beat your visit with Dr. Patterson.",
              .needsApproval, .waiting, [sCalendar], "Before June 24",
              "Booked — and on your calendar."),
            t("m-alert-1", "alerts", "Routing anything urgent, the right way",
              "If a reading or result crosses a line, I send it to the right person and keep nudging until it's truly seen.",
              .automatic, .working, [sRecord, sHealth], "Always on",
              "You'll never have to chase it."),
            t("m-edu-1", "education", "Curating your 'for you' shelf",
              "I pick the few pieces most worth your minutes this week — the evening walk, the salt hiding in Sunday — and skip the noise.",
              .automatic, .working, [sLogs, sInstagram], "Daily",
              "A short, kind shelf — never a feed."),
            t("m-path-1", "pathway", "Keeping Dr. Patterson's chart current",
              "Between visits I keep your trends and open questions tidy, so each appointment starts where the last one left off.",
              .automatic, .working, [sRecord], "Ongoing",
              "Your team always has the latest picture."),
            t("m-life-1", "lifestyle", "Guarding your after-dinner walk",
              "On quiet nights I nudge the 15 minutes; on Braves nights I move it earlier so it still happens.",
              .automatic, .working, [sCalendar], "Most evenings",
              "The streak keeps itself."),
        ]
    }

    // MARK: Elena · oncology

    private static var oncologyTasks: [AgentTask] {
        [
            t("o-alert-1", "alerts", "The fever rule, always armed",
              "100.4°F or higher is a call-now, any hour. If you log a fever, I open the line to Dr. Rivera's team and stay with you through the call.",
              .automatic, .working, [sLogs], "Always on",
              "Never sat on, never missed."),
            t("o-mon-1", "monitor", "Watching your low-count window",
              "I know your counts dip days 7–10. I'm counting you into that window now, so the small-crowds, good-handwashing week starts on time.",
              .automatic, .working, [sRecord, sLogs], "This cycle",
              "A gentle nudge the day it opens."),
            t("o-risk-1", "risk", "Tracking the fingertip tingling",
              "Neuropathy is the thing taxane dosing turns on. I'm logging when and how strong, so Dr. Rivera has the real picture before cycle 4.",
              .automatic, .working, [sLogs], "Ongoing",
              "Every note shapes the next dose."),
            t("o-sch-1", "scheduling", "Carrying cycle 3's plan into cycle 4",
              "Your smoothest cycle yet ran on a scheduled anti-nausea plan. I've queued the same for the 22nd — your team just signs off.",
              .needsApproval, .waiting, [sRecord], "Before June 22",
              "Drafted and ready for their ok."),
            t("o-adh-1", "adherence", "Pre-staging your infusion meds",
              "Ondansetron and dexamethasone are stocked at Northside ahead of cycle 4. I'm keeping the timing card ready for day one.",
              .automatic, .working, [sPharmacy], "Before cycle 4",
              "Nothing to pick up, nothing to forget."),
            t("o-sch-2", "scheduling", "A ride home after infusion",
              "You shouldn't drive after the 22nd. Connect your calendar and I'll line up a ride and hold the afternoon clear.",
              .needsApproval, .waiting, [sCalendar], "June 22",
              "A ride confirmed, the day kept gentle."),
            t("o-edu-1", "education", "Good-window living, queued",
              "For days 10–21 I'm gathering the things that make you feel like you — not chores, the living. Yours to spend.",
              .automatic, .working, [sLogs, sInstagram], "Each cycle",
              "The good window, planned for joy."),
            t("o-path-1", "pathway", "Keeping your team in rhythm",
              "Oncology, your infusion nurse, pharmacy — I keep each cycle's notes flowing between them so nothing repeats and nothing drops.",
              .automatic, .working, [sRecord], "Ongoing",
              "One picture, every visit."),
            t("o-life-1", "lifestyle", "Hydration that does the heavy lifting",
              "Eight glasses on infusion days eases almost everything. I count quietly and only mention it when it helps.",
              .automatic, .working, [sHealth, sLogs], "Infusion weeks",
              "Softer days, fewer rough ones."),
        ]
    }

    // MARK: Sam · procedure

    private static var procedureTasks: [AgentTask] {
        [
            t("p-alert-1", "alerts", "The NSAID stop, locked to June 16",
              "Ibuprofen and friends thin the blood around surgery. I'll catch you the evening of the 15th — and watch for any that slip into your logs.",
              .automatic, .working, [sLogs], "Until June 16",
              "The hard rule, kept for you."),
            t("p-mon-1", "monitor", "Reading your prehab pain trend",
              "Evenings have drifted from 6s to 4s on quad-set days. I'm charting it so the pre-op visit opens with proof the plan's working.",
              .automatic, .working, [sLogs], "Daily",
              "A trend, ready to show Dr. Chen."),
            t("p-sch-1", "scheduling", "Booking your first PT within a week",
              "Recovery lives in physical therapy. I'm holding a post-op slot with Priya so week one doesn't slip.",
              .needsApproval, .waiting, [sCalendar], "After June 23",
              "First session locked before you're home."),
            t("p-sch-2", "scheduling", "Moving your June 23 work call",
              "Your calendar shows a 5pm call the day of surgery — you'll be recovering. I can move it and protect the day.",
              .needsApproval, .waiting, [sCalendar], "June 23",
              "Cleared, with a kind note sent."),
            t("p-risk-1", "risk", "Watching the week-one clot signs",
              "Calf pain, one-sided swelling, shortness of breath. I keep these few specifics close so a real one becomes a call-now, fast.",
              .automatic, .working, [sLogs], "Weeks 1–2 after",
              "The few that matter, never missed."),
            t("p-adh-1", "adherence", "Acetaminophen stocked, the safe one",
              "Your green-lit option is in at Walgreens, and the post-op script is set for surgery day. I'm keeping the timing simple.",
              .automatic, .working, [sPharmacy], "Through recovery",
              "The right pill, ready when you need it."),
            t("p-life-1", "lifestyle", "Readying the home for after",
              "Ice packs, clear walkways, the raised seat. I'm pacing one readiness item a day so future-you arrives to a kind house.",
              .automatic, .working, [sLogs], "Until surgery",
              "Home, ready before you are."),
            t("p-path-1", "pathway", "Bridging surgery to rehab",
              "Dr. Chen's team and Priya's rehab don't share a chart — so I do. Your prehab trend travels with you to week one.",
              .automatic, .working, [sRecord], "Ongoing",
              "No detail lost in the handoff."),
            t("p-edu-1", "education", "Week-one expectations, in plain words",
              "I'm cueing up the honest version — swelling that travels, the wins that look like shuffles — so nothing surprises you.",
              .automatic, .working, [sInstagram], "Before surgery",
              "Calm, because you knew it was coming."),
        ]
    }

    // MARK: Rosa · cardiometabolic (diabetes + heart + kidney risk)

    private static var cardiometabolicTasks: [AgentTask] {
        [
            t("c-risk-1", "risk", "Watching your kidney risk early",
              "Your pattern points to early kidney strain. I track eGFR, weight and pressure together — the three that move first — so we act early, never late.",
              .automatic, .working, [sRecord, sHealth], "Always on",
              "You'll hear it from me before it's a problem."),
            t("c-risk-2", "risk", "Worth looping in nephrology now",
              "Yours is the pattern kidney doctors like to see early, not late. I've drafted a referral note to Dr. Okafor for you to review.",
              .needsApproval, .waiting, [sRecord], "When you're ready",
              "Sent the moment you say go."),
            t("c-mon-1", "monitor", "Reading your daily weight for fluid",
              "A two-pound overnight jump is the heart's first whisper. I check your morning weight and ankle notes every single day.",
              .automatic, .working, [sHealth, sLogs], "Every morning",
              "A flag the day it shifts — not the week after."),
            t("c-alert-1", "alerts", "The breathlessness rule, armed",
              "If you log shortness of breath or a fluid jump, I route it to your heart team the same day — any hour, no hesitating.",
              .automatic, .working, [sLogs], "Always on",
              "Never sat on, never missed."),
            t("c-adh-1", "adherence", "Empagliflozin refill — ready to send",
              "Your SGLT2 protects heart and kidney both, and you're down to six days. I can renew it now so the protection never gaps.",
              .needsApproval, .waiting, [sPharmacy], "This week",
              "Renewed — no gap in the cover."),
            t("c-sch-1", "scheduling", "Cardiology + nephrology, one trip",
              "Two specialists, one morning in town. I'm holding back-to-back slots so you're not making the drive twice.",
              .needsApproval, .waiting, [sCalendar], "This month",
              "Both booked, same morning."),
            t("c-edu-1", "education", "Heart- and kidney-smart plates",
              "Low-sodium, kidney-gentle, and pulled toward the vegetarian dinners you already like. I curate a few you'll actually cook.",
              .automatic, .working, [sLogs, sInstagram], "Daily",
              "Dinner, made simpler."),
            t("c-path-1", "pathway", "Keeping three doctors on one page",
              "Primary care, cardiology, nephrology — I reconcile what each one knows so no one's working blind, and your context follows you in.",
              .automatic, .working, [sRecord], "Ongoing",
              "One shared picture, always current."),
            t("c-life-1", "lifestyle", "Pacing movement around your heart",
              "Short, kind walks on good-breath days. I read your energy from Apple Health and never push past it.",
              .automatic, .working, [sHealth], "Most days",
              "Movement that helps, never strains."),
            t("c-mon-2", "monitor", "Glucose and pressure, read together",
              "I watch how your sugar and blood pressure move as a pair — in this body they pull on the same strings, and the kidneys feel both.",
              .automatic, .working, [sHealth, sLogs], "Ongoing",
              "The whole picture, not one number."),
        ]
    }
}
