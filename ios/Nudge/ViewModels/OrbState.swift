import SwiftUI

/// The companion's living state. Modes morph continuously — never cut.
@Observable final class OrbState {
    enum Mode: Equatable {
        case ambient, listening, thinking, speaking, celebrating, concerned, resting
    }

    private(set) var mode: Mode = .ambient
    private var fromEnergy: Double = 0.25
    private var targetEnergy: Double = 0.25
    private var transitionStart: TimeInterval = Date().timeIntervalSinceReferenceDate

    func set(_ newMode: Mode) {
        guard newMode != mode else { return }
        let now = Date().timeIntervalSinceReferenceDate
        fromEnergy = energy(at: now)
        mode = newMode
        targetEnergy = Self.target(for: newMode)
        transitionStart = now
    }

    /// One-shot bloom: brief expansion + light burst, then settle.
    func celebrate() {
        set(.celebrating)
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if mode == .celebrating { set(.ambient) }
        }
    }

    /// Smoothly eased energy for the shader — continuous morphs, never cuts.
    func energy(at t: TimeInterval) -> Double {
        let p = min(max((t - transitionStart) / 0.9, 0), 1)
        let eased = p * p * (3 - 2 * p)
        return fromEnergy + (targetEnergy - fromEnergy) * eased
    }

    var breathPeriod: Double {
        switch mode {
        case .ambient: return 4.0
        case .listening: return 2.6
        case .thinking: return 2.0
        case .speaking: return 1.7
        case .celebrating: return 1.2
        case .concerned: return 5.5
        case .resting: return 6.0
        }
    }

    private static func target(for mode: Mode) -> Double {
        switch mode {
        case .ambient: return 0.25
        case .listening: return 0.7
        case .thinking: return 0.55
        case .speaking: return 0.62
        case .celebrating: return 1.0
        case .concerned: return 0.16
        case .resting: return 0.1
        }
    }

    var accessibilityDescription: String {
        switch mode {
        case .ambient: return "calm"
        case .listening: return "listening"
        case .thinking: return "thinking"
        case .speaking: return "speaking"
        case .celebrating: return "celebrating with you"
        case .concerned: return "here with you"
        case .resting: return "resting"
        }
    }
}
