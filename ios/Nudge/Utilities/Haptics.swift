import UIKit

/// Orchestrated haptic vocabulary — every meaningful touch answers in the
/// hand. Sounds and haptics are twins; both route through moments, not spam.
enum Haptics {
    /// Featherweight acknowledgment — dock taps, chips, toggles.
    static func tick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }

    /// Soft, rounded press — orb touches, glass surfaces.
    static func glass() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.8)
    }

    /// Medium pull — pull-to-talk threshold, sheet commits.
    static func pull() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Warm success — a log kept, a message sent.
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// The bloom — a kept habit, a milestone. Two-beat swell timed to the
    /// light bloom's apex. Use at most once per session for the full moment.
    static func bloom() {
        let soft = UIImpactFeedbackGenerator(style: .soft)
        soft.impactOccurred(intensity: 0.55)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            let rigid = UIImpactFeedbackGenerator(style: .medium)
            rigid.impactOccurred(intensity: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            let tail = UIImpactFeedbackGenerator(style: .light)
            tail.impactOccurred(intensity: 0.4)
        }
    }
}
