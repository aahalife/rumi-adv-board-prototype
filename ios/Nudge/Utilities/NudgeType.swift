import SwiftUI
import CoreText

/// Two-voice typography. The serif voice is Fraunces — a warm, deeply human
/// face with old-style soul; it owns meaning moments. Rounded sans owns
/// function. Never both voices at the same hierarchy level on one surface.
enum NudgeType {
    /// The display voice — Hermione, a curved, deeply human serif reserved
    /// for the wordmark, screen titles and chapter-scale moments only.
    static func display(_ size: CGFloat) -> Font {
        .custom("HermioneFREE", size: size)
    }

    /// The serif voice — warmth and gravity. Headlines, story chapters,
    /// milestone copy, the companion's emphasized lines.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "Fraunces-Bold"
        case .semibold: name = "Fraunces-SemiBold"
        case .medium: name = "Fraunces-Medium"
        default: name = "Fraunces-Regular"
        }
        return .custom(name, size: size)
    }

    /// Serif italic — for a single warm aside, never long passages.
    static func serifItalic(_ size: CGFloat) -> Font {
        .custom("Fraunces-Italic", size: size)
    }

    /// The rounded voice — UI chrome, labels, conversation body, data.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Numbers are always sans with monospaced digits.
    static func number(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// Small caps-style kicker labels.
    static func kicker() -> Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }
}

/// Registers the bundled Fraunces files at launch. If registration fails the
/// system serif quietly stands in — type never blocks the app.
enum NudgeFonts {
    static func registerAll() {
        let files = [
            "Fraunces-400", "Fraunces-500", "Fraunces-600", "Fraunces-700",
            "Fraunces-400-italic", "HermioneFREE",
        ]
        for file in files {
            guard let url = Bundle.main.url(forResource: file, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
