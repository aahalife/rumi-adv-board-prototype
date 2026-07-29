import Foundation

/// A moment on Today's Thread — the companion's chosen item for right now.
/// Hard cap of 3; dismiss melts it away, never to guilt-reappear.
struct Moment: Identifiable, Equatable {
    enum Kind: Equatable {
        case insight, habit, task, checkIn
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let body: String
    let actionLabel: String
    var insightID: UUID? = nil
    var journeyID: UUID? = nil
    var medID: String? = nil

    var glyph: String {
        switch kind {
        case .insight: return "sparkles"
        case .habit: return "leaf"
        case .task: return "pills"
        case .checkIn: return "bubble"
        }
    }
}

/// An insight — honest epistemics, visible lifecycle, loops that close.
struct Insight: Identifiable, Equatable {
    enum Category: String, CaseIterable, Identifiable {
        case pattern = "Patterns"
        case milestone = "Milestones"
        case headsUp = "Heads-ups"
        case opportunity = "Opportunities"
        var id: String { rawValue }
    }

    enum Status: Equatable {
        case fresh
        case seen
        case saved
        case acted(outcome: String)
    }

    enum Visual: Equatable {
        case chart(String)   // LabSeries id
        case scene(Int)      // generative seed
        case tide
    }

    let id = UUID()
    let category: Category
    let headline: String
    let body: String
    /// Sample-size-aware confidence copy. No causal language without basis.
    let confidence: String?
    let provenance: String
    let actionLabel: String?
    var status: Status
    let visual: Visual
    /// "Why am I seeing this" — exactly which data produced it.
    let sources: [String]
}

/// One thing the user is working on. Never called "goals", "streaks",
/// or "compliance".
struct AtomicHabit: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let contextLine: String
    /// No streak fields. Ever.
    var keptDates: [Date]
}

struct Journey: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let why: String
    var habits: [AtomicHabit]
    let gardenSeed: Int
    /// When derived from a care-plan goal (§4.4.5), the goal it serves —
    /// shown as provenance. Appended last so existing fixtures still compile.
    var planGoal: String? = nil

    var keptCount: Int { habits.reduce(0) { $0 + $1.keptDates.count } }
}

/// A structured program. Sponsorship can never alter clinical eligibility,
/// ranking, or language — see governance laws at the ranking site.
struct Program: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let summary: String
    /// nil = unsponsored. The user-visible experience never differs by funding
    /// status except this disclosure chip.
    let sponsor: String?
    let sponsorDetail: String?
    let clinicalWhy: String
    let personalFit: String
    let provenance: String
    let patientDividend: String?
    var enrolled: Bool = false
    var declined: Bool = false
}

struct SymptomLog: Identifiable, Equatable, Codable {
    var id = UUID()
    let kind: String
    let severity: Double
    let at: Date
    let note: String?
    /// Where on the body, when the symptom asked for a place.
    var bodyRegion: String? = nil
    /// Logged alongside a medication — patterns need anchors.
    var linkedMedID: String? = nil
}

/// An event on the Story timeline.
struct StoryEvent: Identifiable, Equatable {
    enum Kind: Equatable {
        case diagnosis, result, visit, milestone, companion
    }

    let id = UUID()
    let kind: Kind
    let date: Date
    let title: String
    let detail: String

    var glyph: String {
        switch kind {
        case .diagnosis: return "heart.text.square"
        case .result: return "drop"
        case .visit: return "stethoscope"
        case .milestone: return "sparkles"
        case .companion: return "circle.hexagongrid"
        }
    }
}
