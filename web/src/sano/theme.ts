/** Sano design tokens mirrored from the iOS Theme. Earthy means the *feel* —
 *  the palette itself stays luminous and alive. */

export type Scheme = "day" | "night";
export type AccentKey = "warm" | "life" | "sky" | "gold" | "rose" | "attention";

/** Accent → tailwind text/bg token name (drives `text-warm`, `bg-life/15` etc). */
export const accentToken: Record<AccentKey, string> = {
  warm: "warm",
  life: "life",
  sky: "sky",
  gold: "gold",
  rose: "rose",
  attention: "attention",
};

/** Living-gradient palette tuned per time of day. */
export function gradientPalette(scheme: Scheme, hour: number): [string, string, string] {
  if (scheme === "night") {
    if (hour >= 5 && hour < 9) return ["#3A2C6E", "#1E4A5E", "#121736"];
    if (hour >= 9 && hour < 17) return ["#27306E", "#174852", "#2C2058"];
    if (hour >= 17 && hour < 21) return ["#44286A", "#233370", "#47284E"];
    return ["#231F58", "#163E55", "#35205A"];
  }
  if (hour >= 5 && hour < 9) return ["#FFE0CE", "#F9D5E0", "#EDE3F6"];
  if (hour >= 9 && hour < 17) return ["#FBF2E4", "#F6E2CE", "#E6EAF4"];
  if (hour >= 17 && hour < 21) return ["#FFDDBC", "#F7D2D8", "#E2DCF4"];
  return ["#F3E8D8", "#EDDCCB", "#E4E1F0"];
}

export function conversationPalette(scheme: Scheme): [string, string, string] {
  return scheme === "night"
    ? ["#231C52", "#12305A", "#0C1030"]
    : ["#FFDFC8", "#F6CFDD", "#DFD7F4"];
}

/** The companion gradient shells. */
export function companionColors(scheme: Scheme): [string, string, string] {
  return scheme === "night"
    ? ["#6EE7D8", "#9D8CFF", "#FF9FB2"]
    : ["#FFC9A8", "#F2A0BC", "#B39DE8"];
}

/** Soft pastel halo behind the orb. */
export function orbHalo(scheme: Scheme): string {
  return scheme === "night"
    ? "radial-gradient(circle, rgba(157,140,255,0.40), rgba(110,231,216,0.16) 45%, transparent 70%)"
    : "radial-gradient(circle, rgba(255,201,168,0.62), rgba(242,160,188,0.30) 45%, transparent 70%)";
}

export const FIXTURE_HOUR = new Date().getHours();
