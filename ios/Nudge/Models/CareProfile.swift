import Foundation

/// The care pathway shapes the whole experience — which symptoms exist, which
/// metrics matter, what the companion watches for, what "a hard day" means.
/// Not a theme. An understanding.
enum CarePathway: String, CaseIterable, Identifiable {
    case metabolic
    case oncology
    case procedure
    case cardiometabolic

    var id: String { rawValue }

    /// Onboarding choice label — warm, plain, never clinical-cold.
    var choiceLabel: String {
        switch self {
        case .metabolic: return "Diabetes, blood pressure & friends"
        case .oncology: return "Cancer treatment"
        case .procedure: return "A procedure coming up"
        case .cardiometabolic: return "Diabetes & a heart condition"
        }
    }

    var choiceDetail: String {
        switch self {
        case .metabolic: return "The long game — numbers, meds, and real life"
        case .oncology: return "Chemo, appointments, and the in-between days"
        case .procedure: return "Getting ready, and the recovery after"
        case .cardiometabolic: return "Heart, sugar and kidneys — protected together"
        }
    }

    var glyph: String {
        switch self {
        case .metabolic: return "heart"
        case .oncology: return "sparkles"
        case .procedure: return "bandage"
        case .cardiometabolic: return "heart.text.square"
        }
    }
}

/// Accent keys keep models SwiftUI-free; views map them to Theme colors.
enum AccentKey {
    case warm, life, sky, gold, rose
}

/// One condition on the user's record — surfaced with care, never as a label
/// the app keeps shouting.
struct CareCondition: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let since: String
    let state: String
    let plainLine: String
    let glyph: String
    let accent: AccentKey
}

/// A loggable symptom — adapted per condition. Some want a place on the body.
struct SymptomKind: Identifiable, Equatable, Hashable {
    var id: String { name }
    let name: String
    let glyph: String
    let needsBodyMap: Bool

    init(_ name: String, glyph: String, needsBodyMap: Bool = false) {
        self.name = name
        self.glyph = glyph
        self.needsBodyMap = needsBodyMap
    }
}

/// One goal on the doctor's care plan — mapped against the user's journeys.
struct CarePlanGoal: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
    /// Where this goal stands, in the companion's honest voice.
    let progressLine: String?
    let accent: AccentKey
    /// Source visit/order for this goal (PLAN-2). Appended last so existing
    /// fixture calls keep compiling.
    var provenance: String? = nil
}

/// The plan from the care team — visible, plain, and mapped to real life.
struct CarePlan: Equatable {
    let author: String
    let updated: String
    let intro: String
    let goals: [CarePlanGoal]
}

/// What to expect — phase-aware guidance (chemo cycles, procedure windows,
/// or the long steady game).
struct ExpectationItem: Identifiable, Equatable {
    let id = UUID()
    let window: String
    let title: String
    let detail: String
    let accent: AccentKey
}

/// Where the user is in their treatment arc right now.
struct CarePhase: Equatable {
    let kicker: String
    let headline: String
    let detail: String
    /// 0…1 — cycle progress or countdown; nil hides the arc.
    let progress: Double?
}

/// An entry in the discussion guide — questions and observations the user
/// carries into their next visit.
struct GuideItem: Identifiable, Equatable, Codable {
    enum Kind: String, Codable {
        case question = "Question"
        case observation = "Observation"
    }

    var id = UUID()
    let kind: Kind
    var text: String
    let addedFrom: String
    var resolved: Bool = false
}

/// The companion's response to a symptom log — support first, then paths
/// that actually go somewhere: the guide, the office, a conversation.
struct SupportPlan: Equatable {
    let message: String
    let tips: [String]
    /// Elevated severity — the office becomes the gently-lit path.
    let urgent: Bool
    let guideQuestion: String
    let draftMessage: String
}

/// A region on the abstract body map.
enum BodyRegion: String, CaseIterable, Identifiable {
    case head = "Head"
    case chest = "Chest"
    case abdomen = "Belly"
    case leftArm = "Left arm"
    case rightArm = "Right arm"
    case lowerBack = "Lower back"
    case leftLeg = "Left leg"
    case rightLeg = "Right leg"
    case feet = "Feet & hands"

    var id: String { rawValue }
}

/// Everything one person's experience is built from. The app renders the
/// same calm world for everyone — the persona decides what lives inside it.
struct Persona {
    let pathway: CarePathway
    let firstName: String
    let switcherLine: String
    let conditions: [CareCondition]
    let conditionChip: String
    let heroImage: String
    let phase: CarePhase?
    let expectations: [ExpectationItem]
    let carePlan: CarePlan
    let symptomKinds: [SymptomKind]
    let labSeries: [LabSeries]
    let medications: [Medication]
    let careTeam: [CareTeamMember]
    let officePhone: String
    let officeName: String
    let appointments: [Appointment]
    let journeys: [Journey]
    let insights: [Insight]
    let storyEvents: [StoryEvent]
    let currents: [CurrentsPiece]
    let moments: [Moment]
    let statusQuiet: String
    let statusBusy: String
    let guideSeed: [GuideItem]
}
