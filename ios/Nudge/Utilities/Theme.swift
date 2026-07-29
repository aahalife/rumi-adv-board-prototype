import SwiftUI

extension Color {
    /// Creates a color from a 0xRRGGBB hex value.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    /// Creates a dynamic color that resolves per appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

/// Semantic design tokens — two worlds, one soul.
/// Light: "Clay & Dawn". Dark: "Indigo Night". Never hardcode colors in views.
/// Earthy means the *feel* — the palette itself stays luminous and alive.
enum Theme {
    // MARK: Ground
    static let base = Color(light: 0xF6EEE3, dark: 0x0D1126)
    /// Surfaces sit clearly above the ground — porcelain-bright in daylight,
    /// raised indigo at night. Never the same value as the base.
    static let surface = Color(light: 0xFFFCF7, dark: 0x1E2449)
    static let raised = Color(light: 0xFFF8EE, dark: 0x2A3160)
    static let ink = Color(light: 0x2E2418, dark: 0xF4F1EA)
    /// Secondary text still has to *read* over the bright living gradient —
    /// deeper than a classic placeholder grey.
    static let inkMuted = Color(light: 0x6F6151, dark: 0xA7ADCE)

    /// Hairline borders that separate surfaces from the living ground.
    static let edge = Color(light: 0xE7D8C4, dark: 0x3A4178)
    /// Tinted shadow under surfaces — warm clay by day, deep indigo by night.
    static let shadow = Color(light: 0xC59A6E, dark: 0x000000)

    /// A cool/bright tint laid under the floating dock's Liquid Glass so its
    /// refraction and edge read against the warm living ground (untinted glass
    /// nearly disappeared over the gradient).
    static let dockTint = Color(light: 0xF4FBFF, dark: 0x3C4A86).opacity(0.30)

    // MARK: Accents (light → dark pairings) — vivid, never muddy
    static let warm = Color(light: 0xE0764E, dark: 0xFF9E7E)      // terracotta → coral glow
    static let life = Color(light: 0x7FAE7E, dark: 0x8FEFC0)      // sage → mint
    static let sky = Color(light: 0x6E9CC8, dark: 0x8FC6FF)       // dusty sky → sky
    static let gold = Color(light: 0xD9A348, dark: 0xC8B6FF)      // sand gold → lavender
    static let rose = Color(light: 0xD8849B, dark: 0xFF9FB2)      // dusty rose → rose glow

    /// Attention is carried by warm luminance — never red, never alarms.
    static let attention = Color(light: 0xD98A3D, dark: 0xFFBE8F)

    /// Companion gradient shells.
    static func companion(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark
            ? [Color(hex: 0x6EE7D8), Color(hex: 0x9D8CFF), Color(hex: 0xFF9FB2)]
            : [Color(hex: 0xFFC9A8), Color(hex: 0xF2A0BC), Color(hex: 0xB39DE8)]
    }

    /// Soft pastel halo behind the orb — the orb never floats on bare ground.
    static func orbHalo(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark
            ? [Color(hex: 0x9D8CFF).opacity(0.35), Color(hex: 0x6EE7D8).opacity(0.16), .clear]
            : [Color(hex: 0xFFC9A8).opacity(0.55), Color(hex: 0xF2A0BC).opacity(0.28), .clear]
    }

    /// Living-gradient palette tuned per time of day — visibly alive,
    /// dawn-rose to dusk-amber to night-indigo.
    static func gradientPalette(scheme: ColorScheme, hour: Int) -> (Color, Color, Color) {
        if scheme == .dark {
            // Night is indigo with real color in it — violet, teal and dusk-rose
            // blooms so the ground never reads as one flat navy.
            switch hour {
            case 5..<9: return (Color(hex: 0x3A2C6E), Color(hex: 0x1E4A5E), Color(hex: 0x121736))
            case 9..<17: return (Color(hex: 0x27306E), Color(hex: 0x174852), Color(hex: 0x2C2058))
            case 17..<21: return (Color(hex: 0x44286A), Color(hex: 0x233370), Color(hex: 0x47284E))
            default: return (Color(hex: 0x231F58), Color(hex: 0x163E55), Color(hex: 0x35205A))
            }
        } else {
            switch hour {
            case 5..<9: return (Color(hex: 0xFFE0CE), Color(hex: 0xF9D5E0), Color(hex: 0xEDE3F6))
            case 9..<17: return (Color(hex: 0xFBF2E4), Color(hex: 0xF6E2CE), Color(hex: 0xE6EAF4))
            case 17..<21: return (Color(hex: 0xFFDDBC), Color(hex: 0xF7D2D8), Color(hex: 0xE2DCF4))
            default: return (Color(hex: 0xF3E8D8), Color(hex: 0xEDDCCB), Color(hex: 0xE4E1F0))
            }
        }
    }

    /// Deeper, more atmospheric palette for the immersive conversation scene.
    static func conversationPalette(_ scheme: ColorScheme) -> (Color, Color, Color) {
        scheme == .dark
            ? (Color(hex: 0x231C52), Color(hex: 0x12305A), Color(hex: 0x0C1030))
            : (Color(hex: 0xFFDFC8), Color(hex: 0xF6CFDD), Color(hex: 0xDFD7F4))
    }
}
