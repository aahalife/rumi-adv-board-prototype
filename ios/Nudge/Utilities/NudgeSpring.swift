import SwiftUI

/// The only animation vocabulary in the app.
/// Usage rule: no `.linear`, no `.easeInOut` anywhere in app code.
enum NudgeSpring {
    /// Standard UI spring.
    static let ui = Animation.spring(response: 0.42, dampingFraction: 0.82)
    /// Large surfaces and screen morphs.
    static let gentle = Animation.spring(response: 0.55, dampingFraction: 0.86)
    /// Blooms only — at most one per session gets the full treatment.
    static let delight = Animation.spring(response: 0.38, dampingFraction: 0.66)
}
