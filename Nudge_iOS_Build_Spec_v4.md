# SANO (formerly NUDGE) — iOS App Build Specification & Requirements
### The AI Behavioral Health Companion · As-built spec for an agentic coding model (Claude in Rork)
**Amalgam Rx × Publicis Groupe · June 2026 · v4 (condition-adaptive personas, voice pipeline, audio identity, rebrand to "Sano", as-built verification) · Confidential**

> **How to use this document:** v4 supersedes v3. It keeps v3's product, design, and engineering law intact as the north star, and layers on (a) everything that was added or changed since v3, and (b) a code-level verification of what is actually built in the iOS project. Sections marked **[v4 NEW]** are net-new since v3. Every requirement now carries a **Build status** tag so the team can see, at a glance, what is shipped, what is mocked, and what remains. When in doubt, the design principles in §5 and the companion rules in §7 still win over any convenience shortcut.

> **Build-status legend (used throughout):**
> - ✅ **Implemented** — present and functional in the iOS code against fixture data.
> - 🟡 **Partial** — present but scoped down, or some sub-requirements missing.
> - 🟦 **Mocked** — the UX is fully built but the underlying integration is simulated (no live external system).
> - ⛔ **Not yet** — specified, not yet built.

---

# 0 · What Changed in v4 (read first) **[v4 NEW]**

This section is the v3 → v4 changelog. Everything here is verified against the iOS source in `ios/Nudge/`.

### 0.1 The product is now named **Sano**
The companion and the brand are **"Sano"** across all user-facing copy, the wordmark, the onboarding ("Talk with Sano"), and internal log tags (`[Sano]`). The Xcode **target/product is still `Nudge`** (folder `ios/Nudge/`, scheme `Nudge`) — only the user-facing brand changed. "Sano" is short, warm, two-syllable, health-rooted (Latin *sanare*, to heal), and ends in a vowel — matching the viral-consumer naming pattern requested. Wherever this document says "the companion," read "Sano."

### 0.2 Condition-adaptive personas became a first-class architecture pillar
v3 designed everything around one reference user (Marcus, T2D). v4 generalizes the entire experience around a **care pathway** the user selects at onboarding, and re-shapes symptoms, metrics, medications, care plan, journey phases, content, recap, and the companion's clinical responses to fit. Three full personas ship as fixtures:
- **Marcus** — Metabolic (Type 2 diabetes, hypertension, CKD-2).
- **Elena** — Oncology (breast cancer, AC-T chemotherapy, cycle 3 of 6).
- **Sam** — Procedure (total knee replacement, 12 days post-op).

Switching pathway re-seeds the whole world (`AppModel.switchPathway`). This is the single biggest structural addition since v3. Full spec in **§3.0**.

### 0.3 The companion is wired to a real LLM + real voice loop
- **Text + voice brain:** Anthropic **Claude Opus 4.8** (`anthropic/claude-opus-4.8`) via the Rork Toolkit gateway, streamed over SSE.
- **Voice mode:** real microphone → **ElevenLabs Scribe (`scribe_v2`)** speech-to-text → Claude Opus 4.8 → **ElevenLabs Turbo (`eleven_turbo_v2_5`)** text-to-speech (voice "Rachel", warm mid-register), with the orb driven by mic level and TTS playback.
- All calls route through `https://toolkit.rork.com` with a bearer toolkit key. Full spec in **§7.5** and **§10.11**.

### 0.4 A real audio identity (the score) shipped
- **Beds:** *Barley Thunder* under onboarding; *Stone Kintsugi* as the ambient bed for the rest of the app and Currents Listen/Watch; a dedicated recap score.
- **Micro-instrument:** five sung pentatonic "ta" notes (`tap_ta_1…5`) that compose a melody as the user taps — taps make music, not UI blips.
- Crossfaded beds, a global mute, silent-switch-through playback. Full spec in **§6.8**.

### 0.5 A distinctive two-voice type system shipped
- **Display voice:** **Hermione** (elegant curved serif) for the Sano wordmark and big title moments.
- **Serif reading/meaning voice:** **Fraunces** (400/500/600/700 + italic) for insight headlines, Currents Reads, story chapters, recap title cards.
- **Function voice:** SF Pro Rounded + monospaced digits. Full spec in **§6.4**.

### 0.6 New modules added beyond v3's P0 list
- **Life Catalog [v4 NEW]** — a magazine-style gallery of meals / movement / meds rendered as subject-lifted "studio object" photos, grouped by day, with detail "rooms." See **§3.16**.
- **Condition Overview [v4 NEW]** — a calm surface that holds the user's conditions, care-plan-from-the-doctor, phase arc, and what-to-expect. See **§3.17**.
- **Discussion Guide [v4 NEW]** — a self-writing visit guide of questions + observations with send-ahead approval. See **§3.18**.
- **Agentic action cards [v4 NEW]** — Sano proposes actions; the user approves/declines; "nothing sends without you." See **§7.8**.

### 0.7 Known gaps carried into v4 (honest status)
- **EHR/record connection and HealthKit are fully designed but mocked** (no live FHIR/HealthKit reads). 🟦
- **Omnichannel (Photon Spectrum / iMessage / WhatsApp)** is not built. ⛔
- **Brain Vault MCP server** is not built (Privacy Center surface exists). ⛔
- **Sponsored eligibility engine** clinical-gate logic is fixture-scripted, not a live rules engine. 🟡
- **Persona "AI" clinical support responses** in Quick Log are fixture-scripted (`supportPlan`), not live-LLM. 🟡
- **Security note:** the toolkit key is currently a hardcoded literal in `AppConfig.swift`. It works in-sandbox (publishable-tier key) but should move to an injected config before any real-world release.

---

# 0.8 · Code Map (where everything lives) **[v4 NEW]**

```
ios/Nudge/
├── NudgeApp.swift              @main; font registration; scene-phase bed control
├── ContentView.swift           living-gradient ground + global tap ripple; onboarding↔root switch
├── Models/
│   ├── CareProfile.swift       CarePathway, Persona, CarePlan, SymptomKind, BodyRegion, SupportPlan, GuideItem
│   ├── PersonaFixtures.swift   Marcus / Elena / Sam full corpora + supportPlan() scripted clinical brain
│   ├── MarcusFixtures.swift    deep metabolic fixture corpus (labs, meds, programs, currents)
│   ├── EngagementModels.swift  Moment, Insight, Journey, AtomicHabit, Program, SymptomLog, StoryEvent
│   ├── ContentModels.swift     CurrentsPiece (4 formats), ConversationTurn + Rich inline elements
│   ├── LifeModels.swift        CareEntry (meal/move/med), LifeLibrary image matcher, AgentAction, MemoryGlimpse, UserProfile
│   └── RecordModels.swift      LabSeries, RecordItem (+conflict), Medication (tide), CareTeam, Appointment, Consent
├── Services/
│   ├── CompanionAI.swift       SSE streaming client → Claude Opus 4.8 via toolkit gateway
│   ├── VoiceSession.swift      mic → Scribe STT → Opus → ElevenLabs TTS; drives orb
│   ├── SoundEngine.swift       beds, ta-note melody, SFX, recap score, mute
│   ├── SubjectLifter.swift     Vision foreground-mask cutout for the Life "studio object" look
│   └── PersistenceService.swift local JSON document store
├── ViewModels/
│   ├── AppModel.swift          the single @Observable data spine + all actions
│   ├── CompanionEngine.swift   grounded system prompt builder + tag parser + side effects
│   └── OrbState.swift          companion mood state machine
├── Shaders/  Orb.metal · LivingGradient.metal · Effects.metal (melt/ripple/lightSweep/touchGlow)
├── Utilities/ AppConfig · Theme · NudgeType · NudgeSpring · Haptics · Glossary
├── Views/
│   ├── Components/ (14)  OrbView, VideoOrbView, LivingGradientView, GlassSurface, MemoryOrbView,
│   │                     RippleEffect, MeltModifier, GlowChart, TideView, LightGardenView,
│   │                     SceneVisual, NudgeDock, ProgressiveBlur, Chips
│   ├── Today/  TodayCanvasView, MomentCard
│   ├── Conversation/  ConversationView, VoiceModeView
│   ├── Onboarding/  OnboardingFlowView, OnboardingConversationView, RecordConnectView
│   ├── Currents/  CurrentsView, CurrentsPlayerSheets
│   ├── Life/  LifeCatalogView
│   ├── Log/  QuickLogView, BodyMapView
│   ├── Meds/  MedicationsView, MedDetailView
│   ├── Insights/  InsightsHubView
│   ├── Journeys/  JourneysView (+ programs engine)
│   ├── Settings/  SettingsView, PrivacyCenterView
│   ├── You/  YouView, StoryTimelineView, RecapPlayerView, DiscussionGuideView,
│   │          ConditionOverviewView, CareTeamView, RecordsDrawerView, LabDetailView, ExplainSheet
│   └── RootView.swift   post-onboarding shell (5 tabs + dock + orb + conversation overlay)
├── Resources/  music_barley_thunder · music_stone_kintsugi · music_recap · orb_*.mp4 · sfx_* · tap_ta_1…5
└── Fonts/  Fraunces-400/500/600/700/-italic · HermioneFREE
```

---

# 1 · Product Context (unchanged from v3, summarized)

Sano is a consumer iOS app — the patient-facing surface of the five-layer platform (L1 multi-rail clinical data · L2 plain-language knowledge · L3 Epsilon personalization · L4 care pathways + sponsored programs · L5 behavioral AI companion). The hero is the **companion**. Everything else is supporting cast. (Full L1–L5 detail unchanged from v3 §1.)

**Reference users (v4):** three pathways now anchor design decisions — **Marcus** (metabolic), **Elena** (oncology), **Sam** (procedure). If a screen would make any of them feel lectured, judged, or confused, the screen is wrong.

---

# 2 · Competitive Teardown (unchanged from v3)

No change. Healthie / Lotus / Novellia teardown, table-stakes synthesis, and "the open space Nudge owns" remain as v3 §2.

---

# 3 · Feature Requirements & Module Specs

Priority key: **P0** = MVP launch blocker · **P1** = fast-follow · **P2** = later. Build-status tags per §0.8 legend.

## 3.0 Condition-Adaptive Care Pathways (P0) **[v4 NEW]** — ✅ Implemented

The whole experience adapts to the user's clinical reality. A **`CarePathway`** (`metabolic` / `oncology` / `procedure`) selected at onboarding seeds a **`Persona`** that supplies condition-specific:

- **Conditions list** and a friendly one-line framing (never a cold diagnosis banner).
- **Phase arc** — where the user is in their journey (e.g. oncology "Cycle 3 of 6"; procedure "12 days post-op / early recovery").
- **What-to-expect** items tuned to the phase (chemo side-effect windows; post-op milestones; metabolic steadiness).
- **Symptom kinds** with condition-appropriate severity scales and body-map need (`SymptomKind.needsBodyMap`): e.g. oncology surfaces nausea/neuropathy/fever; procedure surfaces incision pain/swelling/range-of-motion; metabolic surfaces dizziness/glucose/foot checks.
- **Metrics & labs** (oncology: ANC/neutrophils; metabolic: A1c/eGFR/BP/LDL; procedure: pain & range-of-motion).
- **Medications**, **care team**, **appointments**, **journeys**, **insights**, **story**, **Currents**, and **moments**.
- **The scripted clinical brain** (`PersonaFixtures.supportPlan(pathway:kind:severity:)`): severity-gated, condition-aware responses — e.g. **oncology fever ≥100.4°F → urgent "call your team now" path**; metabolic late-day statin-cramp pattern; procedure NSAID-timing caution.

> **Code:** `Models/CareProfile.swift`, `Models/PersonaFixtures.swift`, `AppModel.switchPathway(...)`. Settings includes a **persona previewer** so the team (and alpha users) can switch pathways and see the adaptation live.

**Acceptance:** changing pathway must change symptoms, metrics, meds, plan, content, and the companion's clinical responses — verified by `switchPathway` re-seeding every store.

## 3.1 Onboarding & Identity (P0) — 🟡 Partial (UI ✅ / connect 🟦)

The onboarding is a conversation, not a form, and now **captures identity and selects a pathway**.

1. **Welcome** — full-bleed living gradient; the orb (real-footage `VideoOrbView`) breathes into existence; Hermione wordmark "Sano." (Sign in with Apple is specified; not yet wired.) ✅ scene / ⛔ Apple auth
2. **About You [v4 NEW]** — captures **first name, last name, and date of birth** (`AboutYouView`) — the basis for matching hospital records and for warm address. ✅
3. **Path choice [v4 NEW]** — the user picks their care pathway; `ShapingView` narrates how Sano adapts to it. ✅
4. **The first conversation (90s)** — 3 streamed questions: what matters most (values), what's hardest (barriers), how Sano should speak (tone). ✅ (`OnboardingConversationView`, live-streamed via Claude)
5. **Record connection** — single Connect door: pick provider → portal sign-in → record match → progressive discovery narration. 🟦 **Mocked** (sets `connectedSystems` flags; no live FHIR).
6. **HealthKit** — purpose-scoped permission screen with the exact read types. 🟦 **Mocked** (sets `healthConnected`; no live HealthKit reads).
7. **Epsilon consent** — dedicated plain-language screen, equal-weight decline. ✅
8. **First Light** — onboarding ends on the Today canvas with one personally meaningful moment already present. ✅

**Acceptance (v4):** zero forms with >3 visible fields; every permission individually declinable; pathway + name + DOB captured before First Light. The live EHR/HealthKit rails remain a fast-follow.

## 3.2 The Companion (P0) — ✅ Implemented (full spec §7)

## 3.3 Home — "Today" Canvas (P0) — ✅ Implemented

A living scene, not a dashboard (`TodayCanvasView`):
- **Top:** the orb in ambient state (real-footage `VideoOrbView`) over the living gradient.
- **The Thread:** 1–3 `MomentCard`s (hard cap 3), swipe-to-dismiss with the **melt shader** dissolve, never guilt-reappearing.
- **Pull-to-talk:** pulling down stretches the scene and drops into conversation. ✅
- **Agentic action card [v4 NEW]:** when Sano has proposed an action, a glass card sits on Today with approve/decline and the line "Nothing sends without you." ✅
- **Life strip [v4 NEW]:** a horizontal row of recent meals/moves/meds as lifted studio images. ✅
- **Quick-log "+":** a glowing button into the 3-tap log. ✅
- **Condition chip + music mute** in the chrome. ✅
- **Dock:** floating liquid-glass dock — **Today · Life · You · Journeys · Currents** (note: v4 ships **five** destinations; "Life" was added since v3's four). The orb persists minimized on non-Today tabs ("Talk with Sano"). ✅

## 3.4 "You" — The Health Story (P0) — ✅ Implemented (Body view 🟡)

`YouView` is a NavigationStack hub with a Story · Insights segmented control and quick-door chips (conditions, guide w/ badge, care team, meds) plus a records link.
- **Story view** — curved-spine narrative timeline of diagnoses, results, visits, milestones, companion-caught moments (`StoryTimelineView`). ✅
- **Cinematic Recap** — **"Play your chapter" actually plays** (`RecapPlayerView`): 4 per-persona title-card chapters with Ken-Burns drift over `recap_*` imagery, timed auto-advance + progress bars, recap score, tap-to-advance, skippable. (Animated title cards + stills, not a rendered shareable video yet.) ✅ / share-render ⛔
- **Memory Orbs** — held-moment **liquid-glass beads** (`MemoryOrbView`): native iOS 26 `.glassEffect(.clear)` refraction over a patient selfie/photo, plus a draggable arc viewer (`MemoryArcViewer`) and a PhotosPicker capture (`AddMemoryOrb`). Lives in Journeys. ✅
- **Body view** — abstract luminous figure (`BodyMapView`) used in symptom logging; not yet a standalone story "body view." 🟡
- **Records drawer** — `RecordsDrawerView`: unified record, source freshness chips, 7 categories, row→explain sheet with three-tier disclosure, and a **conflict reconciliation** sheet ("sources differ"). ✅
- **Trends** — `LabDetailView` + `GlowChart`: luminous line, soft reference bands (no red/green), annotations toggle, explain. ✅
- **Share** — visit-prep brief exists (see §3.8); PDF/live-link export ⛔.

## 3.5 Journeys — Habits & Programs (P0) — ✅ Implemented

`JourneysView`: held-moment orbs + arc viewer, the generative **light-garden** (each kept habit adds a glowing element — no streaks anywhere), journey/habit keep-toggles with a light-bloom reward, and the **Sponsored Programs engine** (see §3.14). Banned vocabulary enforced by `Glossary.swift`. ✅

## 3.6 Medications (P0) — ✅ Implemented

`MedicationsView` + `MedDetailView`: calm list with plain purpose lines and supply countdown; the **adherence tide** visualization (no percentages on the surface, PDC one tap deep); barrier-first **refill intelligence**; guidance, side-effect watchlist tuned to conditions, and dose-history; **"log near this med"** ties a symptom log to a medication (`SymptomLog.linkedMedID`). Schedules and Live Activity reminders remain a fast-follow. ✅ core / 🟡 reminders+Live Activity

## 3.7 Symptom & Life Logging (P0) — ✅ Implemented (AI support 🟡)

`QuickLogView`: a branching 3-tap flow.
- **Symptom path:** what (condition-adaptive `symptomKinds`) → **body-map location** (`BodyMapView`, 9 hotspots, shown only for `needsBodyMap` symptoms) → **fluid severity slider** (color-temperature morph, no numerals) → optional context → **companion support step**.
- **The support step [v4 NEW]** is the important part: it returns a `SupportPlan` with a warm message, condition-specific tips, an **urgent-call banner** when warranted, **add-to-discussion-guide**, a **draft-a-note-to-the-office** (with approval), a **call-the-office** action (`callOffice()` → `tel://`), and a "talk it through" door into conversation. ✅ (support text is fixture-scripted via `supportPlan`, not live-LLM — 🟡)
- **Quick add for meals / movement / meds** lives in the same "+" flow and feeds the Life Catalog. ✅
- Every log gets a companion acknowledgment toast (`CompanionAckToast`), tappable into conversation. ✅

## 3.8 Care Team & Appointments (P0) — ✅ Implemented

`CareTeamView`: care team list with **call-office**, appointments timeline, and a **Visit Prep** door (`VisitPrepView`): what's changed, what to ask (pulled from the Discussion Guide), what to bring, and send-ahead approval. ✅

## 3.9 Insights — the Hub (P0) — ✅ Implemented

`InsightsHubView`: editorial full-width insight spreads with category filters, glow-chart / generative-scene / tide visuals, **honest epistemics** (confidence copy, provenance chip, "Why am I seeing this?" → exact sources), acted-outcome state, and save/act. ✅

## 3.13 Currents — the content experience (P0) — ✅ Implemented

`CurrentsView` + `CurrentsPlayerSheets`: a finite, full-bleed paging feed of scenes in four formats, with a gentle daily-set end scene (no infinite feed), save-to-story, taste training, and ask-the-companion.
- **Reads** render long-form inline in the Fraunces serif. ✅
- **Listens actually play** (`ListenSheet`: AVAudioPlayer + waveform + transport + transcript). ✅
- **Watches actually play** (`WatchSheet`: looping video + auto-advancing captions + scored audio). ✅
- **Glances** as swipe-frames. ✅

## 3.14 The Sponsored Programs Engine (P0) — 🟡 Partial

`JourneysView` + `Program` model implement the **presentation grammar**: clinical-why → personal-fit → patient-dividend → one-tap action → **sponsorship disclosure chip** (`SponsorChip` → `SponsorExplainSheet`). Equal-weight decline; enroll weaves the program into Today (a moment), Journeys (a journey), an agent action, and a memory. Governance laws are restated in code comments at the ranking site. Sano can surface programs contextually in conversation (a `program` Rich card). 🟡 **The clinical-eligibility gate is fixture-scripted, not a live guideline rules engine**, and activation-verification hooks (R4/R6) are stubs.

## 3.15 The Brain Vault (P1/P2) — 🟡 Partial (Privacy Center ✅ / MCP ⛔)

`PrivacyCenterView` delivers an evolved, browsable, **editable** profile surface: a memory "constellation," four personalization "lenses," the Epsilon toggle, the consent ledger, connected sources with freshness, and **export + delete-everything**. The **Vault-as-MCP server** and "Connect with Nudge" partner flow are not built. ✅ surface / ⛔ MCP

## 3.10 Privacy Center (P0) — ✅ Implemented

See §3.15 — consent ledger, Epsilon view/edit, memory transparency, export, delete account, source freshness. ✅

## 3.11 Caregiver & Family (P1) — ⛔ Not yet
## 3.12 Widgets, Live Activities, Watch (P1) — ⛔ Not yet

## 3.16 Life Catalog (P0) **[v4 NEW]** — ✅ Implemented

`LifeCatalogView`: meals, movement, and meds as a **magazine-style gallery of subject-lifted studio objects** (`SubjectLifter` cuts the subject out of bundled studio photos via Vision foreground masking), grouped by day with calorie/effort totals. A hero transition opens a `LifeEntryDetailView` "room" (big number + animated macro bars for meals / med facts for meds + ask/log/remove). Adding an entry shows a **live studio-image preview** as Sano matches the food/med/activity to a consistent visual (`LifeLibrary` keyword→image matcher + `LifeFacts` nutrition lookup). This is the "premium magazine catalog" timeline view requested. ✅

## 3.17 Condition Overview (P0) **[v4 NEW]** — ✅ Implemented

`ConditionOverviewView`: a calm hero surface that **surfaces the user's condition(s) without nagging**, the **care plan from the doctor** (goals to map the journey against), the **phase arc** (where they are), **what-to-expect**, and links into clinical data. Reachable from the You hub. ✅

## 3.18 Discussion Guide (P0) **[v4 NEW]** — ✅ Implemented

`DiscussionGuideView`: a fresh, friendly take on a visit guide — a **self-writing list of questions + observations** for the care team, captured from symptom logs and conversation, with question/observation sections, resolve, and **send-ahead approval**. Feeds Visit Prep. ✅

---

# 4 · The Engagement Model (binding) — mostly unchanged from v3

The core loop (ambient trigger → effortless action → felt reward → growing investment), session shape, the **banned list** (no streaks, no red shame, no infinite feeds, no guilt copy), the **notification governor** (≤2/day, ≤8/week, quiet hours, friend-test), the **return ladder**, and the **First-30-days curve** all stand as v3 §4.

**v4 build status:** the banned list is enforced in product and in `Glossary.swift` (banned words: streak, goal, compliance, failed, missed). ✅ The notification governor, return ladder, and `daysSinceOnboarding` feature-state machines are **specified but server-side / not yet wired client-side**. 🟡 Preferences for notification classes and quiet hours exist in Settings. ✅

---

# 5 · Design Principles (Binding) — unchanged from v3

The eight principles stand: companion is hero · calm by default, light is attention · nothing boxy · motion is physics · warm earth + deep night · delight within function · three taps to anything · trust is a design primitive.

---

# 6 · Design Language Spec

North stars unchanged (Kuznetsov · Genie · Trivedi · Choi). v4 updates the concrete tokens that shipped.

## 6.1 Color — ✅ Implemented (`Theme.swift`)
Two worlds: **"Clay & Dawn"** (light) and **"Indigo Night"** (dark), as semantic tokens with time-of-day gradient palettes and companion orb palettes/halos. Meaning-without-alarm scale (amber luminance for attention, deeper warm orange for urgent — never red). ✅ The user can force Day / Night / Auto in Settings. ✅

## 6.2 The Living Gradient — ✅ Implemented
App-wide animated Metal mesh ground (`LivingGradient.metal` → `LivingGradientView`), three slowly-orbiting radial centers, time-of-day tuned, paused when the scene isn't active.

## 6.3 Shape & Layout — ✅ Implemented
Continuous-corner everything; organic surfaces (`GlassSurface`/`OrganicSurface`); curved story spine; liquid glass reserved for chrome (dock, chips, sheet headers, input bar) over the living gradient so it has something to refract.

## 6.4 Typography — a two-voice system **[v4 UPDATED]** — ✅ Implemented (`NudgeType.swift`)
v4 ships a **distinctive, non-default** type system:
- **Display / wordmark voice — Hermione** (`HermioneFREE`): the "Sano" wordmark and big title moments — an elegant, curved, human serif.
- **Serif meaning/reading voice — Fraunces** (400/500/600/700 + italic): insight headlines, Currents Reads, story chapter titles, recap title cards, the companion's emphasized lines.
- **Function voice — SF Pro Rounded** + monospaced digits for chrome, numbers, labels, body.
- Fonts bundled in `ios/Nudge/Fonts/` and registered at launch (`NudgeFonts.registerAll()`). Pairing discipline from v3 stands (serif owns meaning, sans owns function; numbers always sans).

## 6.5 Data Visualization — ✅ Implemented (`GlowChart`, `TideView`, `LightGardenView`)
Luminous single-line glow charts with soft fill, scrub lens, and neutral reference bands; the medication **tide** and the habit **light-garden** are generative Canvas scenes, not charts.

## 6.6 Motion & Delight Budget — ✅ Implemented (`NudgeSpring.swift`)
Springs only (ui / gentle / delight). Matched-geometry morphs and fluid dissolves for transitions. One bloom moment per session. Micro-interactions ≤150ms. (`Reduce Motion` fallbacks remain a hardening item — 🟡.)

## 6.7 Iconography & Illustration — 🟡 Partial
Custom chrome icons (`ChromeIcon`) and generative empty-state scenes (`SceneVisual`) ship; the only "character" is the orb. Bundled studio illustrations (meals/meds/activities, currents, recap, conditions) provide the rich imagery requested. A full ~40-glyph hand-drawn icon set remains partially system-derived. 🟡

## 6.8 Sound & Music — the Score **[v4 UPDATED]** — ✅ Implemented (`SoundEngine.swift`)
The app has a real score with **one sonic identity**:
- **Beds (crossfaded, equal-power-ish, silent-switch-through via `.playback`):** *Barley Thunder* under onboarding's opening; *Stone Kintsugi* as the ambient bed for the rest of the app and under Currents Listen/Watch; a dedicated **recap score** (`startRecap()/stopRecap()`).
- **The "ta" micro-instrument [v4 NEW]:** five sung pentatonic notes (`tap_ta_1…5`) walked through a phrase array so taps **compose a melody** (debounced ~90ms), not a UI-blip junk drawer.
- **SFX:** soft whoosh (pull-to-talk), bloom (kept habit / milestone), glass (orb tap), tick.
- **Mixing:** the bed ducks while the companion speaks (voice mode); a **global music mute** + per-class sound toggles in Settings; every sound has a haptic twin (`Haptics.swift`). ✅
- Keyframed `MomentScore` (audio+haptic+motion as one timeline) is partially realized (recap + bloom synced); full descriptor remains a polish item. 🟡

---

# 7 · The Companion — Hero Spec

## 7.1 Form: the Orb — ✅ Implemented
Two renderers ship: a **real-footage orb** (`VideoOrbView`) that cross-fades looped clips per state (`orb_day` / `orb_night` / `orb_speak` / `orb_think` / `orb_bloom`) with a feathered circular mask and rim light, falling back to a **Metal aurora orb** (`OrbView` + `Orb.metal`: three phase-offset noise-displaced gradient shells, specular kiss, volumetric halo, breath, celebrate ring) under 60pt. The orb persists minimized on every non-chat screen and is the matched-geometry anchor into conversation. State machine (`OrbState`): ambient / listening / thinking / speaking / celebrating / concerned / resting. ✅

## 7.2 Conversation Surface — ✅ Implemented
`ConversationView`: full-bleed immersive scene (aurora washes + drifting motes Canvas), streaming per-word text, user messages in glass capsules, and **inline rich elements as organic surfaces**: a lab trend chart, a habit proposal (one-tap accept), a refill fix, a guide-add, an **agent action card** (approve & go), and a **program card** with sponsor disclosure. Suggestion chips; glass input bar; drag-to-dismiss; voice button. ✅

## 7.3 Voice & Behavior — ✅ Implemented (prompt) (`CompanionEngine.swift`)
The companion's brain builds a large **grounded system prompt** every turn: persona switcher line, conditions, meds (with chartable lab tag ids), care plan, appointments, memories, recent symptom + life logs, open guide questions, available programs (with sponsor-disclosure rules), pending actions, and today's date. It instructs warm-friend tone with clinical depth, MI/SDT/HBM/COM-B/TTM as reasoning lenses, no diagnosis/prescription/alarms, three-tier disclosure, provenance, and explicit confirmation for outbound actions — and **anti-sycophancy** honesty. The model is **Claude Opus 4.8**. ✅

## 7.4 Memory Made Visible — ✅ Implemented
A "what Sano remembers" surface in Privacy Center (constellation of editable memory chips) and invocable in chat. Every item editable/deletable. ✅

## 7.5 Voice Mode — the companion, spoken (P0) **[v4 UPDATED]** — ✅ Implemented (`VoiceSession.swift`, `VoiceModeView.swift`)
A real end-to-end voice loop, designed around the orb:
- **Entering voice:** the voice button / holding the orb opens `VoiceModeView`; the orb grows center-stage with mic-level halo rings.
- **The pipeline:** `AVAudioRecorder` (live metering drives the orb halo) → **ElevenLabs Scribe `scribe_v2`** STT (multipart upload) → **Claude Opus 4.8** (`companion.voiceReply`) → **ElevenLabs `eleven_turbo_v2_5`** TTS (voice "Rachel"), played via `AVAudioPlayer` with the music bed ducked.
- **One button:** tap to talk, tap to finish, tap to interrupt (barge-in stops TTS). Phase machine: idle / listening / transcribing / thinking / speaking / unavailable.
- **Real-device gating:** if no mic (cloud simulator), a warm placeholder asks the user to install Sano on their iPhone. ✅
- Streaming-first-phrase latency optimization and lock-screen background session remain polish items. 🟡

## 7.6 Voice Notes (P0) — 🟡 Partial
TTS rendering exists; dedicated rare "voice note" capsules at milestone/emotional moments are not separately surfaced beyond voice mode. 🟡

## 7.7 Rapport & the Nostalgia Layer — 🟡 Partial
Rapport mechanics (continuity callbacks, earned references) live in the system prompt + memory. **Era warmth** is a real Settings control (Off / Subtle / Full); the visual nostalgia treatments (VHS-sunset drift, grain-bloom recap variants) are scoped to the recap/score and not yet a full shader LUT set. 🟡

## 7.8 Agentic Actions & Approval (P0) **[v4 NEW]** — ✅ Implemented
Sano proposes actions it can take (draft a note to the office, set up delivery, enroll a program, add a guide question). These render as **glass action cards** on Today and inline in conversation, parsed from `[[action:…]]` / `[[program:…]]` / `[[refill:…]]` tags by `CompanionEngine`. **Critical actions require explicit approval** ("Approve & go," with the guarantee "Nothing sends without you"); `AppModel.approveAction`/`declineAction` resolve them visibly (a companion story event + ack toast). Proactive nudges come from per-persona seeded moments, insights, and agent actions. ✅

---

# 8 · Screen Inventory (as-built checklist) **[v4 UPDATED]**

| # | Screen | Status | Notes |
|---|---|---|---|
| 1 | Welcome / Auth | 🟡 | scene ✅, Sign in with Apple ⛔ |
| 2 | Onboarding conversation (3 Q) | ✅ | live-streamed |
| 2b | About You (name + DOB) **[v4]** | ✅ | |
| 2c | Path choice + shaping **[v4]** | ✅ | seeds persona |
| 3 | Record connect | 🟦 | UI ✅, integration mocked |
| 4 | HealthKit permission | 🟦 | UI ✅, no live reads |
| 5 | Epsilon consent | ✅ | |
| 6 | Today canvas | ✅ | orb, Thread, pull-to-talk, dock, agent card, life strip |
| 7 | Conversation | ✅ | streaming + 6 rich inline elements |
| 8 | You — Story | ✅ | curved timeline |
| 9 | Records drawer | ✅ | 7 categories, explain, reconciliation |
| 10 | Lab detail / Trend | ✅ | glow chart, bands, annotations |
| 11 | Medications | ✅ | tide, supply |
| 12 | Med detail | ✅ | refill intelligence, watchlist |
| 13 | Quick Log | ✅ | 3-tap, body map, severity, support step |
| 14 | Journeys home | ✅ | light-garden, memory orbs |
| 15 | Journey detail | ✅ | habits |
| 16 | Program browse/enroll | 🟡 | grammar ✅, live eligibility gate scripted |
| 17 | Care team & appointments | ✅ | |
| 18 | Visit Prep | ✅ | send-ahead approval |
| 19 | Privacy Center | ✅ | ledger, Epsilon, export, delete |
| 20 | Settings | ✅ | tone, appearance, persona previewer, era warmth, sound, quiet hours |
| 21 | Insights Hub | ✅ | editorial, epistemics |
| 22 | Currents | ✅ | 4 formats, Listen/Watch play |
| 23 | Voice Mode scene | ✅ | real STT→LLM→TTS |
| 24 | Cinematic Recap player | ✅ | plays; share-render ⛔ |
| 25 | Memory Orbs | ✅ | native glass refraction + arc viewer |
| 26 | Document scan/upload | ⛔ | |
| 27 | Body view (standalone) | 🟡 | body map exists in logging |
| 28 | Food log | ✅ | within Life Catalog |
| L1 | **Life Catalog [v4]** | ✅ | meals/moves/meds magazine gallery |
| L2 | **Condition Overview [v4]** | ✅ | conditions, care plan, phases |
| L3 | **Discussion Guide [v4]** | ✅ | self-writing visit guide |
| 29 | Family circle | ⛔ | |
| 30 | Widgets / Live Activity / Watch | ⛔ | |
| 31 | Connect flow (multi-rail) | 🟦 | UI ✅, rails mocked |
| 32 | Sponsored moment surfaces | 🟡 | grammar ✅ |
| 33 | Brain Vault | 🟡 | Privacy Center ✅, MCP ⛔ |

---

# 9 · Omnichannel (Photon Spectrum) — ⛔ Not yet
Specified as v3 §9; **not built in v4**. iMessage/WhatsApp/Telegram extension, identity resolver, unified cross-channel store, and channel-routed return ladder remain future work. (The conversation store is already channel-agnostic in the model, so this is additive.)

---

# 10 · Technical Architecture & Reference Code **[v4 UPDATED]**

## 10.0 Stack (as-built)
- **iOS 26 target** (uses native `.glassEffect` Liquid Glass with `.ultraThinMaterial` fallback for earlier OS), SwiftUI-first, Metal for orb + living gradient + effects; `@Observable` MVVM with a single `AppModel` spine. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- **Persistence:** local JSON document (`PersistenceService` → `SanoUserData`) + UserDefaults for preferences. (SwiftData + `NSFileProtectionComplete` encrypted store from v3 §10 remains the production target — 🟡.)
- **Networking:** async/await `URLSession` → Rork Toolkit gateway (`https://toolkit.rork.com`); **SSE token streaming** for chat (`CompanionAI`).
- **Config:** `AppConfig.swift` — `toolkitURL`, `toolkitKey` (⚠️ currently hardcoded literal; move to injected env before release), `chatModel = anthropic/claude-opus-4.8`, `voiceID = 21m00Tcm4TlvDq8ikWAM`.

## 10.1 Spring System — ✅ `NudgeSpring.swift` (ui / gentle / delight; no `.linear`/`.easeInOut`).

## 10.2 Living Gradient — ✅ `LivingGradient.metal`.

## 10.3 Touch Ripple / Fluid Distortion — ✅ `Effects.metal` (`ripple`, `touchGlow`) + `RippleEffect` modifiers; global tap ripple on the ground in `ContentView`.

## 10.4 Fluid Dissolve (melt) — ✅ `Effects.metal` (`melt`) + `MeltModifier`; used for Thread dismissal.

## 10.4b Genie Light Distortion **[v4 NEW]** — ✅ `Effects.metal` (`lightSweep`, `sweepLens`) + `LightSweep`/`AmbientLightSweep` modifiers — the Genie-style iridescent light band over chrome.

## 10.5 Liquid Glass chrome **[v4 UPDATED]** — ✅ `GlassSurface.swift`
`GlassSurface` / `OrganicSurface` / `CircularGlass` / `CapsuleGlass` / `ChromeIcon` / `NudgeDock` use **native iOS 26 `.glassEffect(...)`** with a `.ultraThinMaterial` fallback. Memory beads use `.glassEffect(.clear, in: .circle)` for true refraction.

## 10.6 The Orb — ✅ `Orb.metal` + `OrbView` + `VideoOrbView` (see §7.1).

## 10.7 Glow Trend Chart — ✅ `GlowChart` (Swift Charts catmullRom + glow + area fill + scrub lens).

## 10.8 Data Models (as-built) **[v4 UPDATED]**
The shipped model layer is richer and persona-centric: `CarePathway`, `Persona`, `CarePlan`, `SymptomKind`, `BodyRegion`, `SupportPlan`, `GuideItem`, `CareEntry`, `AgentAction`, `MemoryGlimpse`, `UserProfile`, plus the engagement models (`Moment`, `Insight`, `Journey`, `AtomicHabit` — **no streak fields**, `Program`, `SymptomLog`, `StoryEvent`) and record models (`LabSeries`, `RecordItem` with conflict, `Medication` with tide, `CareTeamMember`, `Appointment`, `RecordSource`, `ConsentEntry`). SwiftData migration is the production target.

## 10.9 Asset Manifest (produced) — ✅ partial
Bundled: orb footage (`orb_day/night/speak/think/bloom.mp4`), recap/condition/currents/meals/meds/activity studio images (`Assets.xcassets`), the score (`music_barley_thunder`, `music_stone_kintsugi`, `music_recap`), SFX, the `tap_ta_1…5` notes, and the Fraunces/Hermione fonts. Hand-drawn 40-glyph icon set and era-warmth LUT variants — 🟡.

## 10.10 Reference Library — used: Trivedi ripple lineage, Choi/Metal shader patterns, Inferno-style dissolves, Apple WWDC custom-effects ripple/layer effects, ElevenLabs voice. (Pow / Wave SPM not imported — effects hand-written.)

## 10.11 Voice Mode Integration — ✅ `VoiceSession.swift` (see §7.5). Provider seam is ElevenLabs direct via the toolkit proxy; wrap behind a `VoiceProvider` protocol before swapping vendors — 🟡.

## 10.12 Adaptive Audio Engine + MomentScore — 🟡 `SoundEngine.swift` realizes beds/notes/SFX/recap with crossfades, ducking, mute, and debounce; the unified `MomentScore` descriptor is partially realized.

## 10.13 Layer-1 Multi-Rail Data — 🟦 designed, mocked
The Connect UX, freshness chips, and reconciliation surface are built and render from fixtures; the live rail router (R1 athena / R2 SMART-on-FHIR / R3 TEFCA / R4 payer / R5 aggregator / R6 Surescripts / R7 HealthKit / R8 documents) and the reconciliation engine are **not yet wired**. This is the top fast-follow for production.

## 10.14 Brain Vault & MCP — ⛔ (Privacy Center surface ✅).

---

# 11 · Quality Bars & Acceptance (status)

- **Performance:** 120fps canvas/orb/conversation, ≤1.5s cold launch, ≤1.2s first token/first audio — to be validated in Instruments. 🟡
- **Accessibility:** VoiceOver orb-state announcements, audio-graph charts, Dynamic Type to XXL across both type voices, Reduce-Motion fallbacks, WCAG AA in both worlds — partial; a dedicated accessibility pass remains. 🟡
- **Privacy:** zero PHI outside encrypted stores — **gap:** current store is plain JSON/UserDefaults; move to `NSFileProtectionComplete` SwiftData + Keychain for the toolkit key before release. 🟡
- **§11.3 Coherence Audit** — `Glossary.swift` enforces one vocabulary; the single `AppModel` spine enforces one data source; agentic wiring connects features to the brain. Cross-surface snapshot tests across the Day 0/3/7/14/30 curve and sponsored-governance/reconciliation test suites remain to be written. 🟡

---

# 12 · Build Phases — where v4 stands

1. Foundation (tokens, living gradient, glass, models, fixtures) — ✅
2. The Orb (state machine + shaders + footage) — ✅
3. Conversation (streaming + rich elements + ripple) — ✅
4. Today + Thread + dock + pull-to-talk — ✅
5. You: Story, records, reconciliation, explain, glow charts — ✅
6. Medications + Quick Log + symptom support + body map — ✅
7. Journeys + light-garden + programs engine — ✅ (governance gate scripted 🟡)
8. Insights Hub + Currents (4 formats, Listen/Watch play) — ✅
9. Voice mode + ScoreEngine + audio identity — ✅ (voice notes / MomentScore 🟡)
10. Onboarding end-to-end + Privacy Center + Settings — ✅ (Apple auth ⛔)
11. Care team, visit prep, recap player, memory orbs, condition overview, discussion guide, **Life Catalog** — ✅
12. Omnichannel — ⛔
13. Hardening: coherence/accessibility/performance/privacy audits, real EHR+HealthKit rails, SwiftData encryption, Apple auth, Brain Vault MCP — **the v4→v5 roadmap.**

---

# 13 · v4 → v5 Roadmap (the honest backlog) **[v4 NEW]**

In priority order for production readiness with alpha patients:
1. **Live data rails** — real SMART-on-FHIR connect + HealthKit reads (replace the §10.13 mocks).
2. **Sign in with Apple** + real identity/account.
3. **Encrypted persistence** (SwiftData + `NSFileProtectionComplete`) and **move the toolkit key out of client source**.
4. **Live clinical-eligibility engine** for the sponsored programs gate (replace fixture-scripted `supportPlan`/eligibility with guideline-anchored logic + activation verification).
5. **Notification governor + return ladder + Day 0/3/7/14/30 feature-state machine** wired client-side.
6. **Accessibility + performance hardening** pass (VoiceOver, Reduce Motion, Instruments, thermal/Low-Power shader fallbacks).
7. **Omnichannel (Photon Spectrum)** and **Brain Vault MCP**.
8. **Cinematic Recap share-render**, voice-note surface, full era-warmth LUTs, hand-drawn icon set.

---

*End of v4 specification. The bar is unchanged: the best-designed app of the decade in its category — calm enough to trust with your health, alive enough that you miss it when you're away. v4 records how far Sano has come toward that bar, and exactly what remains.*
