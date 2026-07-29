# Legacy Requirements — Rumi / Nudge

**Document type:** Comprehensive as-built specification (legacy requirements)
**Scope:** Every feature, screen, model, asset, behavior, animation and integration currently implemented across all three apps in this project.
**Status:** Reverse-engineered from the shipped codebase. This document describes *what exists*, not what is planned. Where a governance rule is encoded in code, it is recorded here as a requirement.

---

## Table of contents

1. [Product overview](#1-product-overview)
2. [Repository & app topology](#2-repository--app-topology)
3. [Design system](#3-design-system)
4. [Motion, sound & haptics](#4-motion-sound--haptics)
5. [The companion (Rumi)](#5-the-companion-rumi)
6. [Care pathways & personas](#6-care-pathways--personas)
7. [Data model reference](#7-data-model-reference)
8. [Application shell & navigation](#8-application-shell--navigation)
9. [Onboarding](#9-onboarding)
10. [Screen-by-screen specification](#10-screen-by-screen-specification)
11. [The agent network](#11-the-agent-network)
12. [Logging systems](#12-logging-systems)
13. [Services & platform integrations](#13-services--platform-integrations)
14. [Backend (Cloudflare Worker)](#14-backend-cloudflare-worker)
15. [Web app (Rumi web mirror)](#15-web-app-rumi-web-mirror)
16. [Asset inventory](#16-asset-inventory)
17. [Persistence & state](#17-persistence--state)
18. [Privacy, safety & governance laws](#18-privacy-safety--governance-laws)
19. [Accessibility](#19-accessibility)
20. [Configuration & environment](#20-configuration--environment)
21. [Build, validation & known constraints](#21-build-validation--known-constraints)

---

## 1. Product overview

**Rumi** (iOS app target name: `Nudge`) is a companion-led chronic-care app. It is not a dashboard, a tracker, or a portal. It is a calm, living world in which a single AI companion — the orb, named Rumi — holds the user's entire health story and quietly does the remembering, noticing, and arranging that "a great friend who happens to be a nurse" would do.

### Product pillars

| Pillar | Requirement |
|---|---|
| **One companion, everywhere** | The companion is never a tab. It is present on every surface — full-size on Today, minimized top-right elsewhere, and the destination of every "talk to me" affordance. |
| **One data spine** | A value shown on Today, in the Care hub, in Trends, and in conversation is *the same value with the same freshness stamp*. There is exactly one store (`AppModel`). |
| **Calm but capable** | Nothing consequential happens without an explicit, equal-weight confirmation. Attention is carried by warm luminance — never red, never alarms. |
| **Agentic, visibly** | A family of specialized agents is always working. Safe work runs automatically; anything that leaves the device or touches the care team waits for one human tap. The machine is shown working — but never allowed to overshadow the calm. |
| **Finite, not infinite** | Today's Thread caps at 3 moments. Currents is a finite 3–7 piece daily set with an honest end scene. There is no infinite feed anywhere. |
| **No guilt mechanics** | No streaks, no broken chains, no compliance percentages on any surface. Progress is a growing light-garden; adherence is a soft tide. |

### Banned vocabulary (enforced in `Utilities/Glossary.swift`)

Never rendered to the user: **streak, goal, compliance, failed, missed, "don't forget"**. The companion is never called *bot*, *assistant*, or *AI*.

### Canonical vocabulary (one word per concept, everywhere)

`moment` (item on Today's Thread) · `insight` (pattern/milestone/heads-up/opportunity) · `journey` (a thing being worked on) · `habit` (atomic unit inside a journey) · `current` (a piece in the daily content set) · `recap` (cinematic chapter film) · `companion` (the orb) · `story` (the record as narrative).

---

## 2. Repository & app topology

Declared in `rork.json`:

| App | Path | Framework | Role |
|---|---|---|---|
| **Nudge** | `ios/` | Swift / SwiftUI | The primary product. iOS 18 minimum, iOS 26 Liquid Glass where available. |
| **Rumi** | `web/` | Vite + React + TypeScript + Tailwind | A faithful browser mirror of the iOS experience, rendered inside a 440 pt device column. |
| **Functions** | `functions/` | Cloudflare Worker | Private voice proxy (ElevenLabs STT + TTS). Holds the API key server-side. |

### iOS source layout

```
ios/Nudge/
├── NudgeApp.swift              @main — font registration, scene-phase music
├── ContentView.swift           Living gradient + onboarding/root switch
├── Config.swift                Auto-generated env view (values injected at build)
├── Models/          (11)       Domain types + persona/care/agent fixtures
├── ViewModels/      (3)        AppModel, CompanionEngine, OrbState
├── Services/        (5)        SoundEngine, VoiceSession, CompanionAI,
│                               PersistenceService, SubjectLifter
├── Utilities/       (6)        Theme, NudgeType, NudgeSpring, Haptics,
│                               Glossary, AppConfig
├── Views/
│   ├── Onboarding/  (3)        8-stage conversational onboarding
│   ├── Today/       (2)        Today canvas + moment cards
│   ├── Care/        (12)       The clinical action center
│   ├── You/         (9)        The health story
│   ├── Journeys/    (1)        Behavior change
│   ├── Currents/    (2)        Daily content set + players
│   ├── Conversation/(2)        Text conversation + hands-free voice mode
│   ├── Log/         (3)        Quick log, body map, library picker
│   ├── Life/        (1)        Meals/activity/meds gallery
│   ├── Meds/        (2)        Medication list + detail
│   ├── Insights/    (1)        Editorial insights hub
│   ├── Settings/    (2)        Settings + privacy center
│   ├── Components/  (15)       Orb, glass, charts, ripple, tide, garden…
│   └── RootView.swift          Post-onboarding shell
├── Shaders/         (3)        Orb.metal, LivingGradient.metal, Effects.metal
├── Fonts/           (6)        Fraunces ×5, HermioneFREE ×1
├── Resources/       (18)       5 music/SFX beds, 5 orb videos, 5 tap notes, 3 SFX
└── Assets.xcassets/ (67)       App icon, accent color, 64 illustration imagesets
```

---

## 3. Design system

All tokens live in `Utilities/Theme.swift`. **Views must never hardcode a color.**

### Two worlds, one soul

| Token | Light ("Clay & Dawn") | Dark ("Indigo Night") | Use |
|---|---|---|---|
| `base` | `#F6EEE3` | `#0D1126` | The ground behind everything |
| `surface` | `#FFFCF7` | `#1E2449` | Cards — never equal to base |
| `raised` | `#FFF8EE` | `#2A3160` | Elevated inner surfaces |
| `ink` | `#2E2418` | `#F4F1EA` | Primary text |
| `inkMuted` | `#6F6151` | `#A7ADCE` | Secondary text (deliberately deeper than a placeholder grey so it reads over the living gradient) |
| `edge` | `#E7D8C4` | `#3A4178` | Hairline borders |
| `shadow` | `#C59A6E` | `#000000` | Tinted shadow under surfaces |
| `dockTint` | `#F4FBFF` @30% | `#3C4A86` @30% | Cool tint under the dock's Liquid Glass so refraction reads over the warm ground |

### Accents

| Token | Light | Dark | Semantic |
|---|---|---|---|
| `warm` | `#E0764E` terracotta | `#FF9E7E` coral glow | Primary accent, app tint |
| `life` | `#7FAE7E` sage | `#8FEFC0` mint | Growth, habits, positive |
| `sky` | `#6E9CC8` | `#8FC6FF` | Clinical, scheduling |
| `gold` | `#D9A348` | `#C8B6FF` lavender | Value, savings, insight |
| `rose` | `#D8849B` | `#FF9FB2` | Messages, human warmth |
| `attention` | `#D98A3D` | `#FFBE8F` | **Attention is warm luminance, never red** |

### The living gradient

`LivingGradientView` renders an ultra-slow Metal mesh of three orbiting radial centers. Palette is selected by `Theme.gradientPalette(scheme:hour:)` across four windows — 5–9 (dawn), 9–17 (day), 17–21 (dusk), 21–5 (night) — so the app's ground visibly follows the time of day.

`Theme.conversationPalette(_:)` supplies a deeper, more atmospheric variant used behind conversation and voice mode.

### Typography — two voices

`Utilities/NudgeType.swift`. Registered at launch by `NudgeFonts.registerAll()` via `CTFontManagerRegisterFontsForURL`; if registration fails the system serif quietly stands in.

| Voice | Face | Reserved for |
|---|---|---|
| **Display** | HermioneFREE (curved humanist serif) | Wordmark, screen titles, chapter-scale moments only |
| **Serif** | Fraunces 400/500/600/700 + italic | Headlines, story chapters, milestone copy, companion emphasis |
| **Rounded** | SF Rounded | All UI chrome, labels, conversation body |
| **Number** | SF Rounded, monospaced digits | Every numeral, always |
| **Kicker** | 11 pt semibold rounded | Small-caps section labels |

**Rule:** never both voices at the same hierarchy level on one surface.

### Glass discipline

`Views/Components/GlassSurface.swift` provides the single vocabulary:

- `GlassSurface` — true `glassEffect()` on iOS 26, layered-material equivalent below. **Reserved for dock, floating chips, input bars, sheet headers. Glass is seasoning, not the meal.**
- `OrganicSurface` — the standard non-glass card: porcelain-bright by day, lifted indigo at night, hairline edge, warm tinted shadow.
- `CircularGlass` / `CapsuleGlass` — one source of truth for round and chip glass.
- `ChromeIcon` — one vocabulary for every floating icon button, so day and night chrome read identically.
- `LightSweep` / `AmbientLightSweep` — a traveling band of iridescent light with a faint liquid lens; fired on tap/appearance or ambiently.
- `NudgeButtonStyle` — every tappable thing acknowledges with a spring.

**Hard rule:** never layer Metal effects over Liquid Glass — on iOS 26 this renders placeholders.

---

## 4. Motion, sound & haptics

### Animation vocabulary (`Utilities/NudgeSpring.swift`)

The *only* animation vocabulary in the app. **No `.linear`, no `.easeInOut` anywhere in app code.**

| Spring | Response | Damping | Use |
|---|---|---|---|
| `ui` | 0.42 | 0.82 | Standard UI |
| `gentle` | 0.55 | 0.86 | Large surfaces, screen morphs |
| `delight` | 0.38 | 0.66 | Blooms only — at most one full treatment per session |

### Signature animations & effects

| Effect | Implementation | Behavior |
|---|---|---|
| **Living gradient** | `LivingGradient.metal` | Three orbiting radial centers, ultra-slow, time-of-day tuned |
| **Orb (Metal)** | `Orb.metal` + `OrbView` | Three noise-displaced gradient shells, additive blending, specular kiss, volumetric halo, pastel light-nest beneath. Not a face. It breathes. |
| **Orb (video)** | `VideoOrbView` | Real footage of a hand-crafted glass orb; AVPlayerLayer pairs cross-fade between moods so the orb *morphs, never cuts*. Day ambient = pearl, night ambient = deep indigo, speaking/listening = vivid Siri-glass, thinking = transparent bubble, celebrating = checkmark bloom. Placements < 60 pt fall back to the Metal orb. |
| **Touch ripple** | `RippleEffect.swift` + `Effects.metal` | Janum-Trivedi-style fluid wave distortion propagating from the touch point, paired with `touchGlow` so light visibly bends with the water. Finger-driven, never looped. Taps still reach buttons beneath. |
| **Melt dissolve** | `MeltModifier` | Alpha erosion via Metal, animatable so it rides `NudgeSpring`. Used when a moment is dismissed. |
| **Pull-to-talk** | `TodayCanvasView` | Drag the canvas down; orb scales up to +14 %, label brightens, medium haptic fires at the 110 pt threshold, conversation opens. |
| **Progressive blur** | `ProgressiveBlur` | Stacked gradient-masked material layers (no private API) so content melts into mist toward an edge. |
| **Light garden** | `LightGardenView` | Each kept habit adds a softly glowing element to a generative scene. Touch a light and it answers: which habit, which day. |
| **Tide** | `TideView` | Adherence as a soft tide whose fullness reflects the last 30 days. No percentages on the surface. |
| **Glow chart** | `GlowChart` | Luminous line + soft outer glow, under-fill fading to clear, reference bands as soft gradients (**never red/green judgment colors**), points only on scrub. |
| **Voice aura** | `VoiceGradientGlow` | Siri-like aura rising from the bottom, breathing with speech energy: luminous soft-white core, gentle multicolor fringe, small slow embers of light drifting up. Never fast confetti. |
| **Memory orbs** | `MemoryOrbView` | A photograph suspended inside true Liquid Glass. `MemoryArcViewer` swings held moments past on a circular arc, snapping to the nearest bead. |
| **Streaming text** | `StreamingText` | The last stretch of a streaming reply glows softly, so tokens feel *poured* rather than printed. Thinking state is a quiet shimmer — never typing dots. |
| **Scene visual** | `SceneVisual` + `SeededRandom` | Deterministic seeded generative light scenes for insight visuals, Currents grounds and empty states. **Never a sad clipboard.** |
| **Subject lift** | `SubjectLifter` + `LiftedImage` | Vision `VNGenerateForegroundInstanceMaskRequest` cuts the subject out of a bundled studio photo so logged items float on the canvas with a soft elliptical contact shadow. Two-tier cache (NSCache + disk PNG); each image lifted exactly once. Falls back to the rounded original while Vision works. |

### The score (`Services/SoundEngine.swift`)

Audio session category is `.playback` with `.mixWithOthers` — **the score stays audible with the silent switch on**.

**Three layers:**

1. **Tap notes** — five recordings of a small girl singing "ta" at different chords (`tap_ta_1…5.mp3`). Taps walk a pentatonic phrase `[0,2,4,2,3,1,4,0,2,3]`, so ordinary use composes an endless little melody. Two-player pool per note so rapid taps overlap instead of cutting. Rate-limited to one note per 90 ms.
2. **Music beds** — `music_barley_thunder.m4a` (onboarding, vol 0.42) and `music_stone_kintsugi.m4a` (the world, vol 0.30). Beds crossfade over ~2.4 s using a smoothstep-eased 30 fps ramp, loop seamlessly, and duck out entirely when muted. `music_recap.mp3` is the one place the score leads.
3. **Moments** — `sfx_whoosh` (stage advance) and `sfx_bloom` (a kept habit, an approval, a milestone).

**Intentional silence:** `tick()` is deliberately a no-op. The vocal "ta" is reserved for meaningful moments — opening the companion, logging, sending, keeping a habit, approvals — so it never feels random on incidental taps. Haptics still fire at those call sites.

Scene-phase handling in `NudgeApp`: the bed resumes on `.active` (1.8 s fade) and pauses on `.background` (0.6 s fade).

### Haptic vocabulary (`Utilities/Haptics.swift`)

| Call | Generator | Use |
|---|---|---|
| `tick()` | light @ 0.6 | Dock taps, chips, toggles |
| `glass()` | soft @ 0.8 | Orb touches, glass surfaces |
| `pull()` | medium | Pull-to-talk threshold, sheet commits |
| `success()` | notification success | A log kept, a message sent |
| `bloom()` | soft 0.55 → +0.16 s medium 1.0 → +0.34 s light 0.4 | Three-beat swell timed to the light bloom's apex. At most once per session for the full moment. |

Sounds and haptics are twins; both route through *moments*, never spam.

---

## 5. The companion (Rumi)

### Orb state machine (`ViewModels/OrbState.swift`)

Seven modes, each with a target energy and breath period. Modes **morph continuously, never cut** — `energy(at:)` smoothsteps over 0.9 s from the previous energy.

| Mode | Energy | Breath period | Accessibility label |
|---|---|---|---|
| `ambient` | 0.25 | 4.0 s | "calm" |
| `listening` | 0.70 | 2.6 s | "listening" |
| `thinking` | 0.55 | 2.0 s | "thinking" |
| `speaking` | 0.62 | 1.7 s | "speaking" |
| `celebrating` | 1.00 | 1.2 s | "celebrating with you" |
| `concerned` | 0.16 | 5.5 s | "here with you" |
| `resting` | 0.10 | 6.0 s | "resting" |

`celebrate()` is a one-shot: bloom for 1.6 s, then settle back to ambient.

### Conversational brain (`ViewModels/CompanionEngine.swift`)

- **Model:** `anthropic/claude-sonnet-4.6` via the Rork AI gateway (`{toolkitURL}/v2/vercel/v1/chat/completions`), streaming SSE, `temperature 0.75`, `max_tokens 700`, 45 s timeout.
- **Streaming:** deltas are appended to the visible turn as they arrive, with a hold-back buffer that withholds anything inside `[[ … ]]` so action tags never flash on screen mid-stream.
- **History window:** last 14 turns.
- **Offline grace:** on any failure it falls back to a scripted local brain that streams word-by-word at 34 ms/word, so the companion never goes silent.

#### System prompt requirements (the companion's soul)

The prompt is assembled fresh on every ask and grounds the model in the *whole* picture: pathway, phase, conditions, medications with supply days, chartable labs (with their tag ids), care plan and author, upcoming appointments, office name and phone, what it remembers, recent symptom logs, recent life log, open guide questions, available programs (with sponsorship marked), and already-offered steps (so it never re-offers).

Voice & soul rules encoded in the prompt:

- Sound like a person. Contractions, rhythm, warmth. Default 2–4 sentences (~60 words). Depth only when invited.
- **Zero sycophancy.** Never open with praise, never "Great question", never mirror-flatter. Specific beats nice.
- **No AI-speak.** Never "As an AI", never disclaim, never clinical jargon without translating it in the same breath.
- **Hold hard feelings before fixing them.** One beat of real acknowledgment, then at most *one* small concrete step. Never two.
- Honor the user's tone preference. Lightly funny when light; never when heavy.

Clinical spine (hard rules in the prompt):

- Never diagnose, never adjust doses, never contradict the care team. Notice, prepare, connect.
- **Oncology fever rule: ≥ 100.4 °F = call the team now, any hour.** Non-negotiable, said calmly.
- **Procedure: NSAIDs stop June 16. Acetaminophen stays safe.**
- Anything that leaves the phone needs explicit approval.

#### Action tag protocol

At most **one** tag per reply, at the very end, never inside a sentence. `parse(_:)` strips all tags and promotes the first to a rich element.

| Tag | Rich element | Effect |
|---|---|---|
| `[[trend:SERIES_ID]]` | `.trend` | Inline glow chart for that lab series |
| `[[habit:Title\|when-context]]` | `.habitProposal` | One-tap hold of a tiny habit slot |
| `[[refill:Med\|detail]]` | `.refillFix` | Refill fix card |
| `[[guide:Question]]` | `.guideAdd` | **Side effect:** immediately inserts the question into the discussion guide, stamped "Drafted in conversation · <date>" |
| `[[action:Title\|what I'll do]]` | `.agentAction` | Approval card for an agentic step |
| `[[program:Exact title]]` | `.program` | Program card with full sponsorship disclosure |

#### Seeded sessions

`openConversation(seed:)` opens the conversation on a topic. `symptom:<kind>` instructs the model to sit with the symptom first, then offer one useful question or step, and to draft a guide question if it belongs in front of the care team. Any other seed is picked up naturally.

### Voice mode (`Services/VoiceSession.swift`)

A fully **hands-free** loop. Phases: `idle → listening → transcribing → thinking → speaking → idle …`, plus `unavailable(String)`.

1. **Permission** — `AVAudioApplication.requestRecordPermission()`. Denial shows a warm line pointing at Settings.
2. **Record** — `.playAndRecord`, `.voiceChat` mode, `defaultToSpeaker` + `allowBluetooth`, AAC 44.1 kHz mono medium. The music bed is paused (0.2 s) so **the mic never picks up the score**.
3. **Client-side VAD** — 42 ms metering loop. Level = `10^(dBFS/20) × 2.8`, clamped 0…1. Speech is detected above 0.06; ~1.1 s of quiet (26 frames) after real speech commits the turn; a natural mid-sentence pause will not cut you off; the earliest possible commit is 1.0 s in. If nobody speaks for ~8 s the mic recycles silently — **no error, no fuss**.
4. **Transcribe** — multipart POST to `{functionsURL}/voice/stt`, model `scribe_v2`, `diarize=false`, `no_verbatim=true`. Audio under 2 000 bytes is discarded.
5. **Miss handling** — an empty transcript increments a miss counter. Only on the **second consecutive** miss does it surface "Still here — take your time, I'm listening." Otherwise it just keeps listening.
6. **Think** — `CompanionEngine.voiceReply` appends a voice-mode addendum to the system prompt: 1–2 short warm spoken sentences, no lists, at most one tag. Turns land in the same chat history, so the conversation continues seamlessly in text afterwards.
7. **Speak** — POST to `{functionsURL}/voice/tts` with `eleven_turbo_v2_5` (chosen for ~250 ms latency while holding the custom voice; `eleven_v3` was richer but too slow for live talk). Playback metering at 33 ms drives the aura.
8. **Loop** — 450 ms after speaking, the mic reopens automatically. Tapping is only ever *start / interrupt / end*, never required per turn.
9. **Teardown** — restores `.playback` session and resumes the ambient bed at 1.6 s.

---

## 6. Care pathways & personas

The care pathway shapes the whole experience — which symptoms exist, which metrics matter, what the companion watches for, what "a hard day" means. **It is not a theme. It is an understanding.**

| Pathway | Persona | Onboarding label | Detail |
|---|---|---|---|
| `metabolic` | **Marcus** | "Diabetes, blood pressure & friends" | "The long game — numbers, meds, and real life" |
| `oncology` | **Elena** | "Cancer treatment" | "Chemo, appointments, and the in-between days" |
| `procedure` | **Sam** | "A procedure coming up" | "Getting ready, and the recovery after" |
| `cardiometabolic` | **Rosa** | "Diabetes & a heart condition" | "Heart, sugar and kidneys — protected together" |

A `Persona` (defined in `Models/CareProfile.swift`, populated in `Models/PersonaFixtures.swift`, 1 144 LOC) carries: conditions, condition chip, hero image, care phase, expectations, care plan, symptom kinds, lab series, medications, care team, office name/phone, appointments, journeys, insights, story events, currents, moments, quiet/busy status lines, and a discussion-guide seed.

`CareHubFixtures` (658 LOC) supplies the parallel Care bundle per pathway: appointments, threads, bills, cost summary, documents, savings, request seeds, the result awaiting acknowledgment, and the looking-ahead nudge. `MarcusFixtures` (625 LOC) supplies the shared programs, record items, sources, consents and memory seeds.

**Pathway switching** (`AppModel.switchPathway`) is available in onboarding and in Settings as a "journey previewer" — it rebuilds every store inside a `NudgeSpring.gentle` animation, resets the companion, clears derived journeys and logs, and persists the choice.

---

## 7. Data model reference

### Engagement (`Models/EngagementModels.swift`)

- **`Moment`** — one item on Today's Thread. Kinds: `insight`, `habit`, `task`, `checkIn`. Hard cap of 3 on screen. Dismissal melts it away, never to guilt-reappear.
- **`Insight`** — categories `pattern` / `milestone` / `headsUp` / `opportunity`; lifecycle `fresh → seen → saved → acted(outcome:)`; carries sample-size-aware `confidence` copy, `provenance`, a `sources` list for "why am I seeing this", and a `visual` (chart / seeded scene / tide). **No causal language without basis.**
- **`AtomicHabit`** — title, context line, `keptDates`. **No streak fields. Ever.**
- **`Journey`** — title, why, habits, `gardenSeed`, optional `planGoal` provenance.
- **`Program`** — sponsored or not; `sponsor`, `sponsorDetail`, `clinicalWhy`, `personalFit`, `provenance`, `patientDividend`. Sponsorship can never alter clinical eligibility, ranking, or language.
- **`SymptomLog`** — kind, severity 0…1, timestamp, note, optional body region, optional linked medication.
- **`StoryEvent`** — `diagnosis` / `result` / `visit` / `milestone` / `companion`.

### Record (`Models/RecordModels.swift`)

- **`LabSeries`** — points, unit, optional soft reference `band` + label, an `annotation`, `provenance`, and three-tier explain copy (`explainReading`, `explainNextStep`, `explainAsk`).
- **`Medication`** — dose, purpose line, schedule line, `supplyDaysRemaining`, pharmacy, guidance, watchlist, history, and `adherence30` (30 daily 0…1 values). `tideLevel` is the mean. **PDC lives one tap deep, never on the surface.**
- **`RecordItem`** — categorized row (labs / medications / conditions / immunizations / procedures / notes / documents) with source, optional `conflicted` + `conflictNote`, optional `seriesID`.
- **`RecordSource`** — name, rail label, connected flag, `lastSync`. Aggregation quality is a first-class UX concern.
- **`ConsentEntry`**, **`CareTeamMember`**, **`Appointment`** (kind, status, join link, trip plan, plan-goal hint), **`MemoryItem`** (text + `learnedFrom`).

### Care profile (`Models/CareProfile.swift`)

`CarePathway`, `AccentKey`, `CareCondition`, `SymptomKind` (with `needsBodyMap`), `CarePlanGoal` (with `provenance`), `CarePlan`, `ExpectationItem`, `CarePhase` (kicker/headline/detail/progress), `GuideItem` (question|observation, `addedFrom`, `resolved`), `SupportPlan` (message, tips, `urgent`, guide question, draft message), `BodyRegion` (9 regions), `Persona`.

### Care hub (`Models/CareHubModels.swift`)

`CareDestination` (18 type-safe cases), `MessageChannelMode` (`inApp` "Secure in-app thread" | `portal` "Drafted for the portal"), `MessageCategory` (medical / refill / admin / records), `MessageState` (draft → sending → sent → delivered → replied), `CareMessage` (with `origin` context and `attachment` provenance), `MessageThread`, `AppointmentKind`, `AppointmentStatus`, `TripStep`, `TripPlan` (depart-by, travel minutes, route hint, map query, checklist, virtual flag, calendar conflict, ride hint), `BillStatus`, `BillLineItem` (billed / plan paid / you owe / **why** you owe), `Bill` (stable `key`, plain summary, optional error `flag`), `CostSummary` (deductible + OOP progress + labeled estimate), `DocumentType` (7), `ExtractedField` (with `lowConfidence`), `CareDocument`, `RequestKind` (4), `RequestState` (3), `CareRequest`, `SavingKind` (4), `MedicationSaving`, `LookingAheadNudge`, `NeedsYouItem`.

### Agent network (`Models/AgentNetwork.swift`, `Models/AgentActivity.swift`)

`WalletCardKind` / `WalletCard` (label + last four only — **never full card data**), `ConnectionGroup` / `Connection` (with `enables` copy), `AgentService`, `ReportLine` / `ReportSection` / `DoctorReport`, `AgentTaskMode` (`automatic` | `needsApproval`), `AgentTaskStatus` (`working` / `waiting` / `scheduled` / `done`), `AgentSource` (label + optional `connectionID` tying it to a linkable account), `AgentTask`.

### Life log (`Models/LifeModels.swift`)

- **`CareEntry`** — kind `meal` ("Meals") / `move` (rawValue "Moves", **displayName "Activity"**) / `med` ("Meds"), title, detail, timestamp, `imageName`, note, optional linked med. `facts` resolves lazily from the image name.
- **`LifeFacts`** — calories, protein, carbs, fat, portion (meals) or minutes (activity). Honest "about" numbers, **never presented as lab truth**.
- **`LifeLibrary`** — `foods` and `activities` browsable libraries (`LibraryItem`: name, image, group), keyword `mealTable` / `moveTable` matchers ordered **most-specific-first**, `factsTable`, `medImage(for:)`, and `matchMeal` / `matchMove` (fallback `walking_shoes_stride` → "Movement").

### Content (`Models/ContentModels.swift`)

- **`CurrentsPiece`** — format `glance` (20 sec) / `read` (3 min) / `watch` (1 min) / `listen` (2 min), kicker, headline, body, scene seed, image, `aiGenerated` flag, server-side `intent` tag (every piece is a nudge by other means), `saved`, `taste` (−1 / 0 / +1).
- **`ConversationTurn`** — role, text, `rich` element, `richResolved`, `streaming`.

---

## 8. Application shell & navigation

### Root switch (`ContentView`)

`LivingGradientView` always renders underneath. Above it, `hasOnboarded` selects `RootView` (opacity + 1.02 scale transition) or `OnboardingFlowView` (opacity), animated with `NudgeSpring.gentle`. Stone Kintsugi begins at 3.0 s fade when already onboarded.

### Shell (`RootView`)

Layers, bottom to top:

1. The active tab scene (fades to 0 opacity when conversation is open).
2. **The minimized orb** — top-right, 34 pt in circular glass, on every tab *except* Today (which has the big orb). Tapping plays `glass` haptic + note and opens the conversation. Label: "Talk with Rumi".
3. **The floating dock** (`NudgeDock`).
4. **`ConversationView`** when open (opacity transition, `matchedGeometryEffect` on the orb).
5. **`CompanionAckToast`** — every log gets a companion response within seconds, **never a mute database write**. Rises from the bottom, tappable to open the conversation seeded with "pattern", auto-clears after 5 s.

Sheets: quick log (`.large` detent), settings, agent network. Full-screen cover: the recap film. Opening the conversation starts the ambient bed.

### The dock (`NudgeDock`)

Five destinations in a single Liquid Glass capsule (iOS 26: `.glassEffect(.regular.tint(Theme.dockTint), in: .capsule)` plus a top-lit white gradient stroke; below: `GlassSurface(radius: 34)`).

| Tab | SF Symbol | Screen |
|---|---|---|
| Today | `sun.haze` | `TodayCanvasView` |
| Care | `cross.case` | `CareHubView` |
| You | `book.closed` | `YouView` |
| Journeys | `leaf` | `JourneysView` |
| Currents | `water.waves` | `CurrentsView` |

Selection is marked **only** by a quiet `warm @16 %` capsule behind the icon — no big sliding pill. Icons switch to `.fill` and medium weight when selected. The Care tab carries a 7 pt `warm` dot badge when `careUnreadCount > 0`, white-ringed, with a scale+opacity transition. Light impact feedback on every tap. **The companion is not in the dock; it lives everywhere.**

---

## 9. Onboarding

`OnboardingFlowView` — "onboarding is a conversation, not a form." Eight stages, over `pastel_gradient_glow_bg` at 92 % opacity plus `OnboardingAura` (drifting pastel light blooms). "Barley Thunder" plays from the first breath at 3.2 s fade, with the music mute always available top-right.

| # | Stage | Requirement |
|---|---|---|
| 1 | `welcome` | The orb breathes into existence at 178 pt inside a nest of light |
| 2 | `aboutYou` | Name & birthday, so records can find you and the greeting can be yours. Pre-filled from Apple sign-in where available; everything editable |
| 3 | `path` | "What are you carrying?" — the pathway choice that shapes the whole experience |
| 4 | `shaping` | The world visibly re-shapes itself; the user *watches the app learn them* |
| 5 | `connect` | `RecordConnectView` — one door, many rails: find provider → sign in → match record → Rumi narrates warmly what it found. Fully skippable |
| 6 | `healthKit` | Purpose-led ask: only the read types actually used, each individually switchable *before* anything connects. **Never the full kitchen sink** |
| 7 | `conversation` | `OnboardingConversationView` — three questions, ninety seconds, zero forms: what matters most, the hardest part, preferred tone |
| 8 | `epsilon` | Separate, explicit, plain consent. **Decline is one equal-weight tap and is respected everywhere** |

Stage transitions are **pure breath** — opacity plus a whisper of scale (0.985 in, 1.012 out). Deliberately no x-offsets, so an interrupted transition can never strand a stage off the screen edge. Each stage is locked to `containerRelativeFrame` so it can never exceed the screen width; it scrolls only if the keyboard compresses height.

On completion: tone is stored, the values and barrier answers become the companion's first two memories, the orb celebrates, bloom sound + haptic fire, the ambient bed crossfades in over 3.0 s, `onboardedAt` is stamped (driving the first-14-days holds), and `justBloomedToday` is set.

---

## 10. Screen-by-screen specification

### 10.1 Today (`TodayCanvasView`)

**Not a dashboard. One living scene.** Composed top to bottom:

1. Header (date, settings/recap chrome).
2. **The orb** — 150 pt `VideoOrbView` with halo, `matchedGeometryEffect(id: "orb")` for the conversation morph, scaling with pull progress.
3. Greeting in Fraunces 28 + persona status line.
4. "pull down to talk" — opacity rises with pull progress.
5. **Care alert banner** when `careUnreadCount > 0` — a gentle line so the user always knows to look, **without it ever feeling like an alarm**.
6. **`AgentActionCard`** — the first pending agentic action: approve or wave off, one equal-weight tap each.
7. **`AgentPulseCard`** — the network's compact presence: what's humming, the first thing waiting, and a door into the whole family. Calm by default, capable when you look.
8. **The Thread** — max 3 `MomentCard`s, or a reassuring "thread resolved" state.
9. **The life strip** — recent meals/activity/meds as `LifeThumb` studio tiles.
10. 150 pt tail so the last row always clears the floating dock.

**The `+` button floats on its own layer**, outside the scroll's offset and melt effects, so it is always exactly where the finger expects. Scroll indicators hidden, bounce always on, whole page scrolls freely from anywhere on screen.

**`MomentCard`** — one organic surface, one clear action, a studio image or soft gradient tile (never a pixel jumble). Swipe to dismiss: it melts away, never to guilt-reappear.

### 10.2 Care — the clinical action center (`Views/Care/`, 12 files)

Calm but utilitarian. Every value carries provenance and freshness; nothing consequential happens without an explicit, equal-weight confirmation.

| Surface | Requirements |
|---|---|
| **`CareHubView`** | Grid of `CareTile`s (icon tile, title, one live status line, optional count; whole tile is the tap target). Hosts the **"Needs you"** band and the `LookingAheadCard`. Consumes `pendingCareDestination` for deep links from Today. |
| **`MessagesView`** | Every care team in one calm inbox. `ModeChip` always states where words actually go — secure in-app thread vs. drafted for the portal. **Nothing sends without an explicit tap.** In `MessageThreadView`, origin context rides along on messages that began elsewhere (a pattern, a result) so the team sees the *why*; attachment provenance renders above the bubble, never buried. User words lean warm and right; team words sit calm and left. |
| **`AppointmentsView`** | Upcoming visits as calm rows: `DateStone` (month + day, warm and tactile), who, where, `KindChip`, `StatusChip`. Detail view offers confirm / reschedule / join / get there / prep, and names the care-plan goal the visit advances. **Telehealth join unlocks only inside the pre-window** (≤ 15 min before to 90 min after). `RescheduleSheet` is a focused pick-a-time-and-confirm. |
| **`TripView`** | Wayfinding: depart-by time, travel minutes, route hint, parking, pre-visit checklist — or a readiness flow for telehealth. Surfaces a known calendar conflict *before it bites* and offers a ride when one helps. |
| **`CarePlanView`** | The care team's plan in plain words, mapped against real life, each goal carrying provenance. Any goal can become a tiny journey — opt-in, user-confirmed, removable. **The derivation is behavioral and never restates or implies a medical instruction the physician didn't give** (`behavioralHabit(for:)` maps goals to "A few minutes of movement", "A quick morning reading", "Refill the water bottle", "Today's prehab set", etc.). |
| **`BillsView`** | The statement in plain language, what counts as "yours" and why, and where you stand on the deductible via a luminous `ProgressBar` — **never red**. `BillDetailView` shows the companion's plain-language read, line items with why-you-owe reasons, and any likely billing error flagged. The app prepares and routes; **the user always authorizes payment. Rumi never stores card details.** |
| **`DocumentsView`** | The paper that runs alongside care, in one private place. Extraction is **always shown for confirmation before it touches the record**; low-confidence fields are flagged, never silently trusted. Provenance ("From your scan") stays visible. `AddDocumentSheet` is an honest typed record where a device scan would auto-fill. |
| **`RequestsView`** | Refills, appointments, records copies and forms, tracked end to end. Each routes the smart way — true in-app channel where supported, otherwise a clean portal draft. A three-step luminous `RequestProgress` rail: submitted → acknowledged → resolved. The user always sees where it went. |
| **`SavingsView`** | Copay cards, patient assistance, cash prices, lower-cost options. **Sponsorship is disclosed but never changes clinical ranking or the neutral answer to "are there other options?"** Applying submits PII only after an explicit, pre-filled confirm. **Rumi never enters or stores payment credentials.** Savings are labeled *estimated* until claims confirm. |
| **`WalletView`** | The cards the companion may use, one-tap approval each time. Only a label and last four ever live here. This is what agentic bill-pay draws from. |
| **`ConnectionsView`** | Link Google (Gmail, Calendar) and channels (iMessage, SMS, Instagram) so the companion becomes omnichannel: read context, reach the user where they already are, still keep everything logged inside the app. Each connection states plainly what it *enables*. The agent family is presented together as one cohesive set of `AgentServiceTile`s. |
| **`ReportsView`** | Per-doctor visit summaries — see §11.3. |
| **`AgentNetworkView`** | The agent network made visible — see §11.1. |

#### The "Needs you" band

Computed live in `AppModel.needsYou`, containing **only** what genuinely needs the user right now, in this order: unread thread replies → an unacknowledged significant result → medications with ≤ 7 days supply → open bills → pending appointment confirmations. When empty it is not a blank — the surfaces show a reassuring line.

`careUnreadCount` is specifically the *new from your care team* signal (unread threads + a freshly-landed result), because refills/bills/appointments already live in the band.

#### Looking ahead (population risk)

`LookingAheadCard` is the **only** patient-facing expression of the prediction model: a population-level screening-and-prevention nudge that routes into a real conversation via a guide question. **Never an individual prediction, probability, or date.** It carries an honest "why am I seeing this" population basis, and is suppressed by opt-out, by crisis, and for the **first 14 days** after onboarding (`showsLookingAhead`).

### 10.3 You — the health story (`Views/You/`, 9 files)

| Surface | Requirements |
|---|---|
| **`YouView`** | Story · Insights as one segmented pair, with the conditions overview, discussion guide and records drawer one tap away. |
| **`StoryTimelineView`** | The record reimagined as narrative — a flowing vertical timeline on an organic curved spine, chapters by year. |
| **`InsightsHubView`** | A calm editorial space — insights as small magazine spreads, not a feed of boxes. Honest epistemics on every pattern. |
| **`ConditionOverviewView`** | What you're carrying, where you are in it, the plan from your team, and what to expect next. Personal without ever feeling like a chart. |
| **`DiscussionGuideView`** | Every question and observation worth ten minutes of a doctor's full attention, captured the moment it happens. **A fresh take on "bring a list": the list writes itself, you just approve it.** |
| **`LabDetailView`** | One metric drawn with light — glow line, soft range band (**never red/green judgment**), scrub lens, companion annotations. |
| **`SeriesExplainSheet` / `ExplainSheet`** | Three-tier disclosure: the reading → the next step → what to ask. Every clinical statement carries a `ProvenanceChip`. |
| **`RecordsDrawerView`** | The conventional browser for when the user wants the raw thing. Every row carries one-tap "What does this mean for me?". `ConflictSheet` presents a calm merged view when sources disagree — **reconciliation is a clinical-safety feature, not hygiene**. |
| **`CareTeamView`** | People, not list rows. Calling or messaging the office is one tap (`callOffice()` opens `tel://`). `VisitPrepView` is a one-screen brief — what's changed, what to ask, what to bring — and **the "ask" list IS the discussion guide, one source of truth**. Every outbound message requires explicit user approval: hard rule. |
| **`RecapPlayerView`** | The Cinematic Recap — a ~30-second film about *them*. Slow Ken-Burns drifts over `recap_dawn` / `recap_path` / `recap_garden`, serif title cards, `music_recap` as the one place the score leads. Earned, rare, skippable. |

### 10.4 Journeys (`JourneysView`)

Where behavior change lives. **No streaks, no broken chains, no guilt** — progress is a growing light-garden. Keeping a habit is one tap: `keepHabit` appends today's date, the orb celebrates, bloom haptic + sound fire. `keptToday(journeyID:habitID:)` gates the affordance. Programs surface here with `SponsorChip` disclosure and a `SponsorExplainSheet` stating in plain language exactly what the sponsor funds and what they receive. Enrolling weaves the program through the whole world (see §17). Declining is one equal-weight tap, remembered, and never re-surfaced in the same form within 90 days.

### 10.5 Currents (`CurrentsView`, `CurrentsPlayerSheets`)

A finite, flowing daily set of 3–7 pieces. Full-bleed scenes, not cards. Four formats with honest durations. **An honest end scene. No infinite feed. Ever.**

- **`ListenSheet`** — listen pieces actually play: a scored, captioned couple of minutes with a living `WaveformView` of breathing bars. The global music bed steps aside while it speaks.
- **`WatchSheet`** — watch pieces play a calm visual: the bubble footage breathing under auto-advancing captions, scored softly. **Captioned by default, always.**

Per-piece controls: save toggle, and a taste signal (`setTaste`) of less / neutral / more that toggles off when re-tapped.

### 10.6 Conversation (`ConversationView`)

**The conversation is a place, not a screen** — a deepened living scene the rest of the app exhales into. The orb holds center stage via the shared `matchedGeometryEffect`. `ConversationScene` layers aurora washes and drifting light motes over the living gradient: atmosphere, not decoration. Stone Kintsugi plays underneath, one tap from silence.

- Companion words land **directly on the canvas** with a soft glow and a breathing tail shimmer while streaming.
- User words float in glass capsules.
- Thinking is a quiet shimmer — never typing dots.
- Rich elements (charts, habit proposals, refill fixes, guide additions, action approvals, program cards) appear 220 ms after the text settles, and resolve with a single tap.
- The input bar's glass is a *background layer* so it never wraps the UIKit-backed text field.
- `VoiceModeView` lives one layer deeper in the same place: the orb takes the whole stage, the user's voice becomes a halo of light, and a `TypewriterText` reveals the transcript character by character so a freshly-heard line reads as if it's being written down live.

### 10.7 Quick Log (`QuickLogView`)

Flow: **what → where (when it matters) → how much → context → and then the part that counts: the companion shows up.**

- Symptom kinds come from the active persona. Kinds with `needsBodyMap` present `BodyMapView` — an abstract figure of light, not an anatomy chart; tap where it lives and the region answers with a glow.
- Severity uses `FluidSeveritySlider`, which morphs color temperature from sage through gold to warm.
- Optional note, optional medication link.
- On submit, `addLog` returns a `SupportPlan`: support message first, then condition-tuned tips, then **paths that actually go somewhere** — add to the discussion guide, draft a note to the office, call, or open a conversation. Elevated severity makes the office the gently-lit path.
- `LifeLibraryPicker` is the browsable, searchable library for meals and activities: the full set is on screen to pick from with most-used choices floating to the top, and the search field pinned at the top for those who'd rather type.

### 10.8 Life (`LifeCatalogView`)

Meals, activity and meds as a **floating magazine gallery**. Every entry is a lifted studio object sitting directly on the living canvas — no boxes — grouped by day with honest little totals.

`LifeEntryDetailView`: tapping an object glides it into its own room — blurred scene for its kind, the big honest number, macro bars that breathe in, warm exits. Drag down anywhere to float back to the table.

`AddEntrySheet`: "logging should feel like telling a friend, not filing a report." Type what it was and **the studio object finds itself while you watch**.

### 10.9 Medications (`MedicationsView`, `MedDetailView`)

The calm list is the surface; full depth is one tap deep. Adherence is a soft `TideView`, never a percentage red-flag. Logging how a med feels lives right there beside the med. Detail carries dose history, a watchlist tuned to the user's conditions, guidance, and refill intelligence with **barrier-first** fixes.

### 10.10 Settings & Privacy (`SettingsView`, `PrivacyCenterView`)

Settings exposes: tone preference, appearance (`Auto` / `Day` / `Night` → `colorSchemeOverride`), five notification classes (Habit moments, Insights, Heads-ups, Logistics, Check-ins), quiet hours (default 21:00–08:00), micro-sound toggle, music toggle, era warmth, the looking-ahead opt-out, epsilon consent, and the **journey previewer** for seeing the whole experience through another life.

**`PrivacyCenterView` — radical transparency, made touchable.** What the companion remembers is not a database list: it's a constellation of big serif realm-words drifting in a loose spatial cluster (`FlowingWords`), the selected one swelling with its count riding as a superscript. Tap a realm and its memories cascade in as glass chips. **Pop any chip and it is actually gone.** Teach it something new from the same breath.

---

## 11. The agent network

Rumi's quiet differentiator: a family of specialized agents always at work, reading across connected sources, doing the safe things itself, and holding the consequential ones for one human tap. **This surface shows the machine working without ever letting it overshadow the calm of the rest of the app.**

### 11.1 The eight agents

| id | Name | Role |
|---|---|---|
| `risk` | Risk watch | Flags possible issues early from your record and history |
| `monitor` | Continuous monitoring | Notices warning signs across your day-to-day |
| `alerts` | Alerts & escalation | Routes time-sensitive things to the right person |
| `scheduling` | Smart scheduling | Books and moves visits around your life |
| `education` | Support & education | A 24/7 voice for questions, coaching and reassurance |
| `pathway` | Care pathway | Walks you through your plan and keeps your team posted |
| `adherence` | Medication adherence | Refills, reminders and insurance navigation |
| `lifestyle` | Lifestyle support | Tiny, sustainable habits tuned to your condition |

Each is individually pausable (`toggleAgentService`). Paused agents' tasks drop out of the Today surfaces.

### 11.2 Task model & surfacing

Every `AgentTask` declares its **mode** (`automatic` = Rumi handles it, or `needsApproval` = "Needs your ok"), its **status** (`working` / `waiting` / `scheduled` / `done`), a human **cadence** ("Always on", "Every morning", "Before June 24", "Just now"), the **sources** it reads, and the **outcome line** that lands when it completes.

`AgentSource` ties to a `Connection.id` when linkable. `FlowSourceChips` renders connected sources as active dots and unconnected linkable ones as a gentle **"Connect"** invitation — the visible thread between data and action. `FlowLayout` is a custom `Layout` providing wrapping chip flow.

Surfacing:
- `agentTasksInMotion` — quiet automatic work happening now (the machine, humming).
- `agentTasksWaiting` — things genuinely waiting on one human tap.
- `AgentPulseCard` on Today shows the count in motion, the first waiting item with inline approve/decline, and a door into the network.
- `AgentNetworkView` → `AgentRow` → `AgentDetailView` → `AgentTaskCard`.

Approving (`approveAgentTask`) marks the task done inside `NudgeSpring.delight`, writes a `companion` `StoryEvent`, surfaces the outcome as an ack toast for 5 s, and fires orb celebrate + bloom haptic + bloom sound. Declining removes it with a light tick.

Roughly 9–11 seeded tasks exist per pathway, each written in empathetic, plain-spoken copy referencing the real data it acts on — e.g. the metabolic *late-statin cramp pattern* ("clustered 4 of 5 times — already drafted as a question for Dr. Patterson"), the oncology *fever rule, always armed*, the procedure *NSAID stop, locked to June 16*, the cardiometabolic *daily weight for fluid* ("a two-pound overnight jump is the heart's first whisper").

### 11.3 Per-doctor reports (`AgentNetwork.reports`)

For every care-team member except pharmacy, over a user-chosen window, the companion builds a clean PDF-style `DoctorReport` with six sections:

1. **Summary** — who this is, prepared for whom, centered on that doctor's focus.
2. **Your numbers** — lab series **re-sorted by relevance to this doctor's role** (`relevance(_:role:)` boosts kidney/eGFR for nephrology, A1c/glucose/pressure for primary and endocrine, counts for oncology, pain for ortho/PT), each with a computed trend line ("down from 7.4", "holding steady").
3. **Medications** — 30-day taken percentage and days on hand.
4. **What <name> has been logging** — symptom logs grouped by kind with an honest severity summary ("mostly mild", "moderate on average", "running high — worth a look"), plus meal and activity counts.
5. **From your wider care team** — every *other* member with a plain line on what they hold. **This is the unifying section: each report leads with one doctor's focus yet cross-references the rest, so everyone shares one picture.**
6. **Worth covering this visit** — unresolved guide items, or "Nothing flagged — a steady stretch."

**Nothing sends without a review.** `sendReport` records the send, writes a story event, and visibly hands the delivery to the `pathway` agent as a completed `AgentTask` ("Delivered your … to <org>"), then acks for 5 s.

### 11.4 Wallet & agentic bill pay

`payBill(_:with:)` marks the bill paid, writes a `companion` story event ("$X from your <card> — done and filed"), acks for 5 s, fires bloom haptic + sound, and persists. Only card label + last four are ever held.

### 11.5 Connections

Five connections, each stating plainly what it enables:

| id | Group | Enables |
|---|---|---|
| `gmail` | google | Flag a bill or result the moment it lands; send on your behalf with one tap |
| `gcal` | google | New appointments and stop-med reminders drop onto your calendar |
| `imessage` | channel | Rumi reaches you with a check-in by text; you can reply back into the app |
| `sms` | channel | Time-sensitive reminders arrive by text wherever you are |
| `instagram` | channel | Daily Currents pieces arrive as saved reels — still logged here |

Connecting synthesizes a plausible account line and fires bloom; disconnecting clears it with a tick.

---

## 12. Logging systems

### 12.1 Life log (`addEntry`)

Three kinds. For meals, `LifeLibrary.matchMeal` resolves an image and a suggested title, and the slot is derived from the hour (5–11 Breakfast, 11–15 Lunch, 15–17 Afternoon, else Dinner). For activity, `matchMove` resolves an image and title with detail "Felt good to move". For meds, the linked medication supplies name, dose and image. Entries insert at index 0 inside `NudgeSpring.ui`, fire success haptic + send note, and persist immediately.

### 12.2 The activity illustration set

Twenty-four activities across four groups, each mapped to its own clay-render illustration in the shared editorial style (soft sculpted matte clay, warm dawn palette, arched hazy pastel backdrop, gentle inner glow, centered single subject):

| Group | Activities → illustration |
|---|---|
| **Moving** | Walk / Evening walk / Morning walk → `walking_shoes_stride`; Hike → `hiking_boots_walking_pole`; Bike ride / Cycling → `clay_bicycle`; Swim → `water_ripples_goggles`; Treadmill → `clay_treadmill`; Stairs → `clay_stairs_glow` |
| **Gentle** | Yoga → `yoga_mat_bolster`; Stretching → `clay_figure_stretching`; Pilates → `pilates_ring_and_mat`; Tai chi → `clay_figure_tai_chi`; Breathing → `glowing_clay_orb`; Dance → `clay_figure_dancing` |
| **Strength** | Strength training → `clay_dumbbells`; Resistance bands → `resistance_band_clay`; Light weights → `kettlebell_clay`; Quad sets → `leg_quad_extension`; Physical therapy → `hands_supporting_knee` |
| **Around home** | Gardening → `hands_planting_sprout`; Yard work → `leaf_rake_with_pile`; Housework → `broom_dustpan`; Standing desk → `standing_desk_workspace` |

Each carries a `LifeFacts` effort estimate (portion phrase + minutes), e.g. `walking_shoes_stride` = "an easy pace" / 25 min, `hiking_boots_walking_pole` = "on the trail" / 50 min, `clay_stairs_glow` = "flight by flight" / 12 min.

`moveTable` keyword matching is ordered **most-specific-first** — physical therapy → quad → bands → kettlebell → strength → desk → yard → garden → house → treadmill → stairs → hike → swim → bike → dance → tai chi → breath → pilates → stretch → yoga → walk — so "light weights" never falls into generic "strength". The four legacy image names are retained in `factsTable` for back-compatibility with previously logged entries.

### 12.3 Symptom log (`addLog`)

Kind, severity, timestamp, optional note (empty coerced to nil), optional body region, optional med link. Persists, then returns a persona- and severity-tuned `SupportPlan`. `logs(near:)` retrieves everything anchored to one medication — patterns need anchors.

### 12.4 Held moments

`addMemory(photoFilename:caption:)` inserts a `MemoryGlimpse` at index 0 inside `NudgeSpring.delight`, celebrates, blooms and persists. `saveMemoryPhoto(_:)` writes a captured photo to the app's Documents container as `memory_<uuid>.jpg` and returns the filename; failures are logged and return nil.

### 12.5 Discussion guide

`addGuideItem` de-duplicates by text, inserts at 0 inside `NudgeSpring.ui`, fires success haptic + tick, and persists. Items can be toggled resolved or removed. Sources are stamped ("Drafted in conversation · Jun 16", "Quick log", "Lab detail").

---

## 13. Services & platform integrations

| Service | Responsibility |
|---|---|
| **`CompanionAI`** | Streaming SSE client for the Rork AI gateway. Bearer-auth with the public toolkit key, line-by-line SSE parse, deltas delivered on the main actor. `nonisolated` Codable wire types. |
| **`VoiceSession`** | The hands-free voice loop (§5). |
| **`SoundEngine`** | The three-layer score (§4). |
| **`SubjectLifter`** | Vision-based foreground-instance masking with memory + disk caching (§4). `nonisolated` static workers on a detached user-initiated task. |
| **`PersistenceService`** | One ISO-8601 JSON document (`sano_user_data.json`) in the app's own container. Private, exportable, deletable. Atomic writes; decode failures log and return nil rather than crashing. |
| **HealthKit** | Purpose-led read-only ask during onboarding, each type individually switchable before anything connects. Referenced by monitoring agents as the "Apple Health" source. |
| **AVFoundation** | Music beds, tap notes, SFX, recap score, voice record + playback, orb video via `AVPlayerLayer`. |
| **Metal** | `Orb.metal`, `LivingGradient.metal`, `Effects.metal` (ripple, touch glow, melt, light sweep). |

---

## 14. Backend (Cloudflare Worker)

`functions/index.ts` — a minimal, private voice proxy. Its sole purpose is to keep `ELEVENLABS_API_KEY` off the client.

| Route | Method | Behavior |
|---|---|---|
| `/ping` | GET | `{ ok: true, now: <ISO> }` |
| `/voice/stt` | POST | Streams the multipart body to `https://api.elevenlabs.io/v1/speech-to-text` with `xi-api-key`. Response body streamed straight back. |
| `/voice/tts` | POST | JSON `{ text, model_id?, voice_settings? }` → `…/v1/text-to-speech/{RUMI_VOICE_ID}?output_format=mp3_44100_128`. Voice id `L0yTtpRXzdyzQlzALhgD`. Defaults: `eleven_turbo_v2_5`, stability 0.48, similarity boost 0.82, style 0.2, speaker boost on. |
| `*` | any | `404 { ok: false, error: "Not found" }` |

Requirements: permissive CORS on every response (`*` origin, GET/POST/OPTIONS, Content-Type + Authorization headers), `OPTIONS` short-circuits to 204, `set-cookie` stripped from upstream responses, missing key returns a clean `503 { ok:false, error:"ElevenLabs is not configured." }`, empty text returns `400`.

Deployed at `https://nudge-plus-d9rx5y5-backend.rork.app` (the iOS fallback when `EXPO_PUBLIC_RORK_FUNCTIONS_URL` is empty).

---

## 15. Web app (Rumi web mirror)

`web/` — Vite + React 18 + TypeScript (strict) + Tailwind + shadcn/ui, ~6 700 LOC under `src/sano/`.

### Shell

`SanoApp.tsx` renders an ambient wash (`#070A18` night / `#EDE2D2` day) behind a centered **440 pt device column** at `100dvh` with a deep drop shadow. Inside: `LivingGradient` + `RippleLayer`, then either `Onboarding` or `RootShell`. `SoundEngine.unlock()` binds to the first `pointerdown` (browser autoplay policy).

`RootShell` mirrors iOS exactly: five tab screens, the minimized orb top-right on every tab except Today, the `Dock`, the `Conversation` overlay, the `AckToast`, and `Sheet`-hosted quick log / settings / agent network, plus the full-screen `Recap`.

### Structure

| Area | Files |
|---|---|
| **Screens** | `Today`, `Care` (575 LOC), `You`, `Journeys`, `Currents`, `Conversation` (370 LOC), `QuickLog` (388 LOC), `Onboarding`, `Settings`, `Recap`, `AgentNetwork`, plus `shared.tsx` (450 LOC) and `nav.tsx` |
| **UI primitives** | `Orb`, `Dock`, `Glass`, `Sheet`, `Icon`, `LivingGradient`, `DataViz` |
| **State** | `store.tsx` (733 LOC) — a single `SanoProvider` context with `useSano()` accessor; persists to `localStorage` under `sano.web.v1` |
| **Data** | `types.ts` (415), `fixtures.ts` (593), `careBundles.ts` (221), `agentNetwork.ts` (293), `lifeLibrary.ts` (198) |
| **Services** | `ai.ts` (streaming chat, `parseTags`, hold-back filter, `localReply`), `sound.ts` (SoundEngine + Haptics via the Vibration API), `theme.ts` |

### Parity requirements

- `theme.ts` mirrors the iOS `Theme` **hex-for-hex**, including all four time-of-day gradient windows, the conversation palette, companion colors and orb halo.
- `types.ts` mirrors the Swift domain model; `store.tsx` mirrors `AppModel`'s actions and derived values (`needsYou`, `careUnreadCount`, agent task partitions, report building).
- The same audio files are served from `web/public/audio/` and the same orb footage from `web/public/orb/`.
- Images resolve through an `img()` helper: `condition_*`, `currents_*` and `recap_*` are `.jpg`; everything else is `.png`.

### Known parity gap

The 21 new activity illustrations are bundled in iOS `Assets.xcassets` but are **not yet mirrored** into `web/public/img/`, and `web/src/sano/lifeLibrary.ts` still maps activities to the four legacy images (`terracotta_cream_sneakers`, `yoga_mat_rolled`, `dumbbells_towel_wellness`, `soft_editorial_studio`). Closing this requires downloading the 21 PNGs and porting the `activities` / `moveTable` / facts tables.

---

## 16. Asset inventory

### iOS `Assets.xcassets` — 64 illustration imagesets

All illustrations share one editorial style: soft sculpted matte clay render, warm dawn palette (terracotta / peach / cream / sage), arched hazy pastel sunset backdrop, gentle warm inner glow, single centered subject, square, no text.

| Family | Assets |
|---|---|
| **Activity (21)** | `walking_shoes_stride`, `hiking_boots_walking_pole`, `clay_bicycle`, `water_ripples_goggles`, `clay_treadmill`, `clay_stairs_glow`, `yoga_mat_bolster`, `clay_figure_stretching`, `pilates_ring_and_mat`, `clay_figure_tai_chi`, `glowing_clay_orb`, `clay_figure_dancing`, `clay_dumbbells`, `resistance_band_clay`, `kettlebell_clay`, `leg_quad_extension`, `hands_supporting_knee`, `hands_planting_sprout`, `leaf_rake_with_pile`, `broom_dustpan`, `standing_desk_workspace` |
| **Activity (legacy, retained)** | `terracotta_cream_sneakers`, `yoga_mat_rolled`, `dumbbells_towel_wellness` |
| **Meals (6)** | `oatmeal_bowl_blueberries`, `yogurt_parfait_glass`, `vegetable_omelette_plate`, `grain_bowl_chicken_quinoa`, `grilled_salmon_lemon_greens`, `lentil_soup_bowl`, plus `ceramic_bowl_glow`, `cozy_dinner_table` |
| **Symptoms (10)** | `knee_joint_pain`, `leg_cramp_muscle`, `belly_stomach_relief`, `hand_sparkles_tingling`, `lips_mouth_tender`, `joint_swelling_glow`, `hinge_joint_clay`, `clay_head_silhouette_glow`, `thermometer_warmth`, `moon_waves_stars_sleep` |
| **Meds (3)** | `blister_pack_tablets`, `medicine_bottle_pills`, `medicine_bottle_tablets` |
| **Currents (5)** | `currents_a1c`, `currents_kidney`, `currents_salt`, `currents_walk`, `currents_father_son` |
| **Conditions (3)** | `condition_diabetes`, `condition_chemo`, `condition_procedure` |
| **Recap (3)** | `recap_dawn`, `recap_path`, `recap_garden` |
| **Atmosphere / UI (9)** | `pastel_gradient_glow_bg`, `soft_editorial_studio`, `soft_editorial_3d`, `spiral_light_mist`, `thread_unwinding_light`, `glowing_orb_in_leaves`, `tree_path_sunset_walk`, `gift_box_sprout`, `notebook_speech_bubble_star`, `calendar_heart_stethoscope`, `open_folder_documents` |

Plus `AppIcon.appiconset` and `AccentColor.colorset`.

### iOS `Resources/` — 18 media files

| Group | Files |
|---|---|
| **Music** | `music_barley_thunder.m4a` (onboarding), `music_stone_kintsugi.m4a` (the world), `music_recap.mp3` (the recap film), `music_ambient_bed.mp3` |
| **Tap notes** | `tap_ta_1…5.mp3` — a child singing "ta" at five chords |
| **SFX** | `sfx_bloom.mp3`, `sfx_whoosh.mp3`, `sfx_glass.mp3`, `sfx_tick.mp3` |
| **Orb footage** | `orb_day.mp4`, `orb_night.mp4`, `orb_speak.mp4`, `orb_think.mp4`, `orb_bloom.mp4` |

### Fonts — 6 files

`Fraunces-400.ttf`, `Fraunces-500.ttf`, `Fraunces-600.ttf`, `Fraunces-700.ttf`, `Fraunces-400-italic.ttf`, `HermioneFREE.ttf`.

### Shaders — 3 Metal files

`Orb.metal`, `LivingGradient.metal`, `Effects.metal`.

### Web `public/`

45 images in `img/` (jpg for condition/currents/recap, png otherwise), 12 audio files in `audio/`, 5 orb videos in `orb/`, 6 fonts in `fonts/`, plus `favicon.png` / `icon.png`.

---

## 17. Persistence & state

### Single store

`AppModel` (`@Observable`, 1 158 LOC) is the one data spine, injected via `.environment(model)` at the root. Persona fixtures live in code and merge on load. Views read from `AppModel` and never hold duplicate copies of shared data.

### `UserDefaults` keys

`nudge.hasOnboarded`, `nudge.onboardedAt`, `nudge.tone`, `nudge.epsilon`, `nudge.eraWarmth`, `nudge.sound`, `nudge.music`, `nudge.appearance`, `nudge.lookingAheadOptOut`, `nudge.pathway`, `nudge.profile` (JSON), `nudge.resultAck.<pathway>`.

### JSON document (`sano_user_data.json`)

`SanoUserData` persists **everything the user creates**: pathway, life entries, symptom logs, held moments, guide items, memory notes, message threads, requests, documents, paid bill keys, and derived journey goals. Loaded only when the saved pathway matches the active one; non-empty collections override fixtures; paid bills are re-applied by stable `key`. `persistUserData()` is cheap enough to call on every write, and is.

### Closed-loop side effects

Enrolling in a program (`enroll`) demonstrates the "loop closes visibly" requirement — a single tap produces: a first-step `Moment` on Today (if under the cap of 3), a new `Journey` with a two-minute habit, a pending `AgentAction` to set it up, a `MemoryItem` recording the enrollment, plus orb celebrate + bloom haptic + bloom sound.

Similarly, `confirmAppointment` replaces any prior task for that appointment and inserts a completed `scheduling` agent task sourced to Google Calendar, so the follow-through is visibly owned.

---

## 18. Privacy, safety & governance laws

These are encoded in code and are treated as requirements, not guidelines.

### Consent & confirmation

1. **Nothing consequential happens without an explicit, equal-weight confirmation.** Decline is never smaller, greyer or slower than accept.
2. **Nothing sends without you.** Every outbound message, report, referral note and request requires explicit approval. `sendMessage` is only ever reached from a confirmed compose UI.
3. **Epsilon consent is separate, explicit and plain**, and declining is respected everywhere.
4. **HealthKit is purpose-led** — only the read types actually used, each individually switchable before anything connects.
5. **Extraction is confirmed before it touches the record.** Low-confidence scanned fields are flagged, never silently trusted.
6. **Applying for savings submits PII only after an explicit, pre-filled confirm.**

### Payments

7. **The app never enters or stores payment credentials.** Wallet holds a label and last four only. The app prepares and routes; the user authorizes.

### Clinical safety

8. The companion **never diagnoses, never adjusts doses, never contradicts the care team.**
9. **Oncology: ≥ 100.4 °F is a call-now, any hour.** Non-negotiable, stated calmly.
10. **Procedure: NSAIDs stop June 16; acetaminophen stays safe.**
11. **Reference bands are never red/green judgment colors.** Attention is warm luminance.
12. **Source conflicts get a calm merged reconciliation view** — a clinical-safety feature, not hygiene.
13. Care-plan → journey derivation is **behavioral only** and never restates or implies a medical instruction the physician did not give.

### Prediction

14. The **only** patient-facing expression of the prediction model is a population-level screening-and-prevention nudge that routes to care. **Never an individual prediction, probability, or date.**
15. It carries an honest population "why am I seeing this" basis.
16. It is suppressed by opt-out, by crisis, and for the **first 14 days** after onboarding.

### Sponsorship

17. Sponsorship is always disclosed in plain language, with a sheet stating exactly what the sponsor funds and what they receive.
18. **Sponsorship never alters clinical eligibility, ranking, or the neutral answer to "are there other options?"**
19. The user-visible experience never differs by funding status except the disclosure chip.
20. A declined program never re-surfaces in the same form within 90 days.

### Transparency & data ownership

21. **Every clinical statement carries a provenance chip.** Trust is a design primitive, rendered beautifully, never as legal lint.
22. Message channel mode is always visible — the user knows where their words go.
23. Savings and cost figures are labeled *estimates* until claims confirm.
24. What the companion remembers is **fully visible and individually deletable** in the Privacy Center — popping a memory chip actually deletes it.
25. All user data lives in the app's own container in one exportable, deletable JSON document; `PersistenceService.wipe()` removes it entirely.
26. Errors are logged with sanitized, prefixed messages (`[Sano]` / `[Rumi]`) and never expose secrets or PII.

---

## 19. Accessibility

- Every interactive element has an explicit `accessibilityLabel` (e.g. "Talk with Rumi"; dock items announce "Care, 2 new"), and selected tabs carry `.isSelected`.
- Decorative imagery is `accessibilityHidden(true)` — including every `LiftedImage`.
- The orb exposes a human-readable state via `OrbState.accessibilityDescription` ("calm", "listening", "here with you").
- `sensoryFeedback` is used for system-level haptic parity alongside the explicit `Haptics` vocabulary.
- Watch/listen Currents pieces are **captioned by default, always**.
- System fonts with Dynamic Type for all rounded/number styles; bundled faces used only for display and serif voices with a graceful system-serif fallback.
- Touch targets meet the 44 × 44 pt minimum; standard 16–20 pt horizontal margins.
- Native controls (`Button`, `Toggle`, `Picker`) are preferred over custom equivalents; `Button` is used for every tappable element rather than bare tap gestures.

---

## 20. Configuration & environment

### Public (client-tier) variables

Exposed to Swift through the auto-generated `Config.swift` and consumed via `Utilities/AppConfig.swift`:

| Variable | Use | Fallback |
|---|---|---|
| `EXPO_PUBLIC_TOOLKIT_URL` | AI gateway base | `https://toolkit.rork.com` |
| `EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY` | Gateway bearer token (publishable tier) | — |
| `EXPO_PUBLIC_RORK_FUNCTIONS_URL` | Voice proxy base | `https://nudge-plus-d9rx5y5-backend.rork.app` |
| `EXPO_PUBLIC_PROJECT_ID`, `EXPO_PUBLIC_RORK_API_BASE_URL`, `EXPO_PUBLIC_RORK_AUTH_URL`, `EXPO_PUBLIC_TEAM_ID` | Platform plumbing | — |

Derived constants: `chatModel = "anthropic/claude-sonnet-4.6"`, `voicePath = "/voice/tts"`.

### Private (server-only)

`ELEVENLABS_API_KEY` — bound to the Cloudflare Worker only. **It never ships in the app bundle**; the companion's spoken voice is held behind the proxy.

`Config.swift` literals are intentionally empty in source control; real values are injected at iOS build time.

---

## 21. Build, validation & known constraints

### Validation

| App | Command | Notes |
|---|---|---|
| iOS | `runChecks({ appPath: "ios" })` | Real Swift/iOS build via the build service. Currently **green**. |
| Web | `runChecks({ appPath: "web" })` | Static checks + `bun run build` → `dist`, publishes a preview URL. Preview: `https://ssq8oqlhr5rl7tb9wztaq-web.rork.live` |
| Functions | Deployed Worker | `https://nudge-plus-d9rx5y5-backend.rork.app` |

Package manager is **bun** throughout; iOS uses no third-party SPM packages — everything is first-party Apple frameworks plus Metal.

### Platform constraints

- **iOS 18 minimum.** Every iOS 26 API (`glassEffect`, native glass lens) is behind `#available(iOS 26.0, *)` with a layered-material fallback.
- **Concurrency:** the project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. UI types stay isolated; pure data and background workers (`AIChatMessage`, `StreamChunk`, `VoiceScribeResponse`, `CompanionAIError`, `SubjectLifter` static workers, `CompanionEngine.parse`) are explicitly `nonisolated`.
- **Never layer Metal effects over Liquid Glass** — renders placeholders on iOS 26.
- **Voice requires a real microphone.** In the cloud simulator the recorder surfaces a warm `unavailable` message directing the user to install on device via the Rork app, rather than faking a session.
- **Audio session must be `.playback`** (not `.ambient`) or the entire score is muted by the device's silent switch on real hardware.

### Open items

1. **Web activity-illustration parity** — port the 21 new PNGs and the `lifeLibrary.ts` tables (see §15).
2. The "Activity" chooser row in `QuickLogView` still uses the legacy `yoga_mat_rolled` tile art (intentionally untouched during the activity-illustration pass).

### Historical specification lineage

Earlier requirement documents remain in the repository for reference and are superseded by this document: `Nudge_iOS_Build_Spec_v4.md` (root), `tmp/Nudge_v3_spec.md`, `tmp/v5_spec.md`. Section markers such as §4.4, MSG-3, BILL-4, DOC-4, SAV-3, APT-6, PRD-1…6, ENG-3, REC-5, ACT-2 appear throughout the code as inline traceability to those specs; this document restates each of those rules in §18 and §10.
