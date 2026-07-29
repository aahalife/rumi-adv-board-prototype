import Foundation

/// One vocabulary (§11.3): a single source of truth for every user-facing noun.
/// The same concept never has two names anywhere — a habit is never "goal"
/// in a notification and "task" in settings. Copy must use these terms.
enum Glossary {
    static let moment = "moment"        // an item on Today's Thread
    static let insight = "insight"      // a pattern/milestone/heads-up/opportunity
    static let journey = "journey"      // one thing the user is working on
    static let habit = "habit"          // the atomic unit inside a journey
    static let current = "current"      // a piece in the daily content set
    static let recap = "recap"          // a cinematic chapter film
    static let companion = "companion"  // the orb; never "bot", "assistant", "AI"
    static let story = "story"          // the health record as narrative

    /// Banned words (§4.3) — never render these to the user:
    /// "streak", "goal", "compliance", "failed", "missed", "don't forget".
}
