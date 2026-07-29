import Foundation

/// A piece in the Currents daily set. Finite — 3–7 pieces, then the end
/// scene. No infinite feed. Ever.
struct CurrentsPiece: Identifiable, Equatable {
    enum Format: String, Equatable {
        case glance = "Glance"
        case read = "Read"
        case watch = "Watch"
        case listen = "Listen"
    }

    let id = UUID()
    let format: Format
    let kicker: String
    let headline: String
    let body: String
    let sceneSeed: Int
    /// Bundled illustration name — every piece is a scene, not a card.
    var imageName: String? = nil
    let aiGenerated: Bool
    /// Server-side intent tag — every piece is a nudge by other means.
    let intent: String
    var saved: Bool = false
    var taste: Int = 0   // -1 less, 0 neutral, 1 more

    var formatGlyph: String {
        switch format {
        case .glance: return "eye"
        case .read: return "text.alignleft"
        case .watch: return "play"
        case .listen: return "waveform"
        }
    }

    var durationLabel: String {
        switch format {
        case .glance: return "20 sec"
        case .read: return "3 min"
        case .watch: return "1 min"
        case .listen: return "2 min"
        }
    }
}

/// One turn in the unified conversation.
struct ConversationTurn: Identifiable, Equatable {
    enum Role: Equatable { case user, companion }

    enum Rich: Equatable {
        case none
        case trend(String)                                  // LabSeries id
        case habitProposal(title: String, context: String)
        case refillFix(med: String, detail: String)
        /// A question the companion drafted for the discussion guide.
        case guideAdd(question: String)
        /// An agentic step the companion wants to take — needs approval.
        case agentAction(title: String, detail: String)
        /// A program surfaced in conversation, with full disclosure.
        case program(title: String)
    }

    let id = UUID()
    let role: Role
    var text: String
    var rich: Rich = .none
    var richResolved: Bool = false
    /// True while tokens are still arriving — drives the streaming shimmer.
    var streaming: Bool = false
}
