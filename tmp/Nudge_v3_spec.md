# NUDGE — iOS App Build Specification & Requirements
### The AI Behavioral Health Companion · Build-ready spec for an agentic coding model (Claude in Rork or similar)
**Amalgam Rx × Publicis Groupe · June 2026 · v3 (12-point refinement + data rails, sponsored engine, Brain Vault) · Confidential**

> **How to use this document:** This is the complete product, design, and engineering specification for the Nudge iOS app. It is written to be executed end-to-end by an agentic coding model. Sections 1–3 give product context and competitive grounding (read once, internalize). Sections 4–6 are the experience and design law of the app (binding). Sections 7–9 are screen-by-screen and module specs (build against these). Sections 10–12 are technical architecture, reference code, and build phases (follow in order). When in doubt, the design principles in §5 and the companion rules in §7 win over any convenience shortcut.

---

# 1 · Product Context (read first)

Nudge is a consumer iOS app — the patient-facing surface of a five-layer platform:

- **L1 Data:** a **multi-rail** clinical data foundation — direct athenahealth APIs through the Privia relationship, SMART-on-FHIR patient-access connections (Epic, Cerner/Oracle, and any §170.315(g)(10) certified EHR), TEFCA Individual Access, payer Patient Access APIs (claims), Surescripts dispense, aggregator lanes (b.well) as accelerant, HealthKit/devices, and document scan. The app consumes one unified, reconciled record from the Nudge backend; the full rail architecture, reconciliation engine, and write-back path are specified in §10.13. **Do not assume a single vendor delivers the record.**
- **L2 Knowledge:** plain-language clinical understanding (licensed content substrate + Amalgam Medical-Grade AI reasoning).
- **L3 Personalization:** fusion of clinical data + Publicis Epsilon consumer-intelligence profile (purchases, online behavior, values, financial stress signals, messaging receptivity).
- **L4 Care pathways:** condition programs and transparently-disclosed pharma-sponsored support programs surfaced at the behaviorally right moment.
- **L5 Behavioral AI:** the companion. LLM-orchestrated planning across the user's care journey; internalizes COM-B, Motivational Interviewing, Stages of Change, Self-Determination Theory, and the Health Belief Model as ways of *thinking*, not rule engines. It plans care pathways, decomposes them into atomic habits aligned to the user's values/barriers/motivators/social context, and adapts in real time.

The app's hero is the **companion**. Everything else is supporting cast. The companion is also reachable outside the app — iMessage, WhatsApp, Telegram — via Photon Spectrum (§9). The app is the rich, beautiful home; the messaging channels are the ambient extension.

Reference user for all design decisions: **Marcus, 54, Atlanta.** T2D (A1c 8.4), hypertension, CKD-2, BMI 31. Metformin, lisinopril, atorvastatin. Single father, warehouse ops manager, church community, Braves fan, financially stretched, low patience for apps that judge him. If a screen would make Marcus feel lectured, judged, or confused, the screen is wrong.

---

# 2 · Competitive Teardown — What Exists, What's Table Stakes, What's Open

Three products were examined in depth (plus the broader landscape: MyChart/Emmie, athenaPatient, ChatGPT Health, Noom/Omada/Lark, Apple Health).

## 2.1 Healthie (provider-tethered patient app)

**What it is:** The patient-side app of a HIPAA-compliant EHR/practice-management platform for nutrition and wellness practices. The same binary serves providers and clients; experience switches on login credentials.

**Onboarding:** Provider-initiated. The practice invites the patient; patient receives credentials and logs in. No self-serve discovery. Multi-org patients pick which organization to sign into — fragmentation persists even here.

**Data model & logging:** Patient-entered journaling is the core loop — photo-based food logs (with hunger level, perceived healthiness, mood around meals, free-text reflection), nutrient logging via the Edamam food database integration, workouts, water, symptoms, custom metrics (weight, BMI, body fat, any provider-defined metric). Metrics sync from Fitbit, Apple Health (HealthKit), Google Fit, iHealth scales.

**Provider loop:** Providers view and comment on entries in near-real-time; goals are provider-assigned, patients mark complete; education programs (PDF/video modules) are provider-assigned. Secure chat threads attach to the chart.

**AI:** None patient-facing. No insights, no synthesis, no proactive anything. The "intelligence" is the human provider reading your logs.

**Screens (patient):** dashboard with logging icon grid (Food / Metrics / Goals / Programs / Appointments / Messages / Documents), chronological journal feed, chat thread, appointment list with Zoom telehealth launch, forms.

**What to learn from it:** (a) Provider-commenting on patient logs is a powerful accountability loop — Nudge replaces the waiting-for-human latency with instant companion response plus care-team escalation. (b) Photo-first food logging with *mood and hunger context* is the right capture model — low friction, high signal. (c) Its weakness is the absence of any intelligence between visits: data goes in, nothing comes back until a human looks.

## 2.2 Lotus Health AI (free AI doctor)

**What it is:** A licensed virtual medical practice: proprietary clinical-reasoning AI conducts the visit (symptom intake → history review → evidence-grounded assessment → ICD-10-coded diagnosis and plan), board-certified physicians review and sign off. Prescriptions to any pharmacy, lab orders at 6,000+ sites, referrals. Free to patients; monetized by sponsorships. 50-state licensed, malpractice-insured, HIPAA-compliant. ~$35–41M raised (Kleiner Perkins, CRV).

**Onboarding:** Self-serve. Account → connect clinical records, insurance, wearables (granular consent; revocable per-source) → chat immediately. 24/7, 50 languages.

**Data model:** Connected EHR records (labs, meds, immunizations, conditions, procedures), insurance benefits, wearable data. All AI recommendations carry citations to primary sources.

**AI surface:** The entire product is the AI conversation. Physician-level questioning, differential diagnosis, treatment plans, refills handled conversationally. Red-flag symptoms route immediately to emergency guidance. Human-in-the-loop on all final clinical decisions.

**Screens:** chat-first; records browser (by category); care plan view; visit summaries; lab orders/results; prescription status.

**What to learn from it:** (a) Chat-first with the entire clinical record in context is exactly right and validates Nudge's architecture. (b) Citations on every clinical claim build trust — Nudge adopts this as provenance chips. (c) Free-to-patient, sponsor-funded validates Nudge's business model in market. (d) **The gap Nudge attacks:** Lotus is *episodic* — it activates when you're sick and ask. It has no behavioral layer, no longitudinal habit work, no consumer-intelligence personalization, no presence in the 8,754 hours/year between problems. Lotus is an AI doctor; Nudge is the companion who is there the rest of the time (and refers *into* care when needed — Nudge does not diagnose or prescribe).

## 2.3 Novellia (consumer PHR aggregator)

**What it is:** A free personal health record app: connects patient portals across thousands of US health systems, consolidates records (labs, meds, conditions, immunizations, procedures), plus manual tracking. Monetized by de-identified real-world-data licensing to biopharma.

**Onboarding:** Self-serve, ~20 minutes to "stitched-together" history (their selling point and reviews confirm it). Portal-credential-based connection flow; new records auto-sync from connected portals. SMS updates during processing.

**Features:** records browser with patient-added notes on any record; symptom tracking (Quick Log: type, time, severity, charted over time); medication list with reminders and adherence tracking; document upload for paper records; appointment-prep summaries; web app for features not yet on mobile.

**AI:** AI-driven data normalization in the backend; nothing intelligent patient-facing. No interpretation, no insights, no behavioral layer. (A scathing app-store review captures the gap: it aggregates the "wonky test results" but can't explain them.)

**What to learn from it:** (a) Fast time-to-aggregated-record is a wow moment — Nudge must hit "your whole story, assembled" within minutes of onboarding, with progressive loading. (b) Quick Log symptom capture (3 taps: what, when, how bad) is the right friction level. (c) Medication adherence as a home-screen citizen. (d) **The gap:** records sit there, mute. Nudge's entire reason to exist is making the record *talk* — interpretation, synthesis, and behavior change on top of aggregation.

## 2.4 Table-Stakes Synthesis (Nudge must have all of these)

| Capability | Established by | Nudge baseline |
|---|---|---|
| Multi-portal record aggregation, auto-refresh | Novellia, Lotus, b.well | Via backend; progressive load with live status; <5 min to first complete view |
| Records browser: labs (with trends), meds, conditions, immunizations, procedures, visit notes, documents | All three | Yes — but every item carries one-tap "What does this mean for me?" |
| Plain-language result explanation w/ citations | Lotus, Emmie | Yes — three-tier disclosure (reading → next step → ask), provenance chips |
| Medication list, reminders, refill status, adherence view | Novellia, Healthie | Yes — plus Surescripts dispense-aware gap detection and barrier-solving (delivery setup, copay programs) |
| Symptom Quick Log (≤3 taps) + severity charting | Novellia, Healthie | Yes — and every log gets a companion response, never a mute database write |
| Photo food / lifestyle journaling with mood context | Healthie | Yes — optional, companion-responsive, never calorie-shaming |
| HealthKit + wearable sync | All three | Yes — HealthKit read (steps, sleep, HR, glucose if present, workouts), background delivery |
| Secure messaging to care team | Healthie, Lotus | Yes — companion drafts messages to the (Privia) care team; user approves |
| Appointments view + prep | Healthie, Novellia | Yes — companion-generated visit-prep brief ("what to bring up") |
| Granular consent, per-source revocation | Lotus | Yes — consent ledger UI, Epsilon layer separately consented with plain-language explanation |
| Document upload (camera scan) | Novellia | Yes — OCR'd and merged into record |
| Care programs / education modules | Healthie | Yes — as conversational journeys, not PDF dumps |
| Push notifications | All | Yes — but governed by the behavioral notification policy in §4.4 (this is a differentiator, not a checkbox) |

## 2.5 The Open Space Nudge Owns

No competitor has any of: (1) a multi-framework behavioral AI companion with the full clinical record in context, (2) Epsilon-grade consumer-intelligence personalization, (3) longitudinal habit formation built around the user's actual life, (4) pharma-sponsored support programs surfaced at behaviorally-right moments with transparent disclosure, (5) omnichannel companion presence (iMessage/WhatsApp/Telegram). The app spec below is built to make these five visible and felt — not listed.

---

# 3 · Feature Requirements & Module Specs

Priority key: **P0** = MVP launch blocker · **P1** = fast-follow (≤90 days post-launch) · **P2** = later.

> **The depth mandate (binding):** No feature ships thin because it is "just one feature of a bigger app." Each module below must be the implementation a user would *choose over the best dedicated app in that category* — medications must beat Medisafe, symptom logging must beat Bearable, the record must beat Novellia, content must beat any health feed. If a module can't clear that bar at launch, cut its scope honestly (P1 it) rather than shipping a hollow version. Comprehensive without busy: depth lives one gesture below a calm surface, progressive disclosure everywhere, and the same interaction grammar across all modules (§11.3).

## 3.1 Onboarding & Identity (P0)

The onboarding is a conversation, not a form. The companion introduces itself and assembles the user's world while talking with them.

1. **Welcome:** full-bleed living-gradient scene (§6), companion orb breathes into existence. One line: "I'm here to know you — not just your chart." Sign in with Apple (primary), phone+OTP fallback. IAL2 identity verification (ID.me/CLEAR SDK) deferred until a flow requires it (e.g., record connection), not at first open.
2. **The first conversation (90 seconds):** companion asks 3 questions max, conversationally: what matters most to you right now (free text — this seeds the values model); what's hardest about your health day-to-day (seeds barriers); how do you want me to be — gentle nudges or straight talk (seeds tone preference; stored as an explicit, user-editable setting).
3. **Record connection — one simple door, many rails behind it:** "Want me to read your records so you never have to explain yourself twice?" → a single **Connect** flow: the user searches their providers/insurer or picks from smart suggestions (Privia practices auto-detected from sign-up context). The router (§10.13) silently selects the best rail per source — Privia/athena direct, Epic MyChart OAuth, any SMART-on-FHIR portal, payer Patient Access, or aggregator — the patient only ever sees "Find your provider → sign in to their portal → done." Progressive: as each source lands, the companion narrates discoveries warmly ("Found your labs from Piedmont — your last A1c was in March"), and a quiet freshness chip shows sync state per source. Conflicting data across sources is reconciled silently with a "sources differ" chip only when it matters (§3.4). Skippable; app fully works in manual mode; claims (insurer) connection offered later, contextually (§4.6), never as a day-0 wall.
4. **HealthKit:** single purpose-explained permission screen, requesting only read types used (steps, sleep, heart rate, workouts, body mass, blood glucose, blood pressure). Never the full kitchen sink.
5. **Epsilon consent (separate, explicit, plain):** one dedicated screen: what it is ("we use consumer insights — the kind advertisers already have about you — to personalize for you, never to advertise to you"), what changes if declined (generic vs. truly personal), revocable any time in Privacy Center. Decline is one equal-weight tap and is respected everywhere.
6. **Notification permission:** asked only *after* the first moment of delivered value (e.g., after the first insight lands), framed by the companion: "Want me to check in sometimes? I promise I'm not the nagging type."
7. **First Light moment:** onboarding ends on the Home canvas with one personally meaningful insight already present (from connected records, or from the conversation if no records). The user's first session must end with "it already knows me," not "I filled out forms."

Acceptance: time-to-first-insight < 4 minutes with records, < 2 without. Zero forms with >3 fields visible at once. Every permission individually declinable without dead ends.

## 3.2 The Companion (P0) — full spec in §7

## 3.3 Home — "Today" Canvas (P0)

Not a dashboard. A living, organic canvas — one scene, not a card stack.

- **Top third:** the companion orb in its ambient state, set in a slow living gradient that reflects time of day (dawn/day/dusk/night palettes, §6.2) and gently encodes "how things are going" (calm = settled slow motion; something needs attention = a subtle warm pulse — never red, never alarms).
- **The Thread:** below the orb, 1–3 (hard cap 3) "moments" — the companion's chosen items for right now: a check-in question, an insight ("Your BP readings this week are the steadiest they've been in a month"), a habit moment ("Braves don't play tonight — your 15-minute walk window is open"), or a gentle task (refill, visit prep). Each moment is one rounded organic surface with one clear action. Dismiss = swipe; it melts away with a fluid dissolve (§10.4), never to guilt-reappear.
- **Pull-to-talk:** pulling down on the canvas stretches the scene with a fluid distortion (§10.3) and drops into the conversation — the signature gesture of the app.
- **Bottom:** a floating liquid-glass dock with four destinations: **Today** (this canvas) · **You** (story/insights/records/trends) · **Journeys** (habits & programs) · **Currents** (the content experience, §3.13). The companion is not a tab — it is everywhere (orb persists, minimized, on every screen, always tappable).

Acceptance: cold launch to interactive < 1.5s; canvas animates at 120fps on ProMotion; max 3 moments enforced server-side.

## 3.4 "You" — The Health Story (P0)

The record reimagined as a narrative, not a filing cabinet.

- **Story view (default):** a vertical, flowing timeline — organic curved spine, not boxed rows — of the user's health life: diagnoses, results, visits, milestones ("90 days of steady metformin"), companion-caught moments ("We flagged that interaction in June"). Time scrubbing with a fluid elastic scroll; chapters by year.
- **Cinematic Recap (P0 for milestones, P1 full library):** at key milestone unlocks (a journey completed, a lab trend turned, an anniversary of starting), the companion offers a **recap film** — a 20–40s auto-composed, full-screen cinematic sequence of that chapter: slow Ken-Burns drifts over abstract scene compositions of the user's moments, brushstroke/ink-wash reveal transitions (Metal shaders, §10.10), type set in the serif display face, scored by the adaptive audio engine (§6.8), narrated optionally by the companion's voice (§7.5) for the biggest moments. Treat it like opening credits of a film about *them* — earned, rare, skippable, shareable as a rendered video. This is the premier reward surface of the app; never automatic-on-open, always offered.
- **Memory Orbs view (P1):** an alternate way to wander the story — memories as small luminous **liquid-glass orbs** (Inside Out's memory spheres by way of Janum Trivedi's Wabi-style glass material) arranged on a **honeycomb lattice with parallax depth**: tilting the device or scrolling shifts lattice layers at different rates; orbs refract the living gradient behind them; each orb glows in the hue of its moment-type (milestone gold, insight sky, visit sage, hard-day amber — never red). Tap an orb → it floats forward, expands with a matched-geometry morph into the full moment. Pinch out → constellation zoom by year. Implementation: §10.10 references (glass refraction + parallax grid).
- **Body view (P1):** an abstract, beautiful (non-anatomical-textbook) figure; conditions and signals light softly by region; tap to dive.
- **Records drawer:** the conventional browser for when the user wants the raw thing — Labs (sparkline trends, reference ranges shown as soft gradient bands, *never* red/green judgment colors), Medications, Conditions, Immunizations, Procedures, Notes, Documents. Every row: "What does this mean for me?" → companion sheet with three-tier disclosure and provenance chip ("From your Mar 12 Piedmont lab · explained with your kidney function in mind"). **Reconciliation surface:** when sources conflict or duplicate (two med lists, mismatched problem lists), show one calm merged view with a "sources differ here" chip; tap reveals a side-by-side with the companion's plain-language read and a one-tap "ask my care team to confirm." Aggregation quality is a first-class UX concern, not a backend detail.
- **Trends:** any metric chartable; charts use the line-glow + fill-gradient treatment (§6.5); pinch to zoom time; companion annotation toggle (events overlaid on the line: "started lisinopril here").
- **Share:** generate a clean visit-prep PDF or a live share link for a caregiver (proxy roles P1).

## 3.5 Journeys — Habits & Programs (P0)

Where behavior change lives. Never called "goals," "streaks," or "compliance."

- **A Journey** = one thing the user is working on (steadier mornings, moving after dinner, staying ahead of refills). Created conversationally with the companion — the companion proposes the *atomic habit* version (tiny, scheduled around real life from the Epsilon+conversation profile: "after the Braves game ends" not "7am daily").
- **Habit moments** surface on Today at the contextually right time; completing one is a single tap with a soft-burst light reward (§6.6 — light bloom, not confetti) and occasionally a short companion reflection. Missing one is *silence* by default; the companion only mentions a pattern of misses, with curiosity, never a broken-streak graphic. **There are no streak counters anywhere in this app.** Progress is shown as a growing organic form (a light-garden: each kept habit adds a softly glowing element to a personal generative scene) — continuity without streak anxiety.
- **Programs:** structured multi-week journeys (condition programs; pharma-sponsored support programs). Sponsored programs always carry a quiet, glass "Supported by [sponsor]" chip; tap explains the sponsorship in plain language; enrollment is always opt-in; the companion's recommendation logic is never pay-to-rank within clinical relevance (this is a product law, restate it in code comments where ranking happens).

## 3.6 Medications (P0) — must beat the best dedicated med app

- List with friendly framing: name, plain purpose line ("protects your kidneys and lowers BP"), schedule, supply countdown from dispense data.
- **Comprehensive without busy:** the calm list is the surface; one tap deep lives the full med record — dose history and changes (annotated: who changed it, when, why if known), interactions checked across the *whole* list including OTC/supplements the user adds, side-effect watchlist tuned to the user's conditions (statin myopathy watch given CKD), food/timing guidance ("with food," "not within 2h of antacids"), pill imagery for identification, prior medications archive ("what I used to take and why we stopped").
- **Schedules that match real prescriptions:** any pattern — multiple times daily, weekly (semaglutide), tapers, alternating doses, PRN with daily-max guardrails, injection-site rotation tracking for injectables. Time-zone-safe (travel shifts handled with a companion suggestion, not silent breakage).
- **Adherence without judgment:** a soft tide visualization (flowing band whose fullness reflects the last 30 days) instead of percentage-red-flags. Tap for detail; PDC available in detail for the data-curious, never on the surface.
- **Refill intelligence:** dispense-gap detection triggers a companion conversation (barrier-first: "anything making it harder to get there this week?") with in-chat fixes: switch to delivery, find copay program (L4), draft a message to the prescriber. Supply forecasting warns *before* the gap ("you'll run out next Thursday — refill is ready at CVS Peachtree").
- Reminders: scheduled local notifications, tone set by the companion's voice, snooze/skip without guilt, "taken" logging from the notification itself (notification action buttons), and Live Activity during the dose window (P1).

## 3.7 Symptom & Life Logging (P0) — must beat the best dedicated tracker

- **Quick Log:** reachable from Today (+), from the conversation, and via Action Button/widget. Three taps: what (recent + searchable list) → severity (a fluid slider that morphs color temperature, no 1–10 numerals required) → done. Optional photo/note/voice. Body-location picker (the abstract figure) for pain-type symptoms.
- **Pattern engine, not a diary:** logs feed correlation analysis across *everything Nudge knows* — meds started/stopped, sleep, activity, cycle data where relevant, weather, dispense gaps. Patterns surface in the Insights Hub (§3.9) with honest confidence language ("cramps have clustered on antibiotic days — 4 of 5 times"), never causal overclaim.
- Every log gets a companion acknowledgment within seconds — contextual, sometimes clinical (the statin-cramps catch), sometimes just human ("noted — third time this week; want to look at the pattern together?").
- Custom trackables: anything the user wants to watch (energy, mood, swelling), each with its own fluid input style; condition packs preconfigure sensible sets (T2D: glucose readings if no CGM, foot checks; HTN: home BP with cuff-sync via HealthKit).
- Food logging (P1): photo-first, Healthie-style mood/hunger context, zero calorie-counting UI by default (numbers exist behind a tap for those who want them).

## 3.8 Care Team & Appointments (P0)

- Care team list (from records + Privia); appointments timeline; **Visit Prep:** 48h before any visit the companion assembles a one-screen brief (what's changed, what to ask, what to bring) and offers to send topics ahead via the EHR message draft (user approves every outbound message — hard rule).
- In-app message thread to care team where the Privia integration supports it; otherwise drafted-for-portal messages.

## 3.9 Insights — the Hub + ambient surfacing (P0)

Insights get **their own destination**, not just scattered moments. The dock's **You** space gains a second tab pair: *Story · Insights* (one segmented glass control, morphing transition).

- **The Insights Hub:** a calm, editorial space — not a feed of boxes. Insights render as full-width organic compositions in a vertical flow, each one composed like a small magazine spread: a serif headline (§6.4), one luminous visual (glow chart, pattern map, or generative scene), 2–3 sentences in plain language, one action, one provenance chip. Categories: **Patterns** (correlations from logging + records), **Milestones**, **Heads-ups** (interactions, care gaps), **Opportunities** (program eligibility, savings, screening windows). Filter chips float in glass at top.
- **Insight lifecycle:** new → seen → acted/dismissed/saved. Saved insights pin to the top. Acted insights show their outcome thread ("you asked Dr. Patterson — resolved June 12"), closing the loop visibly — insights that go somewhere are the reward that brings users back to this screen.
- **Ambient surfacing continues:** the 1–3 Thread moments on Today and contextual placements inside relevant screens remain, but they are *pointers into* the Hub (tap-through lands on the full insight). One source of truth, two surfaces.
- **Honest epistemics:** every pattern insight carries sample-size-aware confidence copy and a "why am I seeing this" expander listing exactly which data produced it. No causal language without basis. This is both ethics and trust-building.
- Frequency governor for pushes: max 2 insight pushes/week unless clinically urgent (§4.4); the Hub itself can hold more, since visiting is user-initiated.

## 3.13 Currents — the content experience (P0 core, P1 full)

Content drives engagement — but not as another stack of article boxes. **Currents** is a flowing, swipeable, full-bleed content space (entry: a fourth dock position, or a current that runs along the top of Today — choose the dock position) where each piece is a *scene*, not a card.

- **Form:** vertical full-screen paging (one piece per page, reels-grammar familiarity) but rendered in Nudge's language: living-gradient grounds, serif display typography, ink-wash/brushstroke reveals between pages (§10.10 transitions), inline glow-visuals. Mixed formats: **Glances** (15–30s visual stories — 3–5 swipe-frames with one idea each), **Reads** (2–4 min articles set in the serif reading face, beautiful measure and rhythm, progress as a soft light line), **Watches** (short video, captioned by default, player chrome in liquid glass), **Listens** (companion-voiced audio pieces, §7.5). AI-generated and licensed/public content both flow through the same editorial design system; AI-generated pieces are labeled.
- **The selection logic is behavioral, not editorial-generic:** every piece is chosen by the L5 brain as a *nudge by other means* — directly (a Glance on injection-site rotation the week semaglutide starts) or indirectly (a story about a father walking with his son, for Marcus, the week his walking journey wobbles). Selection inputs: active journeys, recent logs/labs, TTM stage per behavior, Epsilon receptivity profile (format and tone preferences), time of day. Every piece carries an invisible *intent* tag server-side; the companion can act on engagement ("you watched that piece on CKD diets twice — want to make one small change from it a habit?").
- **Volume discipline:** Currents is finite — a daily set of 3–7 pieces, then a gentle "that's today's current — I'd rather you live your life than scroll" end-scene. **No infinite feed. Ever.** (§4.3). Unconsumed pieces roll forward intelligently; nothing expires with FOMO mechanics.
- **Interactions:** save to story (becomes a memory orb), share, "more like this / less like this" (one-tap taste training), ask the companion about any piece (pull-to-talk works here — the piece becomes conversation context).
- Acceptance: every piece renders within Nudge's design tokens (no embedded foreign branding chrome); selection-to-behavior intent coverage ≥ 90% of pieces tied to an active journey, condition, or stage; the daily set composes in < 300ms from cache.

## 3.14 The Sponsored Programs Engine (P0) — the business model, designed like a consumer company would

This is the revenue engine and the single most make-or-break design in the product. Amalgam's existing model — pharma-sponsored programs and advisories delivered inside clinical decision support, anchored to guidelines for safe-harbor alignment — extends here into a *direct, consumer-grade* patient channel. The design problem: make sponsored moments so contextual, well-timed, and genuinely in the patient's interest that acceptance is high *because the recommendation is right*, the way great consumer products monetize without corroding trust.

**The architecture: clinical relevance first, sponsorship second — always, structurally.**

1. **Eligibility layer (server):** a guideline-anchored rules+AI layer continuously evaluates the user's record against clinical standards — ACIP immunization schedules, USPSTF screening recommendations, ADA Standards of Care, GOLD/ACC/AHA where relevant — plus program-specific criteria (age, condition, payer, prior therapy). Output: a set of *clinically indicated opportunities* (flu vaccine due; CRC screening overdue; GLP-1 support program for an active semaglutide prescription; copay program for a branded med they already take). **An opportunity must clear the clinical gate before any sponsorship consideration exists.** Unsponsored opportunities of equal clinical weight flow through the identical pipeline — the user-visible experience never differs by funding status except the disclosure chip.
2. **The Moment Engine (the L5 brain decides *when and how*):** for each eligible opportunity, the behavioral brain selects the delivery moment and register using TTM stage, receptivity windows (Epsilon + learned), current psychological bandwidth (§4.6 logic), and channel. The same vaccination outreach that today is a cold SMS blast becomes, in Nudge: a natural beat *inside* an existing conversation ("while I have you — flu season's starting and with your diabetes the CDC puts you in the priority group; want me to find a Saturday slot at your CVS?"), or an Insight Hub entry with the guideline citation, or a Currents Glance the week before, or — for linked channels — a single well-timed iMessage. Never an interruption modal, never a push that exists only to sell.
3. **Presentation grammar (binding):** every sponsored moment is composed of: the *clinical why* in plain language with a guideline provenance chip ("ACIP recommends annual flu vaccination — higher priority with T2D") → the *personal fit* ("Saturday mornings work for you; the CVS on Peachtree has openings") → the *one-tap action* (schedule, enroll, apply copay card, set delivery) → the *sponsorship disclosure* (quiet glass chip: "This program is supported by [sponsor]" — tap for a plain-language explanation of exactly what the sponsor funds and what they receive). Decline is one equal-weight tap, remembered, with optional "not now / not ever" granularity; a declined program never re-surfaces in the same form within 90 days unless clinical urgency changes.
4. **Governance laws (restate in code comments at the ranking site):** sponsorship can never alter clinical eligibility, ranking among clinically-equivalent options, or the companion's language about alternatives; the companion always answers "are there other options?" completely and neutrally; frequency cap ≤ 1 sponsored moment per week surfaced proactively (in-conversation responses to user questions don't count); no sponsored moments in the first 14 days (§4.6 — trust before monetization); no sponsored content ever in crisis, bad-news, or emotional-support contexts; all sponsored copy passes the same §4.4 friend-test.
5. **The acceptance funnel & measurement:** instrument the full path — eligible → surfaced → engaged → accepted → *verified activation* (the shot administered per record/claim, the program enrolled, the script filled per dispense data) → outcome (adherence delta, gap closed). Pharma pays for verified activation and outcomes, not impressions — this is the pricing power of the whole company, and it only exists if the data spine (§10.13) closes the loop. Target benchmarks to design toward: surfaced→engaged ≥ 35%, engaged→accepted ≥ 40% (an order of magnitude above SMS outreach norms — that delta *is* the pitch to sponsors).
6. **The patient-side dividend:** a visible share of sponsorship value flows back as patient benefit — copay savings found, free delivery, covered programs — and the companion narrates it ("that program saves you $47/month"). Users should be able to feel that sponsorship makes their care cheaper and easier, not noisier.

## 3.15 The Brain Vault — Nudge as the patient's context brain, then the platform (P1 foundation, P2 platform)

Beyond clinical records, Nudge progressively becomes the **richest, most current model of the patient's real life** — and that asset, governed by the patient, becomes the long-term platform play.

- **Context rails (each individually consented, §4.6-staged, all optional):** email (health-relevant parsing only: appointment confirmations, lab notifications, EOBs, pharmacy receipts — on-device/edge filtering before anything leaves), calendar (free/busy rhythms for habit timing and scheduling agency), contacts (care circle), photos (medication bottles, documents — explicit per-item), social/content signals via Epsilon (already consented separately), device telemetry (HealthKit), and conversation memory itself. Each rail exists to *do things for the user*: auto-file the EOB, pre-fill the intake form, catch the appointment conflict, time the nudge.
- **The Vault (product surface):** an evolution of Privacy Center — the user's complete profile rendered as a beautiful, browsable, *editable* asset: identity & coverage, clinical summary, medications, preferences & values, behavioral profile (in honest plain language), care circle, document locker. Framed as *theirs*: "This is your brain. Take it anywhere."
- **The platform: Vault-as-MCP.** The Vault is exposed as a patient-controlled **MCP server** (plus FHIR/SMART endpoints for clinical consumers): any app, service, or agent the patient uses — a telehealth visit, a new specialist's intake, a pharmacy app, a fitness coach, even a general assistant — can request a *scoped slice* (e.g., `meds.current`, `allergies`, `coverage.summary`, `preferences.communication`) via a "**Connect with Nudge**" grant flow: the patient sees exactly what's requested, for how long, approves per-scope, and can revoke any grant from a live ledger. Nudge becomes the version-of-truth identity-and-context layer for the patient's whole digital health life — the Google-login of healthcare, except the patient owns the graph.
- **Why this wins long-term:** every grant makes Nudge more indispensable (the switching cost is your whole organized life), every connected service enriches the Vault back (with permission), and the network of consuming services becomes the distribution platform — the Instagram-like surface through which programs, products, and services reach patients *on the patient's terms*. Sequence: P1 = Vault surface + intake-form export + visit-prep share links; P2 = MCP server + Connect with Nudge for 3–5 launch partners; P3 = open developer program with scope-tiered review.
- **Hard laws:** no slice ever leaves without an explicit, specific, revocable grant; default grant duration is bounded (30/90 days, renewable); a complete access ledger (who read what, when) lives in the Vault; raw Epsilon data is never shareable outward — only Nudge-derived, patient-visible preferences; and the Vault is exportable and deletable in full (data portability as a trust feature and a regulatory posture).

## 3.10 Privacy Center (P0)

Consent ledger (every source, every scope, toggleable), Epsilon profile view ("what we use, in plain words" — show the user their own levers: best time of day, tone preference, framing style; let them *edit* these), data export, delete account. Radical transparency here is a trust feature and a marketing asset.

## 3.11 Caregiver & Family (P1)

Proxy access with role-graded views; family "circle" where a caregiver gets the same companion relationship scoped to the patient; built behaviorally (caregivers are often more action-stage than patients).

## 3.12 Widgets, Live Activities, Watch (P1)

Lock-screen widget (today's habit moment + supply countdown), Live Activity during medication windows, Watch app for habit check-off and the companion via voice. Smart Stack relevance.
# 4 · The Engagement Model — Habit-Forming, Honestly

Nudge must be the app people *want* to return to — the evening-remote-control reflex — without dark patterns. The loop is engineered, but every hook pays the user in genuine value. This section is binding product law.

## 4.1 The Core Loop

**Ambient trigger → effortless action → felt reward → growing investment.**

- **Triggers:** external (a behaviorally-timed message from the companion — in-app or via iMessage/WhatsApp) and internal (the cultivated reflex: "something on my mind about my health → open Nudge / text the companion"). The omnichannel presence (§9) is the trigger engine: the companion lives where the user already looks 100×/day.
- **Action:** every requested action is ≤ 1 tap or one short reply. Quick Log = 3 taps. Habit check = 1 tap. Asking anything = pull-to-talk or just texting.
- **Reward — three interleaved registers, deliberately variable:**
  1. *Relational:* the companion's responses are genuinely specific to the user (Epsilon + record context). The dopamine of being *known* — the strongest and most defensible reward in this app. Vary phrasing, depth, and callbacks; never templated.
  2. *Insight:* periodically, the companion connects dots the user couldn't ("your sleep dips the night before your worst BP mornings"). Unpredictable timing = anticipation.
  3. *Sensory:* micro-delight in the craft itself — the light bloom on a kept habit, the orb's pleased shimmer, the fluid melt of a dismissed card. Calibrated: delight at *moments of meaning*, calm everywhere else (§6.6 budget).
- **Investment:** every conversation, log, preference, and kept habit visibly improves the next experience ("the more I tell it, the better it gets") — the light-garden grows, the companion's callbacks deepen, the insights sharpen. Investment is the retention moat; surface it.

## 4.2 Session Shape

Designed for **many short warm sessions** (30–90s) + **occasional deep sessions** (review trends, a real conversation). The Today canvas opens to a complete glanceable state in 1.5s; depth is always one gesture away, never required. End-of-session feels *resolved* (the Thread empties gracefully to "you're set for now — I'll keep watch"), which paradoxically drives return: trust that nothing is being missed.

## 4.3 What is Banned

No streaks. No broken-chain graphics. No red badges of shame. No guilt copy ("you missed…you failed…don't forget!"). No infinite feeds. No engagement-bait notifications ("we miss you!"). No FOMO mechanics. No leaderboards. No confetti-by-default. The product wins by being the most caring thing on the phone, not the loudest.

## 4.4 Notification Policy (the Behavioral Governor)

All outbound contact passes one server-side governor:

- Hard caps: ≤ 2/day, ≤ 8/week across channels combined (clinical-urgent class exempt).
- Timing solves for the *user's* receptivity model (Epsilon + learned in-app behavior): right moment for them, never "9am blast."
- Every message must clear the test: *would a thoughtful friend with a medical background send this, now, in these words?*
- Classes: habit-moment, insight, heads-up (clinical), logistics (refill/appointment), check-in (relational). Each class individually mutable in settings; companion can also adjust conversationally ("fewer pings, please" → it actually changes the setting and confirms).
- Quiet hours default 21:30–08:00 local, learned and adjustable.

## 4.5 Re-engagement — the Return Ladder

Lapsed users are lost users; waiting politely forever is product failure. But re-engagement must read as a friend noticing, never a growth hack. A server-side **return ladder**, channel-aware (in-app push → iMessage/WhatsApp if linked), personalized in timing and voice by the Epsilon receptivity model:

- **Day 2 of silence:** nothing. Silence is allowed; absence of nagging is part of the trust.
- **Day 3–4:** one light, *specific* touch tied to something real — never "we miss you": "Your refill window opens Thursday — want me to set up delivery again?" or "That BP trend we were watching is still moving the right way."
- **Day 7:** one relational check-in in the companion's voice, referencing their world (Epsilon): "Braves swept the series — figured you'd be in a good mood. How's the week been?" If a journey was active, a no-guilt door back in: "Your walking journey is paused, not broken. One tap and we pick it up exactly where it makes sense."
- **Day 14:** one value-forward moment: a genuinely useful artifact delivered whole (a one-screen month-in-review, a new insight with the visual inline in the push/rich message) — give, don't ask.
- **Day 21+:** drop to ambient mode: monthly health-relevant touches only (refill logistics, appointment prep, new significant results) — the relationship goes dormant gracefully, never dead, and any clinical signal (new lab, dispense gap) re-activates the warm path immediately.
- Ladder rules: maximum one rung per window, every rung individually suppressible, any user reply resets the ladder, and every message must pass the §4.4 friend-test. Measure: D7/D30 return rate per rung, opt-out rate < 2% per rung (a higher opt-out means the copy or timing is wrong — fix, don't push harder).

## 4.6 The First 30 Days — how the app evolves with the user

The app is not the same product on Day 1 and Day 30; screens, permissions, and ambient data mature on a designed curve. Build this as explicit feature-state machines keyed on `daysSinceOnboarding`, data-richness, and engagement signals — not hardcoded day numbers alone.

| Stage | Experience state | Permissions & data asks | What unlocks |
|---|---|---|---|
| **Day 0 (first session)** | Conversation-first onboarding; Today shows 1 moment max; First Light insight | Sign in with Apple; records connect (skippable); HealthKit *read* core types only | The relationship |
| **Day 1–2** | Thread grows to 2 moments; first habit proposed conversationally (never day-0 — earn it); Currents shows 3 pieces | Notifications asked *after* first delivered value; med reminders offered only if meds exist | Quick Log, med list |
| **Day 3–5** | First pattern-quality insight if data supports it; tide visualization appears once ≥3 days of signal; companion makes its first proactive (non-reply) touch | HealthKit *background delivery* enabled silently (already authorized); channel-link offer ("text me anywhere") appears once rapport exists | Insights Hub populates; omnichannel |
| **Day 7** | First weekly reflection (gentle, 2 sentences + one visual); journey check-in; Memory Orbs begins collecting | Device integrations prompted *contextually*: CGM (Dexcom/Libre via HealthKit) offered only when glucose matters to their conditions; BP cuff / scale similarly | Weekly rhythm |
| **Day 14** | Trends view rich enough to be interesting; first Opportunity insight (program/savings) if eligible — never before trust is established | Epsilon consent *re-confirmed in context* the first time it visibly powers something ("I timed this for your evening because mornings are chaos — that's the personalization you approved; still good?") | Sponsored surface eligibility |
| **Day 30** | First Cinematic Recap offered (the month-one film); light-garden visibly grown; companion references month-old details naturally | Watch app + widgets promoted now (not day 1 — they're meaningless without data) | The recap reward loop |

**Ambient data doctrine:** the product must progressively *stop depending on manual entry.* By Day 7 the default state is: records auto-refresh (BGAppRefreshTask + server webhooks), HealthKit background delivery streams steps/sleep/HR/glucose/BP/weight as devices write them (HKObserverQuery + enableBackgroundDelivery), dispense events arrive via Surescripts server-side, and the companion *acknowledges ambient data so the user knows it's working* ("your cuff synced — nice steady week"). Manual entry remains for what only the user can know (symptoms, mood, context). Every ambient source has a visible freshness state in Privacy Center.

---

# 5 · Design Principles (Binding)

1. **The companion is the hero.** Craft it like Picasso would — one obsessively perfected living form. Everything else recedes in its presence.
2. **Calm by default; light is the language of attention.** No reds, no alarms; warmth and luminance shifts carry meaning.
3. **Nothing is boxy.** No hard-cornered cards, no default rectangles. Continuous-corner organic radii (≥28pt on surfaces), capsule and blob forms, asymmetric arcs. Layouts breathe along curves.
4. **Motion is physics, not decoration.** Everything moves on springs (§10.1); nothing linearly fades or instantly appears. Transitions morph (matched geometry) instead of cut.
5. **Warm earth + deep night.** A warm, inviting, earthy material world (light mode) and a deep indigo-night luminous world (dark mode) — fused with liquid glass and light play (§6).
6. **Delight within function.** Effects never compete with content. Shaders and light live in the chrome, the companion, and transitions — body text, numbers, and clinical content sit on calm, highly legible ground.
7. **Three taps to anything critical. One screen, one job.**
8. **Trust is a design primitive.** Provenance chips, sponsorship chips, consent clarity — rendered beautifully, never as legal lint.

# 6 · Design Language Spec

The aesthetic north stars (give these to the model as taste references, replicate the *qualities*, not the artifacts): **Gleb Kuznetsov** (dribbble.com/glebich) — clean luminous gradients, pastel-on-deep-blue, fluid motion design that feels engineered and alive; **Genie** (geniegetsme.com, @NelsonNoa) — light as a material: glows, caustics, soft volumetric falloff across an entire product; **Janum Trivedi** (janum.co) — spring-physics fluid interfaces, iOS 17+ SwiftUI shader ripples and distortions that respond to touch; **Minsang Choi** (github.com/radiofun) — Metal/SwiftUI shader gradient and distortion studies; **@loremdeloop** — fluid simulation surfaces. The brief: *if Apple's Health team saw this app, they should feel behind.*

## 6.1 Color

Two worlds, one soul. All colors as semantic tokens (never hardcoded in views).

**Light — "Clay & Dawn":** base `#FAF6F0` (warm porcelain); surfaces `#F3ECE2`; ink `#2B2723` (warm near-black); muted ink `#8A8178`. Accents: terracotta `#D98E73`, sage `#A8BCA1`, dusty sky `#9DB8CF`, sand gold `#E5C898`. Companion gradient (light): peach→rose→soft violet (`#FFD9C2 → #F2B8C6 → #C9B8E8`).
**Dark — "Indigo Night":** base `#0E1226` (deep blue-indigo, *never* pure black); surfaces `#171C36`; raised `#1F2547`; ink `#F2EFE9` (warm white); muted `#8E94B8`. Accents become luminous pastels: coral glow `#FFA487`, mint `#9FE8C5`, sky `#8FC6FF`, lavender `#C8B6FF`. Companion gradient (dark): aurora — teal→violet→rose (`#6EE7D8 → #9D8CFF → #FF9FB2`).
Meaning-without-alarm scale: attention = warm amber luminance increase; urgent-clinical = deeper warm orange + haptic + copy, still no red. Reference ranges on charts: soft gradient bands, neutral.

## 6.2 The Living Gradient (app-wide ground)

Backgrounds are never flat: an ultra-slow (60–90s cycle) multi-stop mesh/shader gradient (§10.2) tuned per time-of-day (dawn warm-rose → day porcelain → dusk amber → night indigo) and modulated ±5% luminance by app state. Imperceptible in any single second; alive over a minute.

## 6.3 Shape & Layout

Continuous-corner (squircle) everything; surface radius tokens 28/36/44pt. Organic blob masks (slowly morphing superellipse paths) for imagery and the light-garden. The Story timeline spine is a curved Bézier, not a straight line. Liquid-glass (`.ultraThinMaterial` + custom refraction shader §10.5) reserved for: the dock, floating chips, sheet headers — glass is seasoning, not the meal, and always sits over the living gradient so it has something to refract.

## 6.4 Typography — a two-voice system

Two complementary voices, used with discipline:

- **The Serif voice — "New York" (Apple's system serif) or a licensed equivalent (e.g., Tiempos Text/Headline):** used where the app *speaks with warmth and gravity* — Insight Hub headlines, Currents reading face (Reads set entirely in serif at 19/30 with a 60–68ch measure), Story chapter titles, Cinematic Recap title cards, milestone copy, and the companion's *emphasized* lines (pull-quote moments in conversation). Optical sizes respected (display cuts for ≥28pt, text cuts for body). **Legibility law:** no swash alternates, no discretionary ligatures, no italic-only passages over 2 lines, contrast AA at all sizes — distinctive, never precious.
- **The Rounded sans voice — SF Pro Rounded:** UI chrome, numbers, labels, buttons, conversation body, data. SF Pro Text for dense secondary content.
- Pairing rules: never both voices at the same hierarchy level on one surface; serif owns *meaning moments*, sans owns *function*. Numbers always sans (monospaced digits). Dynamic Type fully supported across both; serif body floors at 17pt equivalent.

## 6.5 Data Visualization

Charts are drawn, not charted: a single luminous line (2.5pt) with a soft outer glow (shadow radius 8, accent at 35%), under-fill as a vertical gradient fading to clear, animated draw-on with a spring; points appear only on scrub (with a fluid magnifier lens). Axes whisper (hairline, muted ink 30%). The medication tide and habit light-garden are generative Canvas/Metal scenes, not charts.

## 6.6 Motion & Delight Budget

Springs only (response 0.35–0.55, damping 0.75–0.85 for UI; bouncier 0.6–0.7 damping for delight moments). Every screen transition is a matched-geometry morph or a fluid dissolve. **Delight budget per session: at most one "bloom" moment** (kept habit, milestone, insight reveal) gets the full treatment — light bloom + orb shimmer + soft haptic (`.success` softened). Everything else stays calm. Micro-interactions (toggle, tap, dismiss) get ≤150ms of spring acknowledgment. All motion respects `Reduce Motion` (crossfade fallbacks) — accessibility is non-negotiable.

## 6.7 Iconography & Illustration

**No SF-Symbol-default look, no stock Lottie.** Custom icon set: 1.8pt rounded strokes, open organic forms, slight asymmetry (drawn, not generated). Illustrations: abstract warm-earth + light scenes (gradients, glass, glow — no flat corporate people vectors). The only "character" in the app is the orb. Empty states get a small generative light scene + one warm line of copy, never a sad clipboard.

## 6.8 Sound & Music — the Score (supporting role, never the hero)

The app has a *score*, composed like film music: it works the emotion underneath while the eyes stay on the function. Hans Zimmer discipline — texture and swell, not melody and hook; if the user ever *notices the music instead of the moment*, it's too loud or too present.

- **Architecture — an adaptive stem engine (AVAudioEngine):** a small palette of instrumental stems (warm analog pads, soft felt piano, low strings, air/texture beds — no lyrics, no percussion-forward loops) in 3 intensity layers each, key-matched so any combination is harmonic. The engine cross-fades stems (equal-power curves, 1.2–2.5s fades) against app state, never hard-cuts.
- **Where music exists (allowlist — silence is the default state of the app):** onboarding's first 90 seconds (a single warm bed that *resolves* on First Light); voice conversations (a barely-there air bed under the companion's voice, ducked −18dB below speech, §10.12); Cinematic Recaps (the full treatment — this is the one place the score leads); milestone blooms (a 2–3s harmonic swell synced to the light bloom, not a "ding"); Currents Watches/Listens where the piece itself is scored. **Everywhere else: no music.** Browsing records, logging, reading — silent except micro-sounds.
- **Micro-sound palette (≤120ms, mixed at −24 to −30dBFS):** soft felt-piano tick (habit kept), glass-touch (orb tap), low warm whoosh (pull-to-talk stretch), grain shimmer (insight reveal), exhale pad (Thread resolving to "you're set"). Every micro-sound has a haptic twin; sounds derive from 2–3 source timbres so the app has *one sonic identity*, not a UI-sound junk drawer.
- **Mixing laws:** respect the silent switch absolutely (haptics carry meaning when muted); duck instantly for VoiceOver, calls, and user media (`.duckOthers` only during companion speech, `.mixWithOthers` ambient otherwise); master sound toggle + per-class toggles in Settings; loudness-normalized stems (−23 LUFS program, micro-sounds peak-limited); no sound ever fires twice within 400ms (debounce at the engine).
- **Timing is the craft:** every scored moment is keyframed against its animation (the swell's peak lands on the bloom's apex frame; the recap's first chord lands on the first title card). Build a `MomentScore` descriptor (audio cue + haptic pattern + animation curve, one timeline) so sound/haptic/motion ship as a single synchronized unit (§10.12).

---

# 7 · The Companion — Hero Spec

## 7.1 Form: the Orb

A soft, luminous, breathing sphere of layered translucent gradient shells — think a small aurora held in glass (Kuznetsov palette, Genie light). Built as a Metal-backed SwiftUI view (§10.6): 3–4 noise-displaced gradient layers, additive blending, specular kiss on top, soft volumetric halo. **Not** a face, not a mascot, not a blob with eyes. It breathes (scale 1.00→1.03, 4s cycle) at rest.

**States (continuous morphs, never cuts):** ambient (slow breath, cool-calm palette) · listening (leans toward touch point, brightens, ripples at contact §10.3) · thinking (inner layers swirl faster, shimmer traverses) · speaking (gentle pulse synced to text cadence) · celebrating (single bloom: brief expansion + light burst + halo ring) · concerned (warmth deepens, motion slows and steadies — gravitas through stillness) · resting (night palette, dimmed, slower breath after 22:00).

The orb persists minimized (32pt, top-right, glass chip) on every non-chat screen; tap from anywhere → conversation morphs open around it (matched geometry — the orb *is* the transition anchor).

## 7.2 Conversation Surface

Full-bleed scene (no boxed chat window): living gradient ground, orb top-center that drifts subtly as conversation flows. Companion text renders in Rounded type directly on the canvas with a soft text-glow on key phrases; user messages in glass capsules right-aligned. Streaming text arrives with a gentle per-word fade-rise (no typewriter clatter). Rich inline elements render as organic surfaces *inside* the conversation: a lab trend, a habit proposal card (accept = one tap), a draft message to the care team (approve/edit), a program enrollment sheet, a copay card. Voice input: hold the orb to talk; live waveform rendered as ripples through the orb itself.

## 7.3 Voice & Behavior (prompting/server-side, but binds UI copy)

Tone: a wise, warm friend with clinical depth — Marcus's test. Short by default; depth on request. MI techniques in practice (open questions, reflections, rolling with resistance); SDT framing (autonomy, competence, relatedness); HBM/COM-B/TTM as reasoning lenses. Never diagnoses, never prescribes, never alarms; clinical heads-ups follow the three-tier disclosure (what this is → what to do next → one-tap path to a person). Every clinical statement carries a provenance chip. All outbound actions (messages to care team, enrollments, deliveries) require explicit user confirmation in-line. Crisis language triggers an immediate, calm handoff pattern with human resources — designed, not bolted on.

## 7.4 Memory Made Visible

A "what I know about you" surface in Privacy Center *and* invocable in chat ("what do you remember about me?") — values, preferences, tone setting, patterns learned. Every item editable/deletable. Memory transparency is both an ethical requirement and a relational reward (§4.1).

## 7.5 Voice Mode — the companion, spoken (P0 core)

An ultra-realistic, natural voice (ElevenLabs Conversational AI via their Swift SDK, or equivalent realtime stack) turns the companion into someone you *talk with* — and the UI is designed around the voice, Kuznetsov-style, not bolted beside it.

- **Entering voice:** hold the orb (from anywhere) → the whole screen *exhales* into the voice scene: chrome melts away (fluid dissolve §10.4), the living gradient deepens, the orb grows to ~180pt center-stage. One gesture in, one gesture out (tap anywhere or say "that's all for now").
- **The orb is the voice visualization:** no waveform bars. While the *user* speaks, their voice ripples *into* the orb (mic amplitude drives the §10.3 ripple at the orb's rim — it visibly *listens*). While the *companion* speaks, the orb's inner shells pulse with the actual TTS amplitude envelope (energy parameter driven by audio output tap), light blooming softly on stressed syllables. Thinking = the shimmer traversal. The result: a conversation with a small aurora that breathes with both of you.
- **Fluid agentic actions mid-voice:** when the companion *does* something while talking ("let me set that delivery up… done"), the action materializes as a glass artifact that floats up beside the orb (a delivery confirmation, a drafted message, a chart), holds while relevant, then drifts away — the user watches work happen without leaving the conversation. Confirmations stay verbal-first with the artifact as visual receipt; anything consequential still requires an explicit "yes" (spoken or tapped).
- **Mechanics:** barge-in supported (user can interrupt; TTS ducks instantly); live transcript available via a subtle swipe-up sheet (accessibility + trust); locale-aware; latency budget: first audible response ≤ 1.2s (use streaming TTS; play the first phrase while the rest generates); CallKit-style audio session handling (route changes, AirPods, interruptions); voice mode fully functional with screen locked via background audio when in an active session.
- **The voice itself:** one signature Nudge voice (warm, unhurried, mid-register), professionally tuned — pace ~0.95×, gentle prosody; *no* user-facing voice marketplace at launch (one voice = one relationship); pitch/pace micro-adapts to context (slower and lower for concerned moments, brighter for celebrations).

## 7.6 Voice Notes — spoken moments, used sparingly (P0)

Sometimes text is not enough. The companion can leave a **voice note** (TTS-rendered, plays inline as a glowing capsule with the orb miniature pulsing) — but only at moments where hearing a voice materially deepens the moment:

- **Milestone moments:** the Day-30 recap intro, a journey completed, a meaningful trend confirmed ("Marcus — three months ago this number scared you. Look at it now.") — 15–25 seconds, scored under (§6.8).
- **Emotional support moments:** after a hard log or a tough conversation (a hospitalization, a bad result the care team has already delivered), a brief human-register note lands differently than text — 10–20 seconds, no music, slower voice.
- **Welcome-backs:** the Day-7 ladder rung (§4.5) may be a voice note where the channel supports it.
- Discipline: ≤ 2 voice notes/week, never for logistics, always with a one-line text summary beneath (accessibility + skimmability), always skippable, and the user can turn voice notes off entirely. The rarity is the power — a voice note from Nudge should feel like a handwritten card, not a robocall.

## 7.7 Rapport & the Nostalgia Layer — a friend from childhood

The companion's deepest design goal: the texture of a *lifelong* friendship — someone who knows your history, your jokes, your teams, your hard years — established quickly and honestly.

- **Rapport mechanics (server-side behavior, binds UI):** continuity callbacks ("last month you said mornings were the enemy — still true?"); earned inside references (the Braves shorthand emerges naturally after games are discussed, never cold-opened from Epsilon data the user hasn't surfaced — *Epsilon informs timing and framing; the user's own words earn the explicit references*); remembered stakes (DeShawn's college timeline) handled with care; self-consistency (the companion has its own steady temperament, gentle humor, and admits what it doesn't know — friends aren't sycophants, and §user-wellbeing honesty rules apply).
- **The Nostalgia Layer (visual + conversational, consent-aware):** warmth compounds when the world around the conversation carries faint echoes of the user's formative era (derived from age band, refined by Epsilon cultural-affinity signals, and *user-adjustable* in Settings → Appearance → "Era warmth: off / subtle / full"). This is seasoning at 5–10% intensity, never a theme park:
  - For a user whose childhood was the **'90s** (Marcus): the conversation scene's ambient palette can drift toward warm VHS-sunset tones at dusk; milestone blooms may carry a faint scanline-glow or polaroid-develop reveal (a Metal grain/bloom variant, §10.10); the score palette adds a soft tape-saturated pad; the companion's references skew era-fluent when celebration calls for it ("that's a mixtape-worthy week").
  - For an '80s childhood: warmer film-grain golds, vinyl-crackle-soft texture in the celebration sound (sub-audible, −30dB). For 2000s: cleaner glow, brighter pastels.
  - Hard rules: nostalgia never touches clinical surfaces (records, labs, meds stay timeless-calm); never reduces legibility; defaults to *subtle*; and the companion never fakes biographical memory ("remember when we…" about things that didn't happen is banned — nostalgia is ambiance and fluency, not fabricated history).

---

# 8 · Screen Inventory (build checklist)

| # | Screen | Key elements | Pri |
|---|---|---|---|
| 1 | Welcome / Auth | living gradient, orb birth animation, Sign in with Apple | P0 |
| 2 | Onboarding conversation | 3-question flow, tone picker as conversational choice | P0 |
| 3 | Record connect | b.well portal search, progressive discovery narration, skip path | P0 |
| 4 | HealthKit permission | purpose-led, scoped types | P0 |
| 5 | Epsilon consent | plain-language, equal-weight decline | P0 |
| 6 | Today canvas | orb ambient, Thread (≤3 moments), pull-to-talk, dock | P0 |
| 7 | Conversation | full-bleed scene, streaming, inline rich elements, voice | P0 |
| 8 | You — Story | curved timeline, chapters, milestones | P0 |
| 9 | You — Records drawer | 7 categories, search, row→explain sheet | P0 |
| 10 | Lab detail / Trend | glow chart, range bands, scrub lens, annotations | P0 |
| 11 | Medications | list, tide visualization, supply countdown | P0 |
| 12 | Med detail | purpose, schedule, refill intelligence entry | P0 |
| 13 | Quick Log | 3-tap flow, fluid severity slider | P0 |
| 14 | Journeys home | active journeys, light-garden | P0 |
| 15 | Journey detail | atomic habits, schedule, companion adjust | P0 |
| 16 | Program browse/enroll | sponsored chip pattern, opt-in sheet | P0 |
| 17 | Care team & appointments | list, visit-prep brief | P0 |
| 18 | Visit Prep | one-screen brief, send-ahead approval | P0 |
| 19 | Privacy Center | consent ledger, Epsilon view/edit, export, delete | P0 |
| 20 | Settings | notifications by class, quiet hours, tone, appearance, era warmth, sound | P0 |
| 21 | Insights Hub | editorial flow, filters, lifecycle states, outcome threads | P0 |
| 22 | Currents | full-bleed paging, 4 formats, daily-set end scene, taste controls | P0 |
| 23 | Voice Mode scene | orb center-stage, ripple listening, floating glass artifacts, transcript sheet | P0 |
| 24 | Cinematic Recap player | full-screen film, skip, share render | P0 (milestones) |
| 25 | Memory Orbs | honeycomb parallax lattice, orb→moment morph, year zoom | P1 |
| 26 | Document scan/upload | VisionKit scan → OCR → merge | P1 |
| 27 | Body view | abstract figure, regional glow | P1 |
| 28 | Food log | photo-first, mood/hunger context | P1 |
| 29 | Family circle | proxy roles | P1 |
| 30 | Widgets / Live Activity / Watch | habit moment, supply, voice check-in | P1 |
| 31 | Connect flow (multi-rail) | provider/insurer search, rail-routed portal sign-in, progressive sync narration, freshness states | P0 |
| 32 | Sponsored moment surfaces | presentation grammar (why→fit→action→disclosure), program detail sheet, decline granularity | P0 |
| 33 | Brain Vault | vault browser, grants ledger, scope-approval sheet, export/delete | P1 (MCP P2) |
# 9 · Omnichannel — the Companion Beyond the App (Photon Spectrum)

The companion is one brain with many doors. The iOS app is the rich home; iMessage, WhatsApp, and Telegram are ambient extensions via **Photon Spectrum** (open-source TypeScript SDK + Spectrum Cloud; `npm install spectrum-ts`; sub-second edge delivery; adaptive content rendering maps rich elements to each platform's native primitives).

## 9.1 Architecture

```
iOS app ──────────────┐
iMessage ─┐           │
WhatsApp ─┤ Spectrum  ├──► Nudge Agent Gateway ──► Behavioral AI orchestrator (L5)
Telegram ─┘ (edge)    │         │                      │ tools: records, meds, habits,
                      │         └─ identity resolver   │ logging, programs, care-team drafts
                      │            (phone ↔ Nudge ID,  └─ same memory, same governor (§4.4)
                      │             verified at link)
```

- **Single conversation state:** channel-agnostic conversation store keyed on Nudge user ID. A thread started in iMessage continues seamlessly in-app and vice-versa; the app shows a unified history with subtle channel glyphs.
- **Channel linking:** in-app flow ("Text me anywhere") → user sends a one-time code to the Nudge number (or taps a deep link for WhatsApp/Telegram). Phone-number identity is verified before any PHI flows; until verified, the agent stays in general-wellness mode.
- **Capability tiering by channel (PHI policy):** In-app = full clinical depth. iMessage/WhatsApp/Telegram = behavioral coaching, habit moments, check-ins, logistics, and *referenced* (not enumerated) clinical content — "your latest result is in, it's good news; open Nudge for the details" with a deep link. Explicit user setting can raise/lower channel depth; default conservative. All channels obey the same notification governor and quiet hours.
- **Spectrum implementation sketch (server, TypeScript):**

```ts
import { Spectrum, imessage, whatsapp, telegram } from "spectrum-ts";

const spectrum = Spectrum({ providers: [imessage(), whatsapp(), telegram()], config: { cloud: true } });

spectrum.onMessage(async ({ space, message }) => {
  const user = await identity.resolve(space.participant);          // phone → Nudge ID (or null)
  const reply = await nudgeAgent.run({ user, channel: space.platform,
    content: message, capability: capabilityFor(user, space.platform) });
  for (const part of reply.parts) await space.send(render(part));  // adaptive rich rendering
});

// Behaviorally-timed outbound (from the governor, not cron):
await spectrum.send(user.phone, imessage().fallback(whatsapp()), habitMoment(payload));
```

- **Use the channel's native delight:** iMessage tapbacks as lightweight habit confirmations ("❤️ this when you've taken it"), polls for quick check-ins, link previews that render Nudge moments beautifully.

# 10 · Technical Architecture & Reference Code

## 10.0 Stack

- **iOS 17+ minimum** (required for SwiftUI shader APIs `colorEffect/distortionEffect/layerEffect`), Swift 5.10+, SwiftUI-first; Metal for the orb and living gradient; TCA *not* required — use lightweight `@Observable` MVVM + a small Redux-style store for conversation state.
- **Persistence:** SwiftData (models below) + encrypted blob store for documents; **all PHI in Core Data/SwiftData protected with `NSFileProtectionComplete`; secrets in Keychain; no PHI in UserDefaults, logs, or analytics.**
- **Networking:** async/await `URLSession` client → Nudge backend (REST + SSE for token streaming); background refresh via `BGAppRefreshTask` for record sync; HealthKit background delivery observers.
- **Conversation streaming:** SSE; render tokens through the per-word fade-rise (§7.2).
- **Notifications:** APNs + local; categories per class (§4.4) with action buttons (Taken / Snooze / Open).
- **Analytics:** privacy-first, no third-party trackers; event allowlist; nothing keystroke-level; Epsilon signals flow server-side only.
- **Backend contract (the app consumes; backend is out of scope for the iOS build but stub these):** `GET /v1/home/thread` (≤3 moments) · `GET /v1/records/{category}` · `GET /v1/labs/{id}/explain` · `POST /v1/logs` · `GET/POST /v1/journeys` · `POST /v1/conversation` (SSE) · `GET /v1/meds` + `POST /v1/meds/{id}/barrier-fix` · `GET /v1/visit-prep/{apptId}` · `GET/PUT /v1/consents` · `POST /v1/channels/link`.

## 10.1 Spring System (the only animation vocabulary)

```swift
enum NudgeSpring {
    static let ui = Animation.spring(response: 0.42, dampingFraction: 0.82)        // standard
    static let gentle = Animation.spring(response: 0.55, dampingFraction: 0.86)    // large surfaces
    static let delight = Animation.spring(response: 0.38, dampingFraction: 0.66)   // blooms only
}
// Usage rule: no .linear, no .easeInOut anywhere in app code. Matched-geometry morphs for all
// navigation (orb is the shared anchor into conversation; record rows morph into detail sheets).
```

## 10.2 Living Gradient (background, Metal via SwiftUI colorEffect)

```swift
// LivingGradient.metal
#include <metal_stdlib>
using namespace metal;
[[ stitchable ]] half4 livingGradient(float2 pos, half4 color, float2 size, float t,
                                      half4 c0, half4 c1, half4 c2) {
    float2 uv = pos / size;
    // three slowly-orbiting soft radial centers (90s feel: pass t = time * 0.011)
    float2 p0 = 0.5 + 0.42 * float2(sin(t*0.9), cos(t*0.7));
    float2 p1 = 0.5 + 0.38 * float2(sin(t*0.5 + 2.1), cos(t*1.1 + 1.3));
    float2 p2 = 0.5 + 0.45 * float2(sin(t*0.7 + 4.2), cos(t*0.4 + 3.7));
    half w0 = half(exp(-3.5 * distance(uv, p0)));
    half w1 = half(exp(-3.5 * distance(uv, p1)));
    half w2 = half(exp(-3.5 * distance(uv, p2)));
    half4 g = (c0*w0 + c1*w1 + c2*w2) / max(w0+w1+w2, half(0.001));
    return half4(g.rgb, 1.0h);
}
// SwiftUI: Rectangle().colorEffect(ShaderLibrary.livingGradient(.float2(size), .float(time), …))
// Drive `time` with TimelineView(.animation(minimumInterval: 1/30)); pause when scenePhase != .active.
```

## 10.3 Touch Ripple / Fluid Distortion (Janum-Trivedi-style, distortionEffect)

```swift
// Ripple.metal — apply to the conversation canvas and pull-to-talk stretch
[[ stitchable ]] float2 ripple(float2 pos, float2 origin, float t, float amplitude,
                               float frequency, float decay) {
    float d = distance(pos, origin);
    float delay = d / 1200.0;                       // wave propagation speed (pt/s)
    float time = max(0.0, t - delay);
    float r = amplitude * sin(frequency * time) * exp(-decay * time);
    return pos + normalize(pos - origin + 0.0001) * r;
}
// SwiftUI: .distortionEffect(ShaderLibrary.ripple(.float2(touchPoint), .float(elapsed),
//          .float(12), .float(14), .float(7)), maxSampleOffset: CGSize(width: 24, height: 24))
// Trigger on orb touch and on send; keep elapsed ≤ 1.2s then remove the modifier.
```

## 10.4 Fluid Dissolve (dismissing a Thread moment)

```swift
// Melt.metal — alpha erosion driven by simplex-ish hash noise; progress 0→1 on NudgeSpring.ui
[[ stitchable ]] half4 melt(float2 pos, half4 color, float progress, float2 size) {
    float2 uv = pos / size;
    float n = fract(sin(dot(floor(uv * 28.0), float2(12.9898, 78.233))) * 43758.5453);
    half a = color.a * half(smoothstep(progress, progress + 0.18, n + uv.y * 0.25));
    return half4(color.rgb, a);
}
```

## 10.5 Liquid Glass chrome

```swift
struct GlassSurface<Content: View>: View {
    var radius: CGFloat = 36
    @ViewBuilder var content: Content
    var body: some View {
        content
            .background(.ultraThinMaterial, in: .rect(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(.linearGradient(colors: [.white.opacity(0.35), .white.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: .black.opacity(0.10), radius: 24, y: 8)
        // Optional: add a subtle refraction by layering a low-amplitude ripple distortion
        // sampling the living gradient behind (layerEffect) — chrome only, never over body text.
    }
}
```

## 10.6 The Orb (Metal-backed SwiftUI; the single most important view in the app)

Composition: 3 noise-displaced gradient shells (additive), specular highlight, volumetric halo; state machine drives palette, displacement amplitude, and breath rate. Sketch:

```swift
@Observable final class OrbState {
    enum Mode { case ambient, listening, thinking, speaking, celebrating, concerned, resting }
    var mode: Mode = .ambient
    var energy: Double = 0      // 0…1, eased toward target per mode with NudgeSpring.gentle
}

// Orb.metal core idea — fbm-displaced sphere shells rendered in a fragment shader:
[[ stitchable ]] half4 orbShell(float2 pos, half4 _, float2 size, float t, float energy,
                                half4 inner, half4 outer) {
    float2 uv = (pos / size) * 2.0 - 1.0;
    float r = length(uv);
    float wobble = 0.06 * (0.4 + energy) * sin(6.0*atan2(uv.y,uv.x) + t*1.6)
                 + 0.04 * sin(11.0*atan2(uv.y,uv.x) - t*1.1);     // organic rim displacement
    float edge = smoothstep(0.78 + wobble, 0.58 + wobble, r);      // soft body
    float halo = exp(-6.0 * max(0.0, r - 0.8)) * (0.25 + 0.5*energy);
    half4 body = mix(outer, inner, half(smoothstep(0.85, 0.0, r)));
    return half4(body.rgb * half(edge) + outer.rgb * half(halo), half(edge) + half(halo));
}
// Render 3 instances with phase-offset t, different palettes, .blendMode(.plusLighter),
// inside a TimelineView; breath = scaleEffect(1 + 0.03 * sin(t / breathPeriod)).
// listening: increase energy to 0.7 + apply §10.3 ripple at touch; celebrating: one-shot
// energy spike to 1.0 with halo ring (expanding stroked circle, opacity → 0 on .delight spring).
```

## 10.7 Glow Trend Chart

Swift Charts `LineMark` with `.interpolationMethod(.catmullRom)`, `.shadow(color: accent.opacity(0.35), radius: 8)`, `AreaMark` gradient fill to clear, draw-on via animating an `x` domain trim; scrub overlay = `chartOverlay` drag gesture with a glass magnifier lens.

## 10.8 SwiftData Models (core)

```swift
@Model final class UserProfile { var id: UUID; var name: String; var tonePreference: String;
    var quietHours: ClosedRange<Int>; var epsilonConsent: Bool; var channelDepth: [String:String] }
@Model final class ClinicalRecord { var id: String; var category: String;  // lab/med/condition/…
    var date: Date; var payload: Data; var sourceName: String; var sourceFetchedAt: Date }
@Model final class Medication { var id: String; var name: String; var purposeLine: String;
    var schedule: Data; var supplyDaysRemaining: Int?; var lastDispense: Date? }
@Model final class SymptomLog { var id: UUID; var kind: String; var severity: Double;
    var at: Date; var note: String?; var photoRef: String?; var companionAcked: Bool }
@Model final class Journey { var id: UUID; var title: String; var habits: [AtomicHabit];
    var gardenSeed: Int }                                  // seeds the generative light-garden
@Model final class AtomicHabit { var id: UUID; var title: String; var contextRule: String;
    var keptDates: [Date] }                                // no streak fields. ever.
@Model final class ConversationTurn { var id: UUID; var role: String; var channel: String;
    var content: Data; var at: Date }                      // unified cross-channel history
@Model final class ConsentEntry { var source: String; var scope: String; var granted: Bool;
    var at: Date }
```

## 10.9 Asset Manifest (produce during build)

App icon (orb at dawn, both appearances); custom icon set (~40 glyphs, 1.8pt rounded strokes — Today, You, Journeys, Currents, log kinds, record categories, channel glyphs); 6 generative empty-state scenes; light-garden element sprites (8–12 glow forms); haptic patterns (CHHapticEngine: soft-bloom, gentle-tick, success-warm); music stem palette per §6.8 (3 beds × 3 intensities + 6 micro-sounds, sourced/commissioned, loudness-normalized); era-warmth shader LUT variants ('80s/'90s/'00s grain-bloom).

## 10.10 Verified Reference Library (real repos — use, adapt, and extend)

The coding agent should pull from these *actual* sources first (all verified live), and may search for more on its own judgment:

- **`github.com/jtrivedi/Wave`** — Janum Trivedi's spring-based animation engine (MIT, SPM). Use for re-targetable, interruptible springs where SwiftUI's springs fall short: the orb's continuous state morphs, pull-to-talk rubber-banding, dock magnetics. Its velocity-preserving retargeting is exactly the "fluid arc to a new destination" feel this app needs.
- **`github.com/radiofun/MetalPlayground`** — Minsang Choi's SwiftUI + Metal shader prototype collection. Mine it for gradient-flow, distortion, and touch-reactive shader patterns; adapt (don't import wholesale) into the living gradient and orb shells.
- **`github.com/twostraws/Inferno`** — Paul Hudson's Metal shader library for SwiftUI (water/ripple, shimmer, gradient, warping shaders with clean `[[stitchable]]` signatures). Strong starting points for the melt dissolve, shimmer traversal (thinking state), and ink-wash/brushstroke reveals in Cinematic Recaps and Currents page transitions (start from its warp/dissolve shaders; art-direct toward brushstroke with a stroke-mask texture).
- **`github.com/EmergeTools/Pow`** — the Pow effects library (formerly Moving Parts): production-quality SwiftUI transitions/effects (glow, shine, rise, spray). Use *sparingly* for bloom-adjacent moments; everything must be re-skinned to Nudge tokens.
- **Apple WWDC24 "Create custom visual effects with SwiftUI"** + its sample code (developer.apple.com) — the canonical ripple `distortionEffect` and `layerEffect` patterns; the §10.3 shader follows this lineage. Also WWDC23 "Explore SwiftUI animation" for matched-geometry morph discipline.
- **`github.com/elevenlabs`** — ElevenLabs' official SDKs (Swift SDK for Conversational AI; streaming TTS APIs). Use for §7.5 voice mode and §7.6 voice notes. Verify current package name/API at build time; wrap behind a `VoiceProvider` protocol so the vendor is swappable.
- **`github.com/photon-hq`** (spectrum-ts, imessage/whatsapp SDKs) — the omnichannel gateway per §9.
- Honorable hunting grounds (agent's discretion): Apple's HealthKit background-delivery sample code; Swift Charts WWDC sessions for the scrub-lens pattern; `cloudkit`-free CRDT-ish sync notes if conversation sync needs offline robustness.

## 10.11 Voice Mode Integration (sketch)

```swift
protocol VoiceProvider {                       // ElevenLabs behind this seam
    func startSession(context: ConversationContext) async throws -> VoiceSession
}
final class VoiceSession {
    let inputLevel: AsyncStream<Float>         // mic amplitude → orb ripple (§10.3 origin at rim)
    let outputLevel: AsyncStream<Float>        // TTS envelope → orb energy (§10.6)
    let transcript: AsyncStream<TranscriptDelta>
    let agentEvents: AsyncStream<AgentAction>  // tool calls → floating glass artifacts
    func interrupt()                            // barge-in: duck TTS within 80ms
    func end() async
}
// Audio session: .playAndRecord, .voiceChat mode, .duckOthers; handle route changes;
// AVAudioApplication mic permission asked at FIRST voice attempt (never onboarding).
// Latency: stream TTS; begin playback at first phrase boundary; target ≤1.2s first-audio.
// Orb binding: orbState.energy = 0.35 + 0.6 * smoothed(outputLevel) while speaking;
// ripple(origin: rimPoint(for: inputAngle), amplitude: inputLevel * 14) while listening.
```

## 10.12 Adaptive Audio Engine + MomentScore (sketch)

```swift
final class ScoreEngine {                       // AVAudioEngine graph: stems → submix → limiter
    func enter(_ scene: ScoreScene)             // .silent (default), .onboarding, .voice, .recap
    func play(_ moment: MomentScore)            // one-shot synchronized moment
}
struct MomentScore {                            // sound + haptic + motion as ONE timeline
    let audio: AudioCue?                        // file, gainDB, offset to animation keyframe
    let haptic: HapticPattern                   // CHHaptic descriptor
    let animationSync: KeyframeAnchor           // e.g. .bloomApex — engine schedules audio so
}                                               //   the swell peak lands on this exact frame
// Laws in code: equal-power crossfades (1.2–2.5s); duck -18dB under speech; debounce 400ms;
// silent-switch respected (haptics still fire); all stems -23 LUFS; scene .silent whenever
// the user is reading records/labs — assert in debug if a stem plays on a clinical screen.
```

## 10.13 Layer 1 Data Foundation — Multi-Rail Integration Architecture (deep spec)

The record is the product's oxygen; it cannot depend on one vendor. Build a **rail router** behind the single patient-facing Connect flow. Backend scope (the iOS app consumes the unified API; build the rails as a separate service workspace), but the iOS agent must understand this to build the Connect UX, freshness chips, and reconciliation surfaces correctly.

**The rails, in priority order per source:**

| Rail | What it is | When the router picks it | Data & cadence | Notes |
|---|---|---|---|---|
| **R1 — athenahealth direct (Privia)** | athenahealth developer APIs in provider context via the Privia partnership (B2B2C) | User is a Privia patient (detected at sign-up or provider search) | Richest: problems, meds, labs, vitals, notes, scheduling, *and the write-back path* (advisories into clinician workflow, appointment booking). Near-real-time via subscriptions/webhooks where available, else polled 4–6×/day | The flagship rail — deepest data + the only true bidirectional loop. Build first. |
| **R2 — SMART on FHIR patient access** | Standalone patient-launch OAuth against any §170.315(g)(10)-certified EHR FHIR R4 endpoint — **Epic** (patient-facing app registered on fhir.epic.com; MyChart credentials; USCDI via US Core), **Oracle/Cerner** (code console), Meditech, NextGen, etc. | Any non-Privia provider the user names | US Core resources: Patient, Condition, MedicationRequest, Observation, AllergyIntolerance, Immunization, Procedure, DocumentReference, Encounter. Refresh 1–2×/day per source; honor `_lastUpdated` | Register Nudge as a patient-facing app per vendor program (Epic's patient-app registration is self-service; production access per their terms). Granular scopes; refresh tokens encrypted server-side. |
| **R3 — TEFCA Individual Access (IAS)** | Network-level query through a QHIN offering Individual Access Services | Completeness sweep after R1/R2 for providers without easy portal connection | Document-oriented (C-CDA → parse/normalize); batch | Via a QHIN partner; treat as sweep, not primary. |
| **R4 — Payer Patient Access APIs** | CMS-mandated FHIR Patient Access APIs (claims) incl. Medicare Blue Button 2.0 | User connects their insurer (offered ~Day 14, §4.6) | Claims = utilization the EHRs miss (fills, visits across all systems, costs). Daily pull | Claims are the truth-check for verified activation (§3.14) and PDC adherence. |
| **R5 — Aggregator lane (b.well)** | Aggregator SDK/API as accelerant | Sources not yet covered by R1–R4; launch coverage breadth | Per vendor | A lane, not the foundation. Contract must preserve Nudge's right to run R1–R4 in parallel and to own the reconciled record. |
| **R6 — Surescripts** | Medication history & dispense | Always (server-side) | Near-real-time dispense events | Powers refill intelligence + activation verification. |
| **R7 — Devices/HealthKit** | On-device | Always (§4.6 ambient doctrine) | Continuous background delivery | CGM (Dexcom/Libre via HealthKit), BP cuffs, scales, watch. |
| **R8 — Documents** | VisionKit scan + OCR → structured extraction | User-initiated | On upload | Paper records, immunization cards. |

**The Reconciliation Engine (the hard, differentiating work):**

- Normalize everything to **FHIR R4 / US Core + USCDI v3** internally; map C-CDA (R3) and proprietary payloads (R1, R5) into the same model. Code-system normalization: RxNorm (meds), LOINC (labs), SNOMED CT (problems), CVX (immunizations).
- **Entity resolution & dedup:** deterministic keys first (RxNorm+date for fills, LOINC+specimen-time for labs), probabilistic match second; merge across rails with **full provenance retained** (every merged fact keeps its source list, fetch time, and rail).
- **Conflict policy:** provider-context (R1) > patient-access EHR (R2) > claims (R4) > documents (R8) for clinical facts; most-recent-wins within a tier; conflicts above a significance threshold (active-med discrepancies, allergy conflicts) surface to the patient via the §3.4 "sources differ" pattern *and* to the care team via the R1 advisory channel — reconciliation is a clinical-safety feature, not hygiene.
- **Freshness model:** every fact carries `sourceFetchedAt` + rail; UI freshness chips, the companion's hedging language ("as of your March labs"), and the §11.3 one-data-spine tests all read from it.
- **Failure modes designed in:** portal credential breakage → gentle re-auth moment (never a scary error); rail outage → cached with visible staleness; partial first-sync → progressive narration (§3.1) so slow sources never block First Light.

**Patient-experience law:** the user sees *one* Connect flow, *one* unified record, freshness chips, and rare "sources differ" moments — all rail complexity invisible. Acceptance: ≥95% of US patients can connect ≥1 source via R1–R5; Privia patients reach full-depth sync <5 min; reconciliation false-merge rate <0.1% on the fixture corpus.

## 10.14 Brain Vault & MCP Platform (technical sketch)

```
Vault store (server): patient-scoped graph
  identity/      coverage/        clinical.summary/   meds.current/
  allergies/     immunizations/   preferences.*/      behavioral.profile/
  care.circle/   documents/       grants.ledger/
Each node: value + provenance + visibility tier (private | shareable | clinical-only)

MCP server (per-patient authorization):
  resources: vault://meds.current, vault://allergies, vault://coverage.summary, …
  tools: requestScope(scope, duration, purpose) → in-app grant sheet (push → approve)
         readScope(grantToken) · revoke(grantId)
  every read ledgered: {consumer, scope, at, purpose} → visible in Vault UI
"Connect with Nudge": OAuth-style partner flow; scopes map 1:1 to vault nodes;
  default durations 30/90d, renewable; FHIR/SMART facade for clinical consumers.
Email/calendar rails: on-device/edge classification first (health-relevant only);
  raw mailbox content never persists server-side — extracted structured facts only.
Hard assertions in code: no Epsilon-raw fields in any shareable node; export & delete
  produce/destroy the complete vault; all grants expire by default.
```

# 11 · Quality Bars & Acceptance

- 120fps on ProMotion for canvas, orb, conversation; no hitches > 8ms in Instruments on iPhone 13 and newer; shader work degrades gracefully (static gradient fallback) on thermal throttle and Low Power Mode; voice mode and ScoreEngine add ≤ 8% CPU sustained.
- Cold launch ≤ 1.5s to interactive Today; conversation first-token ≤ 1.2s perceived; voice first-audio ≤ 1.2s; Currents daily set composes < 300ms from cache.
- Full VoiceOver pass (orb states announced; charts get audio graphs; voice mode fully transcript-accessible), Dynamic Type to XXL across both type voices, Reduce Motion fallbacks, WCAG AA contrast in both worlds; all audio optional, all meaning carried redundantly by haptic/visual.
- Zero PHI outside encrypted stores; jailbreak/screenshot of sensitive sheets considerations documented; App Privacy labels accurate.

## 11.3 The Coherence Audit (end-to-end wiring — release gate, not a nice-to-have)

The #1 failure mode of feature-rich apps is silo-designed features. Before any release:

- **One vocabulary:** a single `Glossary.swift` (and matching copy doc) defines every user-facing noun — *moment, insight, journey, habit, current, recap, orb, story*. The same concept never has two names anywhere (a habit is never "goal" in a notification and "task" in settings). Lint copy strings against the glossary in CI.
- **One data spine:** every surface renders from the same stores — the A1c on Today's moment, in the Insights Hub, in Trends, in a Recap, and spoken in voice mode is *the same value from the same source with the same freshness stamp*. No screen-local fetch forks. Cross-surface consistency tests assert this with fixture data.
- **Every feature is wired to the brain:** each module both *feeds* the L5 context (logs, views, dismissals, taste signals) and *receives* from it (companion can reference and act on anything: "open my BP trend," "skip tonight's habit," "save that piece"). A capability matrix in code review: feature × {companion-readable, companion-actionable, insight-eligible, recap-eligible} — empty cells need a written reason.
- **Every loop closes:** any action started anywhere resolves visibly somewhere the user will see it (a sent care-team message shows its reply state; an enrolled program shows its first step on Today; a saved Current appears as an orb). Audit script walks all user-initiated actions to their resolution surface.
- **State sanity across the §4.6 curve:** snapshot-test Day 0/3/7/14/30 fixture states for every P0 screen — no screen may render empty-confusing at any stage (each has a designed not-yet state in the day's voice).
- **Sponsored-engine governance tests (release gate):** automated assertions that (a) no sponsored moment exists without a passing clinical-eligibility record and guideline citation, (b) ranking among clinically-equivalent options is invariant to sponsorship flags, (c) frequency caps and the 14-day cold-start hold, (d) disclosure chip present on 100% of sponsored surfaces, (e) declined programs respect suppression windows. Run against adversarial fixtures (sponsored option clinically inferior → must rank below).
- **Reconciliation tests:** fixture corpus with duplicate/conflicting multi-rail records; assert merge correctness, provenance retention, conflict surfacing thresholds, and that the same fact renders identically on every surface with its freshness stamp.
- Every screen passes the three-question test: 5-second comprehension for a new user · still-pleasing on the 30th view · screenshot-proud.

# 12 · Build Phases (for the coding agent)

1. **Foundation:** tokens (color/two-voice type/shape/spring), living gradient, GlassSurface, navigation shell, SwiftData models, Glossary.swift, API client + stubs with realistic Marcus fixture data **including the Day 0/3/7/14/30 state fixtures and a multi-rail fixture corpus (duplicates/conflicts included)**.
1b. **Rails service workspace (parallel track):** rail router, R1 athena + R2 SMART-on-FHIR (Epic patient app) first, reconciliation engine v1 with provenance, unified-record API + freshness; R4/R3/R5 follow. The iOS Connect flow builds against this from day one.
2. **The Orb:** full state machine + shaders + matched-geometry morph into conversation. Do not proceed until the orb feels alive — this is the soul check.
3. **Conversation (text):** streaming, inline rich elements, ripple effects.
4. **Today canvas + Thread + dock + pull-to-talk.**
5. **You:** Story timeline, records drawer + reconciliation surface, explain sheets, glow charts.
6. **Medications (full depth §3.6) + Quick Log + pattern engine hooks + refill intelligence.**
7. **Journeys + light-garden + habit moments + notification classes/governor + return-ladder hooks.**
8. **Insights Hub + Currents** (all four formats; daily-set logic against fixtures).
8b. **Sponsored Programs Engine (§3.14):** eligibility client surfaces, presentation grammar components (clinical-why → fit → action → disclosure chip), decline/suppression logic, governance test suite, activation-verification hooks into R4/R6 data. Treat this phase with the same craft bar as the orb — it funds everything.
9. **Voice mode + ScoreEngine + voice notes** (§7.5–7.6, §10.11–10.12) — land audio/motion sync via MomentScore before adding more scored moments.
10. **Onboarding end-to-end (incl. consent screens, §4.6 permission sequencing) + Privacy Center + Settings (incl. era warmth, sound).**
11. **Care team, visit prep; Cinematic Recap player; Memory Orbs (P1 flag); Brain Vault surface v1 (§3.15: vault browser, grants ledger, export) — MCP server + Connect with Nudge behind a P2 flag; polish pass: haptics, empty states, delight-budget audit, nostalgia layer at *subtle*.**
12. **Omnichannel:** channel-link flow in-app; Spectrum gateway service (separate TS workspace, §9.1 sketch); unified history rendering; return-ladder channel routing.
13. **Hardening:** §11.3 coherence audit, accessibility, performance, privacy audit, App Store assets.

Fixture data: build the entire app against Marcus (records, meds, logs, Epsilon-style preference profile, 60 days of conversation history, a month of Currents sets, one complete Recap) so every screen demos the real product story at every lifecycle stage.

---
*End of specification. The bar: the best-designed app of the decade in its category — calm enough to trust with your health, alive enough that you miss it when you're away.*
