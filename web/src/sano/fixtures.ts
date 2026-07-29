import { d, daysAgo, hoursAgo, uid, LifeLibrary } from "./lifeLibrary";
import type {
  Persona, Pathway, CareBundle, Program, RecordItem, RecordSource, ConsentEntry,
  MemoryItem, Moment, Insight, Journey, LabSeries, Medication, CareEntry, AgentAction, MemoryGlimpse,
} from "./types";

const range = (n: number) => Array.from({ length: n }, (_, i) => i + 1);

// ============================================================
// Marcus shared fixtures (the metabolic spine)
// ============================================================
const marcusLabs: LabSeries[] = [
  {
    id: "a1c", name: "A1c", unit: "%",
    points: [
      { date: d(2025, 3, 18), value: 9.4 }, { date: d(2025, 6, 10), value: 9.1 },
      { date: d(2025, 9, 22), value: 8.9 }, { date: d(2025, 12, 15), value: 8.7 },
      { date: d(2026, 3, 12), value: 8.4 },
    ],
    band: [4.5, 7.0], bandLabel: "where your care team wants this heading",
    annotation: { date: d(2025, 6, 10), label: "metformin steadied here" },
    provenance: "From your Mar 12 Piedmont lab",
    explainReading: "A1c is a 3-month average of your blood sugar. Yours is 8.4% — still above where your care team wants it, but it has moved down five readings in a row. That direction matters more than any single number.",
    explainNextStep: "Keep doing what's working — steady metformin and the evening walks. Your next draw is around September; if the slide continues you'll be under 8 for the first time in three years.",
    explainAsk: "Want me to put this trend on your visit-prep for Dr. Patterson on June 24?",
  },
  {
    id: "egfr", name: "eGFR", unit: "mL/min",
    points: [{ date: d(2025, 3, 18), value: 78 }, { date: d(2025, 9, 22), value: 75 }, { date: d(2026, 3, 12), value: 74 }],
    band: [60, 90], bandLabel: "stage-2 range", annotation: null,
    provenance: "From your Mar 12 Piedmont lab",
    explainReading: "eGFR estimates how well your kidneys filter. 74 keeps you in stage 2 — mild, and holding steady. Stability is the win here.",
    explainNextStep: "Lisinopril is doing protective work. Staying hydrated on warehouse shifts and easy on ibuprofen are the two things most in your control.",
    explainAsk: "Want a heads-up before each kidney panel so it never sneaks up on you?",
  },
  {
    id: "bp", name: "Home blood pressure", unit: "mmHg",
    points: [
      { date: d(2026, 6, 4), value: 138 }, { date: d(2026, 6, 5), value: 134 }, { date: d(2026, 6, 6), value: 131 },
      { date: d(2026, 6, 7), value: 132 }, { date: d(2026, 6, 8), value: 129 }, { date: d(2026, 6, 9), value: 130 },
      { date: d(2026, 6, 10), value: 128 },
    ],
    band: [110, 130], bandLabel: "the calm zone", annotation: null,
    provenance: "From your home cuff, synced this morning",
    explainReading: "These are your systolic readings this week — the steadiest they've been in a month, drifting down toward the calm zone.",
    explainNextStep: "Nothing to change. The evening walks and steady lisinopril are exactly the recipe behind a week like this.",
    explainAsk: "Want me to flag the next time a rough night shows up in these numbers?",
  },
  {
    id: "ldl", name: "LDL cholesterol", unit: "mg/dL",
    points: [{ date: d(2025, 3, 18), value: 131 }, { date: d(2025, 9, 22), value: 112 }, { date: d(2026, 3, 12), value: 96 }],
    band: [50, 100], bandLabel: "target with your history",
    annotation: { date: d(2025, 3, 18), label: "started atorvastatin" },
    provenance: "From your Mar 12 Piedmont lab",
    explainReading: "LDL is the cholesterol worth watching. You've come from 131 to 96 in a year — that's the statin earning its keep.",
    explainNextStep: "Keep the atorvastatin steady. The refill due this week is the only thing between you and another good number.",
    explainAsk: "Want me to get Thursday's refill ready at CVS Peachtree?",
  },
];

const marcusMeds: Medication[] = [
  {
    id: "metformin", name: "Metformin", dose: "1000 mg · twice daily", purposeLine: "steadies your blood sugar",
    scheduleLine: "with breakfast and dinner", supplyDaysRemaining: 12, pharmacy: "CVS Peachtree",
    guidance: ["Take with food — easier on your stomach", "Skip the dose if you're ever told to fast for a scan; we'll plan around it"],
    watchlist: ["Stomach upset in the first weeks (yours settled in 2019)", "B12 gets checked yearly — last was fine in March"],
    history: ["1000 mg twice daily — since Jun 2025 (Dr. Patterson, after the 9.1 A1c)", "500 mg twice daily — 2019 to 2025"],
    adherence30: [1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1],
  },
  {
    id: "lisinopril", name: "Lisinopril", dose: "10 mg · once daily", purposeLine: "protects your kidneys and lowers BP",
    scheduleLine: "with breakfast", supplyDaysRemaining: 23, pharmacy: "CVS Peachtree",
    guidance: ["Morning is fine — consistency beats timing", "Go easy on ibuprofen; it works against this one and your kidneys"],
    watchlist: ["A dry cough is the known quirk — mention it if it shows up", "Potassium gets watched on your kidney panels"],
    history: ["10 mg daily — since 2024 (kidney-protective dose)", "5 mg daily — 2017 to 2024"],
    adherence30: [1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1],
  },
  {
    id: "atorvastatin", name: "Atorvastatin", dose: "20 mg · once daily", purposeLine: "keeps cholesterol in check",
    scheduleLine: "in the evening", supplyDaysRemaining: 5, pharmacy: "CVS Peachtree",
    guidance: ["Evening works best for this one", "No grapefruit juice in quantity — odd but true"],
    watchlist: ["Muscle cramps are worth telling me about — we watch this closely with your kidneys", "Liver panel rides along with your regular labs"],
    history: ["20 mg daily — since Mar 2025 (LDL was 131)"],
    adherence30: [1,1,0,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1],
  },
];

const marcusInsights: Insight[] = [
  {
    id: uid("ins"), category: "Milestones", headline: "Your steadiest BP week in a month",
    body: "Seven mornings, every reading drifting down toward the calm zone. Weeks like this are what the evening walks and steady lisinopril were always for.",
    confidence: null, provenance: "From your home cuff · 7 readings this week", actionLabel: "See the trend",
    status: { t: "fresh" }, visual: { t: "chart", id: "bp" },
    sources: ["Home BP cuff via HealthKit (7 readings)", "Medication schedule (lisinopril, steady 30 days)"],
  },
  {
    id: uid("ins"), category: "Patterns", headline: "Cramps have clustered on late-statin days",
    body: "4 of the 5 times you logged leg cramps, the atorvastatin dose had drifted past 10pm. That's a pattern worth one question — not a conclusion.",
    confidence: "Based on 5 logs over 6 weeks — enough to notice, not enough to be sure.",
    provenance: "Your logs + dose timing · with your kidney function in mind", actionLabel: "Draft the question for Dr. Patterson",
    status: { t: "seen" }, visual: { t: "scene", seed: 7 },
    sources: ["Symptom logs: leg cramps (5 entries)", "Atorvastatin dose times (30 days)", "CKD-2 on your problem list"],
  },
  {
    id: uid("ins"), category: "Heads-ups", headline: "Atorvastatin runs out Thursday",
    body: "The refill is already ready at CVS Peachtree. One tap and it's waiting for you — or I can set up delivery so this stops being a thing you carry.",
    confidence: null, provenance: "Pharmacy dispense data · CVS Peachtree", actionLabel: "Make it ready",
    status: { t: "fresh" }, visual: { t: "tide" }, sources: ["Surescripts dispense record (May 14 fill, 30-day supply)"],
  },
  {
    id: uid("ins"), category: "Opportunities", headline: "A screening worth a few easy minutes",
    body: "You're 54. The USPSTF recommends colon cancer screening starting at 45, and there's nothing on your record yet. A take-home kit counts — no day off work required.",
    confidence: null, provenance: "USPSTF guideline · your record shows no prior screening", actionLabel: "See the easy options",
    status: { t: "seen" }, visual: { t: "scene", seed: 12 },
    sources: ["USPSTF colorectal screening recommendation (age 45–75)", "Your procedures history (no prior screening found)"],
  },
  {
    id: uid("ins"), category: "Patterns", headline: "Short nights show up in your next-morning readings",
    body: "On weeks with warehouse night shifts, your morning BP runs 6–8 points higher the day after. Your body keeps the receipts — gently.",
    confidence: "Seen in 3 of the last 4 shift weeks. We'll keep watching before calling it solid.",
    provenance: "Sleep via HealthKit + your home cuff", actionLabel: "Talk through shift weeks",
    status: { t: "acted", outcome: "You moved Tuesday walks to lunch — readings evened out by May 28." },
    visual: { t: "chart", id: "bp" },
    sources: ["Sleep duration via HealthKit (4 weeks)", "Home BP readings (4 weeks)", "Work rhythm you told me about in April"],
  },
];

const marcusJourneys: Journey[] = [
  {
    id: uid("jny"), title: "Evenings that move", why: "Fifteen minutes after dinner — for the BP, and for DeShawn seeing you do it.",
    habits: [{ id: uid("hab"), title: "15-minute walk after dinner", contextLine: "after the Braves game ends — or 7:30 on quiet nights",
      keptDates: range(14).map((i) => daysAgo(i)).filter((_, idx) => idx % 3 !== 0) }],
    gardenSeed: 42,
  },
  {
    id: uid("jny"), title: "Steady mornings", why: "Meds with breakfast, every day — boring on purpose. Boring is winning.",
    habits: [{ id: uid("hab"), title: "Metformin + lisinopril with breakfast", contextLine: "right after the first coffee",
      keptDates: range(20).map((i) => daysAgo(i)).filter((_, idx) => idx % 7 !== 6) }],
    gardenSeed: 7,
  },
];

const marcusPersona: Persona = {
  pathway: "metabolic", firstName: "Marcus",
  switcherLine: "Marcus · diabetes & blood pressure · the long game",
  conditions: [
    { id: uid("c"), name: "Type 2 diabetes", since: "2019", state: "actively managed", plainLine: "Your A1c has moved down five readings in a row. The walks and steady metformin are why.", glyph: "droplet", accent: "gold" },
    { id: uid("c"), name: "High blood pressure", since: "2017", state: "trending calmer", plainLine: "This week was your steadiest in a month — evenings are doing quiet work here.", glyph: "heart", accent: "warm" },
    { id: uid("c"), name: "Kidneys, stage 2", since: "2024", state: "holding steady", plainLine: "Caught early, protected since. Water on shifts, easy on ibuprofen — that's your part.", glyph: "leaf", accent: "life" },
  ],
  conditionChip: "Diabetes · BP · kidneys", heroImage: "condition_diabetes",
  phase: { kicker: "The long game", headline: "Year two of turning this around", detail: "No finish line here — just direction. And yours has been good for five readings straight.", progress: null },
  expectations: [
    { id: uid("e"), window: "Most days", title: "Boring is winning", detail: "Meds with breakfast, a walk after dinner. The unglamorous stuff is exactly what's moving your numbers.", accent: "life" },
    { id: uid("e"), window: "Night-shift weeks", title: "Numbers drift — that's the schedule, not you", detail: "Short nights show up in next-morning readings. We plan around shift weeks instead of fighting them.", accent: "sky" },
    { id: uid("e"), window: "Every ~3 months", title: "Lab day", detail: "A1c, kidney panel, cholesterol. I'll have the trends charted before you sit down with Dr. Patterson.", accent: "gold" },
  ],
  carePlan: {
    author: "Dr. Alicia Patterson", updated: "March 12, 2026",
    intro: "\u201CReal progress. Keep the walking.\u201D — the plan, in her words and yours:",
    goals: [
      { id: uid("g"), title: "A1c under 8 by fall", detail: "Steady metformin, evening movement, no crash diets.", progressLine: "On its way — 8.4 and falling", accent: "gold" },
      { id: uid("g"), title: "Home BP in the calm zone", detail: "Readings most mornings; lisinopril with breakfast.", progressLine: "Steadiest week in a month", accent: "warm" },
      { id: uid("g"), title: "Protect the kidneys", detail: "Hydrate on shifts, skip routine ibuprofen, kidney panel each visit.", progressLine: "Holding at stage 2 — stable", accent: "life" },
      { id: uid("g"), title: "Move after dinner", detail: "15 minutes, most evenings. The Braves schedule is a planning tool now.", progressLine: "11 of the last 14 evenings", accent: "sky" },
    ],
  },
  symptomKinds: [
    { name: "Leg cramps", glyph: "footprints", needsBodyMap: true }, { name: "Dizziness", glyph: "wind" },
    { name: "Headache", glyph: "brain", needsBodyMap: true }, { name: "Low energy", glyph: "battery-low" },
    { name: "Foot tingling", glyph: "footprints", needsBodyMap: true }, { name: "Stress", glyph: "tornado" },
    { name: "Poor sleep", glyph: "moon" }, { name: "Swelling", glyph: "droplets", needsBodyMap: true },
  ],
  labSeries: marcusLabs, medications: marcusMeds,
  careTeam: [
    { id: uid("t"), name: "Dr. Alicia Patterson", role: "Primary care", org: "Piedmont Internal Medicine · Privia" },
    { id: uid("t"), name: "Dr. Samuel Okafor", role: "Nephrology", org: "Emory Healthcare" },
    { id: uid("t"), name: "CVS Peachtree", role: "Pharmacy", org: "Peachtree St NE, Atlanta" },
  ],
  officePhone: "404-555-0142", officeName: "Dr. Patterson's office",
  appointments: [],
  journeys: marcusJourneys, insights: marcusInsights,
  storyEvents: [
    { id: uid("s"), kind: "milestone", date: d(2026, 6, 8), title: "Steadiest BP week in a month", detail: "Seven readings, all drifting toward the calm zone." },
    { id: uid("s"), kind: "companion", date: d(2026, 5, 26), title: "We caught the cramp pattern", detail: "Leg cramps clustered on late-statin days — 4 of 5 times. Worth one question to Dr. Patterson." },
    { id: uid("s"), kind: "milestone", date: d(2026, 5, 14), title: "90 days of steady metformin", detail: "Quietly, one of the strongest things you've done this year." },
    { id: uid("s"), kind: "result", date: d(2026, 3, 12), title: "A1c 8.4 — fifth drop in a row", detail: "From 9.4 a year ago. Dr. Patterson: \u201CReal progress.\u201D" },
    { id: uid("s"), kind: "visit", date: d(2026, 3, 12), title: "Visit — Dr. Patterson", detail: "Labs reviewed, plan unchanged, walking encouraged." },
    { id: uid("s"), kind: "result", date: d(2025, 12, 15), title: "A1c 8.7", detail: "The slide continued through the holidays — that's rare and real." },
    { id: uid("s"), kind: "milestone", date: d(2025, 9, 22), title: "LDL under 115 for the first time", detail: "Six months of atorvastatin showing up in the numbers." },
    { id: uid("s"), kind: "result", date: d(2025, 6, 10), title: "Metformin stepped up to 1000 mg", detail: "After the 9.1 — the turn this whole year built on." },
    { id: uid("s"), kind: "diagnosis", date: d(2024, 4, 9), title: "Kidneys flagged — stage 2", detail: "Caught early. Lisinopril moved to a protective dose." },
    { id: uid("s"), kind: "diagnosis", date: d(2019, 8, 14), title: "Type 2 diabetes", detail: "The diagnosis that started this story." },
    { id: uid("s"), kind: "diagnosis", date: d(2017, 5, 2), title: "Hypertension", detail: "Where the journey began." },
  ],
  currents: [
    { id: uid("cur"), format: "Glance", kicker: "For your kidneys", headline: "Why your kidneys love lisinopril", body: "It lowers the pressure inside the kidney's tiny filters — not just in your arm. That's why Dr. Patterson calls it protective, not just a BP pill.", sceneSeed: 3, imageName: "currents_kidney", aiGenerated: true, intent: "med-understanding · lisinopril adherence" },
    { id: uid("cur"), format: "Read", kicker: "The evening walk", headline: "Fifteen minutes that outwork an hour", body: "The walk after dinner does something the gym can't: it meets your blood sugar exactly when it peaks.\n\nMuscles pull glucose straight from the blood for about ninety minutes after you eat. A walk in that window is like opening a second drain — no willpower contest, no gear, no good weather required.\n\nFor blood pressure it's quieter still: the rhythm of unhurried walking nudges vessels to relax for hours afterward. Your steadiest BP weeks this spring have all been walking weeks.\n\nThe trick that makes it stick isn't discipline. It's placement. Not \u201Cwalk more\u201D — walk after dinner, when the game's over and the kitchen's closed. Let it be boring. Boring is what habits are made of.", sceneSeed: 9, imageName: "currents_walk", aiGenerated: true, intent: "journey-support · evening walks" },
    { id: uid("cur"), format: "Watch", kicker: "Your numbers, decoded", headline: "What an A1c of 8.4 actually means", body: "Ninety seconds on what the number measures, why direction beats position, and what \u201Cunder 8 by fall\u201D would take. Captioned.", sceneSeed: 5, imageName: "currents_a1c", aiGenerated: false, intent: "lab-understanding · A1c trend" },
    { id: uid("cur"), format: "Listen", kicker: "Two minutes, spoken", headline: "A father, a son, and a walk", body: "A short listen about what it means when your kid starts lacing up to come with you. Sometimes the health part is the smallest part.", sceneSeed: 14, imageName: "currents_father_son", aiGenerated: true, intent: "relational · walking journey" },
    { id: uid("cur"), format: "Glance", kicker: "Small swap", headline: "The salt that hides in Sunday", body: "One deli sandwich can carry more sodium than three home dinners. The swap isn't \u201Cno sandwich\u201D — it's half the meat, double the tomato, same sandwich.", sceneSeed: 21, imageName: "currents_salt", aiGenerated: true, intent: "kidney-smart eating" },
  ],
  moments: [
    { id: uid("m"), kind: "insight", title: "Steadiest week in a month", body: "Your BP readings this week are the calmest run since early May. Worth seeing.", actionLabel: "Show me", insightID: marcusInsights[0].id },
    { id: uid("m"), kind: "habit", title: "Your walk window is open", body: "Braves don't play tonight — the 15 minutes after dinner is all yours.", actionLabel: "I'm on it" },
    { id: uid("m"), kind: "task", title: "Atorvastatin — Thursday", body: "You'll run out next Thursday. The refill is ready at CVS Peachtree.", actionLabel: "Make it ready", medID: "atorvastatin" },
  ],
  statusQuiet: "All quiet. Exactly how we like it.", statusBusy: "A few things worth your time — no rush.",
  guideSeed: [
    { id: uid("gd"), kind: "Question", text: "Leg cramps cluster on late-statin days — worth a timing tweak?", addedFrom: "From the pattern we caught · May 26", resolved: false },
    { id: uid("gd"), kind: "Observation", text: "Steadiest BP week in a month — evening walks are landing.", addedFrom: "From your home cuff · this week", resolved: false },
  ],
};

// ============================================================
// Elena · oncology
// ============================================================
const elenaPersona: Persona = {
  pathway: "oncology", firstName: "Elena", switcherLine: "Elena · breast cancer · chemo cycle 3 of 6",
  conditions: [
    { id: uid("c"), name: "Breast cancer", since: "January 2026", state: "in treatment — responding", plainLine: "Cycle 3 of 6. Dr. Rivera called the last scan \u201Cexactly what we hoped to see.\u201D", glyph: "sparkles", accent: "rose" },
    { id: uid("c"), name: "Chemotherapy course", since: "February 2026", state: "AC-T · cycle 3 of 6", plainLine: "Halfway through the harder half. Your body is keeping remarkable rhythm with it.", glyph: "calendar", accent: "sky" },
  ],
  conditionChip: "Breast cancer · cycle 3 of 6", heroImage: "condition_chemo",
  phase: { kicker: "Chemotherapy · cycle 3 of 6", headline: "Day 6 — the turn toward better days", detail: "The queasy window is behind you. Counts dip around day 7–10, so it's gentle-with-yourself week: small crowds, good handwashing, naps without guilt.", progress: 3 / 6 },
  expectations: [
    { id: uid("e"), window: "Days 1–3", title: "The queasy window", detail: "Nausea peaks here. Ondansetron works best on schedule, not heroically after the fact. Cold food smells less.", accent: "sky" },
    { id: uid("e"), window: "Days 4–7", title: "Tired, but turning", detail: "Heavy-limbed days. Rest is treatment too — and a 10-minute walk on the better days genuinely helps the fatigue.", accent: "gold" },
    { id: uid("e"), window: "Days 7–10", title: "Counts at their lowest", detail: "Your immune guard is briefly down. A fever of 100.4\u00B0F or higher is a call-the-team-now moment — any hour, no hesitating.", accent: "warm" },
    { id: uid("e"), window: "Days 10–21", title: "The good window", detail: "Energy comes back. This is the window for the things that make you feel like you — plan them here.", accent: "life" },
  ],
  carePlan: {
    author: "Dr. Maya Rivera", updated: "June 4, 2026", intro: "The plan for cycles 3 and 4 — protection first, life where it fits:",
    goals: [
      { id: uid("g"), title: "Stay ahead of nausea", detail: "Ondansetron on schedule days 1–3, not as a rescue.", progressLine: "Cycle 3 was your smoothest yet", accent: "sky" },
      { id: uid("g"), title: "Fever rule — 100.4\u00B0F means call", detail: "Any time, day or night. The on-call line always answers.", progressLine: null, accent: "warm" },
      { id: uid("g"), title: "Hydration through infusion week", detail: "Eight glasses on infusion days; it eases almost everything.", progressLine: "You kept it 5 of 7 days last cycle", accent: "gold" },
      { id: uid("g"), title: "Move on the good days", detail: "Short walks when energy allows — fatigue's best medicine, oddly.", progressLine: "Three gentle walks last window", accent: "life" },
    ],
  },
  symptomKinds: [
    { name: "Nausea", glyph: "wind" }, { name: "Fatigue", glyph: "battery-low" }, { name: "Fever or chills", glyph: "thermometer" },
    { name: "Mouth sores", glyph: "circle" }, { name: "Tingling hands/feet", glyph: "hand", needsBodyMap: true },
    { name: "Appetite", glyph: "utensils" }, { name: "Worry", glyph: "cloud" }, { name: "Poor sleep", glyph: "moon" },
  ],
  labSeries: [
    {
      id: "anc", name: "Immune guard (ANC)", unit: "k/\u00B5L",
      points: [{ date: d(2026, 4, 20), value: 1.8 }, { date: d(2026, 5, 4), value: 1.1 }, { date: d(2026, 5, 18), value: 1.9 }, { date: d(2026, 6, 1), value: 1.2 }, { date: d(2026, 6, 8), value: 1.7 }],
      band: [1.5, 8.0], bandLabel: "comfortable range", annotation: { date: d(2026, 6, 1), label: "cycle 3 infusion" },
      provenance: "From your Jun 8 Northside lab",
      explainReading: "ANC counts the white cells that fight infection. Yours dips after each infusion and recovers before the next — exactly the rhythm your team plans around.",
      explainNextStep: "During the dip (days 7–10), it's small-crowds-and-handwashing week. Recovery has been reliable every cycle.",
      explainAsk: "Want a gentle heads-up when you enter the low-count window each cycle?",
    },
    {
      id: "weight", name: "Weight", unit: "lb",
      points: [{ date: d(2026, 4, 6), value: 148 }, { date: d(2026, 4, 27), value: 146 }, { date: d(2026, 5, 18), value: 145 }, { date: d(2026, 6, 8), value: 145 }],
      band: [140, 155], bandLabel: "your steady zone", annotation: null, provenance: "From your infusion-day check-ins",
      explainReading: "Holding steady through chemo is genuinely hard to do — and you're doing it. Three pounds over two months is the gentle kind of change.",
      explainNextStep: "Keep the small frequent meals. If a week drops more than 2–3 pounds, that's worth telling the team — food is part of treatment.",
      explainAsk: "Want me to put weight on your visit-prep for Dr. Rivera?",
    },
  ],
  medications: [
    { id: "ondansetron", name: "Ondansetron", dose: "8 mg · as scheduled", purposeLine: "keeps nausea ahead of you, not behind", scheduleLine: "days 1–3 after infusion, every 8 hours", supplyDaysRemaining: 14, pharmacy: "Northside Pharmacy", guidance: ["Works best on schedule, not as a rescue after nausea starts", "Constipation is its known quirk — water and movement help"], watchlist: ["If nausea breaks through on schedule, the team has stronger options — say so", "Headache is common and mild"], history: ["8 mg scheduled — since cycle 1 (February 2026)"], adherence30: [1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1] },
    { id: "dexamethasone", name: "Dexamethasone", dose: "4 mg · infusion days", purposeLine: "softens the infusion's edges", scheduleLine: "morning of infusion + 2 days after, with food", supplyDaysRemaining: 20, pharmacy: "Northside Pharmacy", guidance: ["Take it with breakfast — it can make sleep lively if taken late", "Some people feel wired then dip — that's the medicine, not you"], watchlist: ["Mood swings on dexamethasone days are real and temporary", "Mention persistent hiccups — there's a fix"], history: ["4 mg around infusions — since cycle 1"], adherence30: [1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1] },
  ],
  careTeam: [
    { id: uid("t"), name: "Dr. Maya Rivera", role: "Oncology", org: "Northside Cancer Institute" },
    { id: uid("t"), name: "Nia Coleman, RN", role: "Infusion nurse navigator", org: "Northside Cancer Institute" },
    { id: uid("t"), name: "Northside Pharmacy", role: "Pharmacy", org: "Peachtree Dunwoody Rd" },
  ],
  officePhone: "404-555-0188", officeName: "Dr. Rivera's team", appointments: [],
  journeys: [
    { id: uid("jny"), title: "Good-day movement", why: "Ten gentle minutes on the days that allow it — fatigue's strangest, best medicine.", habits: [{ id: uid("hab"), title: "10-minute walk on good days", contextLine: "days 10–21 of each cycle — your window", keptDates: range(10).map((i) => daysAgo(i * 2)) }], gardenSeed: 11 },
    { id: uid("jny"), title: "Infusion week, watered", why: "Eight glasses on infusion days. It eases the nausea, the fatigue, almost everything.", habits: [{ id: uid("hab"), title: "Water bottle finished twice", contextLine: "infusion day + 3 days after", keptDates: range(8).map((i) => daysAgo(i * 3)) }], gardenSeed: 23 },
  ],
  insights: [
    { id: uid("ins"), category: "Patterns", headline: "Your nausea peaks on day 2 — and your schedule can meet it", body: "Across three cycles, the hardest hours land the evening of day 2. Taking ondansetron on schedule that morning — not waiting — has made each cycle smoother than the last.", confidence: "Based on 3 cycles of logs — a steady rhythm, not a guess.", provenance: "Your logs · infusion dates from Northside", actionLabel: "Set the day-2 reminder", status: { t: "fresh" }, visual: { t: "scene", seed: 31 }, sources: ["Symptom logs: nausea (9 entries)", "Infusion schedule (3 cycles)", "Ondansetron dose times"] },
    { id: uid("ins"), category: "Milestones", headline: "Halfway. Say it out loud.", body: "Three cycles done, three to go. Your counts have recovered on time every single cycle, and the last scan read the way everyone hoped. This is what getting through looks like.", confidence: null, provenance: "Northside labs · 3 cycles", actionLabel: "See the journey so far", status: { t: "fresh" }, visual: { t: "scene", seed: 8 }, sources: ["ANC recovery curve (3 cycles)", "Dr. Rivera's May scan note"] },
  ],
  storyEvents: [
    { id: uid("s"), kind: "milestone", date: d(2026, 6, 8), title: "Counts recovered — right on time", detail: "Third cycle in a row. Your body keeps its promises." },
    { id: uid("s"), kind: "visit", date: d(2026, 6, 1), title: "Cycle 3 infusion", detail: "Smoothest one yet — the scheduled anti-nausea plan worked." },
    { id: uid("s"), kind: "result", date: d(2026, 5, 12), title: "Scan: \u201Cexactly what we hoped\u201D", detail: "Dr. Rivera's words. The treatment is doing its job." },
    { id: uid("s"), kind: "milestone", date: d(2026, 4, 20), title: "Cycle 2 — you found the rhythm", detail: "Queasy window, tired turn, good days. Named, mapped, survivable." },
    { id: uid("s"), kind: "visit", date: d(2026, 2, 16), title: "Cycle 1 — the hardest first", detail: "You walked in scared and walked out started. That counts double." },
    { id: uid("s"), kind: "diagnosis", date: d(2026, 1, 22), title: "Diagnosis", detail: "The day the story changed. Not the day it ended — the day this chapter began." },
  ],
  currents: [
    { id: uid("cur"), format: "Glance", kicker: "For the queasy window", headline: "Cold plates, quiet smells", body: "Nausea hates cold food — less aroma, less trouble. Chilled fruit, yogurt, rice at room temperature. The microwave is not your friend on days 1–3.", sceneSeed: 4, imageName: "currents_salt", aiGenerated: true, intent: "cycle-support · nausea management" },
    { id: uid("cur"), format: "Read", kicker: "The good window", headline: "Days 10 to 21 belong to you", body: "Every cycle has a window where the fog lifts and energy returns. Yours has opened on day 10, reliably, three cycles running.\n\nThe trick is planning for it. Not the laundry — the living. The friend you keep postponing, the garden, the drive with the windows down.\n\nFatigue research says the strangest thing: gentle movement during the good window stretches it. Ten minutes of walking, most good days, and the next dip tends to land softer.", sceneSeed: 9, imageName: "currents_walk", aiGenerated: true, intent: "journey-support · good-day movement" },
    { id: uid("cur"), format: "Listen", kicker: "Two minutes, spoken", headline: "What halfway feels like", body: "A short listen about the middle of hard things — when the start is far behind and the end is not yet near, and you keep going anyway.", sceneSeed: 14, imageName: "currents_father_son", aiGenerated: true, intent: "relational · halfway milestone" },
  ],
  moments: [
    { id: uid("m"), kind: "checkIn", title: "Day 6 — how's the turn?", body: "By tonight the heaviness usually starts lifting. Tell me where you are and I'll shape the week around it.", actionLabel: "Check in" },
    { id: uid("m"), kind: "task", title: "Low-count window opens tomorrow", body: "Days 7–10: small crowds, good handwashing, and the fever rule on the fridge. I'll keep watch with you.", actionLabel: "What to watch" },
    { id: uid("m"), kind: "habit", title: "Water counts double this week", body: "Infusion week hydration is still working through your system — one more good day of it.", actionLabel: "Done today" },
  ],
  statusQuiet: "A quiet day in cycle 3. Take it.", statusBusy: "Cycle 3, day 6 — here's what matters today.",
  guideSeed: [
    { id: uid("gd"), kind: "Question", text: "Tingling in my fingertips since cycle 2 — is this the neuropathy to watch?", addedFrom: "From your logs · May 30", resolved: false },
    { id: uid("gd"), kind: "Question", text: "Can we plan cycle 4's anti-nausea schedule the same as cycle 3?", addedFrom: "Added after cycle 3 went smoothly", resolved: false },
    { id: uid("gd"), kind: "Observation", text: "Smoothest infusion week yet — scheduled ondansetron made the difference.", addedFrom: "From your cycle 3 logs", resolved: false },
  ],
};

// ============================================================
// Sam · procedure
// ============================================================
const samPersona: Persona = {
  pathway: "procedure", firstName: "Sam", switcherLine: "Sam · knee replacement · 12 days out",
  conditions: [{ id: uid("c"), name: "Right knee osteoarthritis", since: "2021", state: "surgery scheduled · June 23", plainLine: "Replacement day is June 23. The next twelve days are about walking in strong.", glyph: "activity", accent: "sky" }],
  conditionChip: "Knee replacement · June 23", heroImage: "condition_procedure",
  phase: { kicker: "Procedure ahead · 12 days", headline: "Getting you strong for June 23", detail: "Prehab now pays off twice after — people who walk in stronger walk out sooner. The countdown checklist is short and all of it matters.", progress: 0.6 },
  expectations: [
    { id: uid("e"), window: "Now \u2192 day \u22127", title: "Prehab window", detail: "Quad sets and short walks daily. Stop ibuprofen and similar by June 16 — Dr. Chen's hard rule.", accent: "life" },
    { id: uid("e"), window: "The night before", title: "Quiet logistics", detail: "Nothing to eat after midnight. Bag packed, ride confirmed, the recovery corner at home set up — ice, pillows, chargers.", accent: "gold" },
    { id: uid("e"), window: "Day of", title: "It's a half-day, mostly waiting", detail: "Surgery itself runs about two hours. Most people are standing — carefully, triumphantly — the same day.", accent: "sky" },
    { id: uid("e"), window: "Weeks 1–2 after", title: "Swelling is normal; clots are the watch-item", detail: "Ice and elevate daily. Calf pain, one-sided swelling, or shortness of breath is a call-now moment, not a wait-and-see.", accent: "warm" },
    { id: uid("e"), window: "Weeks 2–6", title: "PT is the whole game", detail: "The new knee becomes yours in physical therapy. Bend by bend. It's work, and it works.", accent: "rose" },
  ],
  carePlan: {
    author: "Dr. Daniel Chen", updated: "June 2, 2026", intro: "The countdown plan — short list, every item load-bearing:",
    goals: [
      { id: uid("g"), title: "Prehab daily", detail: "Quad sets \u00D720 and a short walk, every day until surgery.", progressLine: "9 of the last 10 days — strong", accent: "life" },
      { id: uid("g"), title: "Stop NSAIDs by June 16", detail: "Ibuprofen, naproxen and friends — they thin blood around surgery.", progressLine: "Reminder set for June 15", accent: "warm" },
      { id: uid("g"), title: "Home, ready for after", detail: "Clear the walkways, ice packs in the freezer, raised seat installed.", progressLine: "2 of 3 done", accent: "gold" },
      { id: uid("g"), title: "Ride + first PT booked", detail: "Someone to drive you home; PT starts within a week after.", progressLine: "Ride confirmed — PT pending", accent: "sky" },
    ],
  },
  symptomKinds: [
    { name: "Knee pain", glyph: "zap", needsBodyMap: true }, { name: "Swelling", glyph: "droplets", needsBodyMap: true },
    { name: "Stiffness", glyph: "turtle", needsBodyMap: true }, { name: "Poor sleep", glyph: "moon" },
    { name: "Worry", glyph: "cloud" }, { name: "Low energy", glyph: "battery-low" },
  ],
  labSeries: [
    { id: "pain", name: "Knee pain, evenings", unit: "/10", points: [{ date: d(2026, 6, 4), value: 6 }, { date: d(2026, 6, 5), value: 5 }, { date: d(2026, 6, 6), value: 6 }, { date: d(2026, 6, 7), value: 4 }, { date: d(2026, 6, 8), value: 5 }, { date: d(2026, 6, 9), value: 4 }, { date: d(2026, 6, 10), value: 4 }], band: [0, 3], bandLabel: "where the new knee will live", annotation: null, provenance: "From your evening check-ins", explainReading: "Evening pain has drifted from 6s to 4s since prehab started. Stronger muscles are already splinting the joint — a preview of what PT does after.", explainNextStep: "Keep the quad sets daily. Ice after walks if it grumbles.", explainAsk: "Want this trend on Dr. Chen's pre-op summary?" },
  ],
  medications: [
    { id: "acetaminophen", name: "Acetaminophen", dose: "500 mg · as needed", purposeLine: "the pre-surgery-safe pain option", scheduleLine: "up to 3g daily — your green-light option", supplyDaysRemaining: 30, pharmacy: "Walgreens Midtown", guidance: ["This one is surgery-safe right up to the night before", "Cap is 3,000 mg across the whole day — track doses, not pain"], watchlist: ["Ibuprofen and naproxen stop June 16 — they're the ones that thin blood", "Tell the team about any supplements; some surprise people"], history: ["As-needed since May, replacing routine ibuprofen"], adherence30: [1,0,1,1,0,1,1,1,0,1,0,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1,1,0,1,1] },
  ],
  careTeam: [
    { id: uid("t"), name: "Dr. Daniel Chen", role: "Orthopedic surgery", org: "Midtown Orthopedics" },
    { id: uid("t"), name: "Priya Nair, PT", role: "Physical therapy", org: "Midtown Rehab — starts post-op" },
    { id: uid("t"), name: "Walgreens Midtown", role: "Pharmacy", org: "Peachtree St" },
  ],
  officePhone: "404-555-0167", officeName: "Dr. Chen's office", appointments: [],
  journeys: [
    { id: uid("jny"), title: "Stronger going in", why: "Every quad set now is a smoother week one after. Walk in strong, walk out sooner.", habits: [{ id: uid("hab"), title: "Quad sets \u00D720 + short walk", contextLine: "morning coffee first, then the floor mat", keptDates: range(10).filter((i) => i !== 4).map((i) => daysAgo(i)) }], gardenSeed: 33 },
    { id: uid("jny"), title: "Home, ready for after", why: "Future-you arrives on crutches. Present-you is making the house kind to them.", habits: [{ id: uid("hab"), title: "One readiness item a day", contextLine: "ice packs · walkways · shower rail · chargers by the chair", keptDates: range(6).map((i) => daysAgo(i * 2)) }], gardenSeed: 17 },
  ],
  insights: [
    { id: uid("ins"), category: "Patterns", headline: "Pain runs two points lower on prehab days", body: "Evenings after quad-set mornings average 4/10; skipped days run 6/10. Your muscles are already doing part of the new knee's job.", confidence: "Based on 10 days of evening check-ins — consistent so far.", provenance: "Your evening logs + habit record", actionLabel: "See the trend", status: { t: "fresh" }, visual: { t: "chart", id: "pain" }, sources: ["Evening pain logs (10 days)", "Prehab habit record"] },
    { id: uid("ins"), category: "Heads-ups", headline: "NSAIDs stop in 5 days", body: "June 16 is the last day for ibuprofen and naproxen — they thin blood around surgery. Acetaminophen stays green-lit the whole way through.", confidence: null, provenance: "Dr. Chen's pre-op instructions · June 2", actionLabel: "Set the reminder", status: { t: "fresh" }, visual: { t: "scene", seed: 19 }, sources: ["Pre-op instruction sheet (Jun 2)", "Your med list"] },
  ],
  storyEvents: [
    { id: uid("s"), kind: "milestone", date: d(2026, 6, 9), title: "Ten days of prehab", detail: "Nine kept. Evening pain already running lower." },
    { id: uid("s"), kind: "visit", date: d(2026, 6, 2), title: "Surgery scheduled — June 23", detail: "Dr. Chen: \u201CYou're a strong candidate. Let's get you moving again.\u201D" },
    { id: uid("s"), kind: "result", date: d(2026, 5, 14), title: "MRI confirmed it", detail: "Bone-on-bone in the right knee. The answer to three years of grinding." },
    { id: uid("s"), kind: "diagnosis", date: d(2021, 9, 8), title: "Osteoarthritis, right knee", detail: "Where the long road to June 23 started." },
  ],
  currents: [
    { id: uid("cur"), format: "Glance", kicker: "Countdown", headline: "What the night before looks like", body: "Nothing to eat after midnight. Bag by the door: ID, insurance card, loose shorts, slip-on shoes. Phone charged, ride confirmed. Then — genuinely — a movie and bed.", sceneSeed: 6, imageName: "condition_procedure", aiGenerated: true, intent: "procedure-prep · night-before" },
    { id: uid("cur"), format: "Read", kicker: "Recovery, honestly", headline: "Week one with a new knee", body: "The first week is icing, elevating, and short shuffles that feel like victories — because they are.\n\nSwelling is normal and dramatic; bruising travels to strange places. What matters is the rhythm: ice after every walk, foot above heart while resting, the blood-thinner exactly on schedule.\n\nThe watch-items are few and specific: calf pain in one leg, swelling that's one-sided, fever, or shortness of breath. Those are call-now moments — everything else is the ordinary weather of healing.", sceneSeed: 13, imageName: "currents_a1c", aiGenerated: true, intent: "procedure-prep · expectation-setting" },
    { id: uid("cur"), format: "Listen", kicker: "Two minutes, spoken", headline: "People who got their walks back", body: "Three short voices, one year out from the same surgery — what they'd tell the person twelve days before.", sceneSeed: 21, imageName: "currents_walk", aiGenerated: true, intent: "relational · pre-surgery confidence" },
  ],
  moments: [
    { id: uid("m"), kind: "habit", title: "Quad sets — day 11 of the streakless streak", body: "Coffee, then the mat. Each one is a smoother week one after the 23rd.", actionLabel: "Done" },
    { id: uid("m"), kind: "task", title: "Pre-op visit Tuesday", body: "Dr. Chen, June 17. Your prep brief is ready — the NSAID question is already on it.", actionLabel: "See the brief" },
    { id: uid("m"), kind: "insight", title: "Prehab is already paying", body: "Evening pain runs two points lower on exercise days. Proof the plan works.", actionLabel: "Show me" },
  ],
  statusQuiet: "Twelve days out, right on plan.", statusBusy: "Twelve days to go — today's part is small and clear.",
  guideSeed: [
    { id: uid("gd"), kind: "Question", text: "Which blood-thinner will I be on after, and for how long?", addedFrom: "Added while reading about week one", resolved: false },
    { id: uid("gd"), kind: "Question", text: "When exactly do I stop the ibuprofen — morning or night of June 16?", addedFrom: "From the NSAID heads-up · Jun 11", resolved: false },
    { id: uid("gd"), kind: "Observation", text: "Evening pain down to 4/10 on prehab days — the exercises are working.", addedFrom: "From your evening check-ins", resolved: false },
  ],
};

// ============================================================
// Rosa · cardiometabolic (T2D + heart failure + CKD risk)
// ============================================================
const rosaPersona: Persona = {
  pathway: "cardiometabolic", firstName: "Rosa",
  switcherLine: "Rosa · diabetes & heart · protecting the kidneys",
  conditions: [
    { id: uid("c"), name: "Type 2 diabetes", since: "2012", state: "long-managed", plainLine: "Fourteen years in. Empagliflozin now does double duty — steadying your sugar and shielding your heart and kidneys at once.", glyph: "droplet", accent: "gold" },
    { id: uid("c"), name: "Heart failure, preserved EF", since: "2024", state: "stable on treatment", plainLine: "Your heart pumps fine but stiffens, so fluid is the thing we watch. Your daily weigh-in is the early-warning system.", glyph: "heart", accent: "rose" },
    { id: uid("c"), name: "Kidney risk — caught early", since: "flagged 2026", state: "watched closely", plainLine: "Rumi's risk model flagged your kidneys as the next thing to protect — not a diagnosis, a head start. The SGLT2 and the low-sodium plan are the protection.", glyph: "leaf", accent: "life" },
  ],
  conditionChip: "Diabetes · heart · kidney watch", heroImage: "condition_diabetes",
  phase: { kicker: "Heart, sugar & kidneys", headline: "Protecting all three, together", detail: "These three pull on the same strings — so we treat them as one. The wins are quiet: a steady weight, an easy breath, numbers that hold.", progress: null },
  expectations: [
    { id: uid("e"), window: "Every morning", title: "Weigh-in is the whole game", detail: "Same time, after the bathroom, before breakfast. A 2–3 lb jump overnight is fluid — the heart's first whisper, and the easiest thing to catch early.", accent: "rose" },
    { id: uid("e"), window: "Most days", title: "Low-sodium, kidney-gentle", detail: "Salt holds water, and water strains the heart and kidneys both. The swaps are small; the payoff shows up on the scale and the cuff.", accent: "life" },
    { id: uid("e"), window: "Every ~3 months", title: "The three-panel check", detail: "A1c, kidney function, and a heart check. I'll have the trends charted for Dr. Shah, Dr. Reyes and Dr. Okafor before each one.", accent: "gold" },
    { id: uid("e"), window: "Any time", title: "Breath is a call, not a wait", detail: "New shortness of breath, a fluid jump, or swelling that climbs is a same-day call to the heart team — never a wait-and-see.", accent: "warm" },
  ],
  carePlan: {
    author: "Dr. Anita Shah", updated: "May 28, 2026",
    intro: "\u201CThree conditions, one plan — and you’re steady. Keep the weigh-ins.\u201D — the plan, reconciled across your team:",
    goals: [
      { id: uid("g"), title: "Catch fluid early", detail: "Weigh in daily; call if you're up 3 lb overnight or 5 in a week.", progressLine: "Steady within a pound for two weeks", accent: "rose" },
      { id: uid("g"), title: "Protect the kidneys", detail: "Empagliflozin daily, low sodium, and an eye on eGFR each panel.", progressLine: "eGFR holding — the plan's working", accent: "life" },
      { id: uid("g"), title: "A1c in the steady zone", detail: "Metformin and the SGLT2; no crash diets, no skipped meals.", progressLine: "7.1 and holding", accent: "gold" },
      { id: uid("g"), title: "Gentle daily movement", detail: "Short walks on good-breath days — kind to the heart, never past it.", progressLine: "9 of the last 14 days", accent: "sky" },
    ],
  },
  symptomKinds: [
    { name: "Shortness of breath", glyph: "wind" }, { name: "Swelling", glyph: "droplets", needsBodyMap: true },
    { name: "Weight jump", glyph: "activity" }, { name: "Fatigue", glyph: "battery-low" },
    { name: "Dizziness", glyph: "tornado" }, { name: "Chest tightness", glyph: "heart", needsBodyMap: true },
    { name: "Foot tingling", glyph: "footprints", needsBodyMap: true }, { name: "Poor sleep", glyph: "moon" },
  ],
  labSeries: [
    { id: "a1c", name: "A1c", unit: "%", points: [{ date: d(2025, 6, 14), value: 7.6 }, { date: d(2025, 9, 20), value: 7.4 }, { date: d(2025, 12, 12), value: 7.2 }, { date: d(2026, 3, 14), value: 7.1 }], band: [4.5, 7.0], bandLabel: "where your team wants this", annotation: { date: d(2025, 9, 20), label: "added empagliflozin" }, provenance: "From your Mar 14 Piedmont lab", explainReading: "A1c is your three-month sugar average. 7.1 is close to target and steady — and the medicine holding it there is also the one guarding your heart and kidneys.", explainNextStep: "Nothing to change. The empagliflozin earns its keep three ways at once.", explainAsk: "Want this on your visit-prep for Dr. Shah?" },
    { id: "egfr", name: "eGFR", unit: "mL/min", points: [{ date: d(2025, 6, 14), value: 72 }, { date: d(2025, 12, 12), value: 67 }, { date: d(2026, 3, 14), value: 66 }], band: [60, 90], bandLabel: "early-strain watch zone", annotation: { date: d(2025, 12, 12), label: "risk model flagged here" }, provenance: "From your Mar 14 Emory lab", explainReading: "eGFR is how well your kidneys filter. 66 is mild and now holding — the dip last winter is exactly what the risk model caught early, and what the SGLT2 is protecting against.", explainNextStep: "Stay the course: empagliflozin daily, low sodium, easy on ibuprofen. Dr. Okafor watches this each panel.", explainAsk: "Want a heads-up before each kidney panel?" },
    { id: "weight", name: "Daily weight", unit: "lb", points: [{ date: d(2026, 6, 5), value: 171 }, { date: d(2026, 6, 6), value: 170 }, { date: d(2026, 6, 7), value: 171 }, { date: d(2026, 6, 8), value: 173 }, { date: d(2026, 6, 9), value: 171 }, { date: d(2026, 6, 10), value: 170 }, { date: d(2026, 6, 11), value: 171 }], band: [168, 172], bandLabel: "your dry weight", annotation: { date: d(2026, 6, 8), label: "salty dinner — cleared in a day" }, provenance: "From your morning scale, synced", explainReading: "This is your fluid early-warning. The little bump on the 8th was a salty meal — it cleared by morning, which is exactly the all-clear pattern we want.", explainNextStep: "Keep the same-time weigh-in. A jump that doesn't clear in a day is the one to tell me about.", explainAsk: "Want me to flag the next time the scale climbs and stays?" },
    { id: "bp", name: "Home blood pressure", unit: "mmHg", points: [{ date: d(2026, 6, 5), value: 132 }, { date: d(2026, 6, 7), value: 128 }, { date: d(2026, 6, 9), value: 126 }, { date: d(2026, 6, 11), value: 124 }], band: [110, 130], bandLabel: "the calm zone", annotation: null, provenance: "From your home cuff", explainReading: "Your systolic readings, drifting gently into the calm zone — kind to a stiff heart and to the kidneys both.", explainNextStep: "The lisinopril and the low-sodium plan are doing this. Nothing to change.", explainAsk: "Want the cuff readings on Dr. Reyes's cardiology summary?" },
  ],
  medications: [
    { id: "empagliflozin", name: "Empagliflozin", dose: "10 mg · once daily", purposeLine: "protects heart and kidneys while steadying sugar", scheduleLine: "in the morning, with or without food", supplyDaysRemaining: 6, pharmacy: "CVS Peachtree", guidance: ["The one medicine doing three jobs — the cornerstone of your plan", "Stay hydrated; it works by passing a little sugar through your urine"], watchlist: ["Pause it during a stomach bug with poor intake — tell me and I'll flag the team", "Mention any yeast or urinary irritation; it's manageable"], history: ["10 mg daily — since Sep 2025 (added for heart + kidney protection)"], adherence30: [1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1] },
    { id: "metformin", name: "Metformin", dose: "1000 mg · twice daily", purposeLine: "steadies your blood sugar", scheduleLine: "with breakfast and dinner", supplyDaysRemaining: 19, pharmacy: "CVS Peachtree", guidance: ["Take with food — easier on your stomach", "Held automatically before any scan with contrast; we'll plan it"], watchlist: ["B12 gets checked yearly", "Stomach upset settled years ago for you"], history: ["1000 mg twice daily — since 2016", "500 mg twice daily — 2012 to 2016"], adherence30: [1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1] },
    { id: "lisinopril", name: "Lisinopril", dose: "20 mg · once daily", purposeLine: "eases the heart's load and protects the kidneys", scheduleLine: "with breakfast", supplyDaysRemaining: 24, pharmacy: "CVS Peachtree", guidance: ["Morning is fine — consistency beats timing", "Go easy on ibuprofen; it works against this and your kidneys"], watchlist: ["A dry cough is the known quirk — mention it if it shows", "Potassium gets watched on your kidney panels"], history: ["20 mg daily — since 2024 (heart failure dose)", "10 mg daily — 2018 to 2024"], adherence30: [1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1] },
    { id: "furosemide", name: "Furosemide", dose: "20 mg · as directed", purposeLine: "sheds extra fluid before it strains the heart", scheduleLine: "mornings, or as Dr. Reyes adjusts for your weight", supplyDaysRemaining: 28, pharmacy: "CVS Peachtree", guidance: ["Take it early — it'll keep you close to a bathroom for a few hours", "Your weigh-in tells us whether the dose is right"], watchlist: ["Strong dizziness or cramping can mean it's pulled a little too much — tell me", "Dr. Reyes may flex the dose up on heavy-fluid days"], history: ["20 mg, weight-guided — since 2024"], adherence30: [1,1,0,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0] },
  ],
  careTeam: [
    { id: uid("t"), name: "Dr. Anita Shah", role: "Primary care", org: "Piedmont Internal Medicine · Privia" },
    { id: uid("t"), name: "Dr. Lena Reyes", role: "Cardiology", org: "Emory Heart & Vascular" },
    { id: uid("t"), name: "Dr. Samuel Okafor", role: "Nephrology", org: "Emory Healthcare" },
    { id: uid("t"), name: "CVS Peachtree", role: "Pharmacy", org: "Peachtree St NE, Atlanta" },
  ],
  officePhone: "404-555-0173", officeName: "Dr. Shah's office", appointments: [],
  journeys: [
    { id: uid("jny"), title: "The morning weigh-in", why: "Same time, every day. It's the one habit that catches fluid before it ever catches you.", habits: [{ id: uid("hab"), title: "Step on the scale, log the number", contextLine: "after the bathroom, before coffee", keptDates: range(14).filter((i) => i !== 6).map((i) => daysAgo(i)) }], gardenSeed: 28 },
    { id: uid("jny"), title: "Good-breath movement", why: "Short, kind walks on the days your chest feels open — the heart likes them, and so does your sugar.", habits: [{ id: uid("hab"), title: "A gentle 10-minute walk", contextLine: "when the breath feels easy — never forced", keptDates: range(12).filter((i) => i % 3 !== 0).map((i) => daysAgo(i)) }], gardenSeed: 44 },
  ],
  insights: [
    { id: uid("ins"), category: "Heads-ups", headline: "Your kidneys are the next thing to protect — and we're early", body: "The risk model watched your sugar, pressure and that winter eGFR dip together and flagged kidneys as the one to guard now. Good news: the empagliflozin you already take is the protection. This is a head start, not a diagnosis.", confidence: "A population-level signal from your own trends — not a prediction about a date or outcome.", provenance: "Rumi risk model · your Emory + Piedmont labs", actionLabel: "See what protects them", status: { t: "fresh" }, visual: { t: "chart", id: "egfr" }, sources: ["eGFR trend (3 panels)", "A1c + home BP", "CKD risk factors on your record"] },
    { id: uid("ins"), category: "Patterns", headline: "Salty dinners show up on tomorrow's scale", body: "Three times now, a higher-sodium dinner has nudged your morning weight up a pound or two — then cleared by the next day. Your body keeps the receipts, gently, and the pattern is a useful one to know.", confidence: "Seen 3 of the last 4 salty meals — enough to notice.", provenance: "Your meal logs + morning weights", actionLabel: "See the low-sodium swaps", status: { t: "fresh" }, visual: { t: "chart", id: "weight" }, sources: ["Daily weight (14 days)", "Meal logs with sodium notes"] },
    { id: uid("ins"), category: "Milestones", headline: "Two steady weeks — heart and sugar both", body: "Fourteen days within a pound, A1c holding at 7.1, blood pressure drifting calm. With three conditions in the room, a stretch this quiet is the whole goal. Say it out loud.", confidence: null, provenance: "Your scale, cuff and last lab", actionLabel: "See the journey", status: { t: "fresh" }, visual: { t: "scene", seed: 22 }, sources: ["Daily weight (14 days)", "Home BP (this week)", "A1c (Mar 14)"] },
  ],
  storyEvents: [
    { id: uid("s"), kind: "milestone", date: d(2026, 6, 9), title: "Two steady weeks", detail: "Weight within a pound, breath easy. Three conditions, one quiet stretch." },
    { id: uid("s"), kind: "companion", date: d(2026, 3, 20), title: "We caught the kidney risk early", detail: "The risk model flagged it from your trends — and your medicine already protects it." },
    { id: uid("s"), kind: "result", date: d(2026, 3, 14), title: "A1c 7.1 · eGFR holding at 66", detail: "Sugar near target, kidneys steady. The plan is working on all three." },
    { id: uid("s"), kind: "visit", date: d(2026, 2, 10), title: "Cardiology · Dr. Reyes", detail: "Heart stable; furosemide kept weight-guided. “Keep weighing in.”" },
    { id: uid("s"), kind: "milestone", date: d(2025, 9, 20), title: "Started empagliflozin", detail: "One medicine, three jobs — the turn this year's stability was built on." },
    { id: uid("s"), kind: "diagnosis", date: d(2024, 5, 2), title: "Heart failure, preserved EF", detail: "Where the daily weigh-in became the most important habit." },
    { id: uid("s"), kind: "diagnosis", date: d(2012, 7, 16), title: "Type 2 diabetes", detail: "The diagnosis that started the long road." },
  ],
  currents: [
    { id: uid("cur"), format: "Glance", kicker: "For your heart", headline: "Why your weight is a heart number", body: "In preserved-EF heart failure, the scale is your earliest warning. A 2–3 lb overnight jump usually isn't fat — it's fluid the stiff heart is struggling to move. Catch it early and a phone call fixes it; miss it and it becomes a hard week.", sceneSeed: 7, imageName: "currents_kidney", aiGenerated: true, intent: "heart-understanding · fluid awareness" },
    { id: uid("cur"), format: "Read", kicker: "One pill, three jobs", headline: "How empagliflozin protects all of you", body: "It started as a diabetes drug. Then the data surprised everyone.\n\nEmpagliflozin nudges your kidneys to pass a little extra sugar — and with it, a little extra sodium and water. That gentle offloading eases the heart's workload and lowers the pressure inside the kidney's tiny filters.\n\nThe result is rare: one daily pill that steadies your sugar, protects a stiff heart, and slows kidney strain at the same time. For a body managing all three, it's the cornerstone — which is why a gap in the refill matters more here than almost anywhere.", sceneSeed: 3, imageName: "currents_kidney", aiGenerated: true, intent: "med-understanding · SGLT2 adherence" },
    { id: uid("cur"), format: "Glance", kicker: "Small swap", headline: "The salt that hides in 'healthy'", body: "A single bowl of canned soup or deli turkey can carry a day's sodium — and tomorrow's water weight. The swap isn't blandness; it's lemon, herbs, garlic and pepper doing the work salt used to.", sceneSeed: 21, imageName: "currents_salt", aiGenerated: true, intent: "low-sodium living" },
    { id: uid("cur"), format: "Listen", kicker: "Two minutes, spoken", headline: "Living well with three at once", body: "A short listen on what it means to manage more than one condition — and why treating them as one story, not three to-do lists, is the kindest thing you can do for yourself.", sceneSeed: 14, imageName: "currents_father_son", aiGenerated: true, intent: "relational · multi-condition life" },
  ],
  moments: [
    { id: uid("m"), kind: "habit", title: "Weigh-in — your daily all-clear", body: "Same time, before coffee. One number that tells your heart team you're steady.", actionLabel: "Logged it" },
    { id: uid("m"), kind: "task", title: "Empagliflozin runs low in 6 days", body: "It's the one guarding heart and kidneys both — let's not let it gap. The refill's ready at CVS.", actionLabel: "Make it ready", medID: "empagliflozin" },
    { id: uid("m"), kind: "insight", title: "Your kidneys, protected early", body: "The risk model caught the trend before it became a problem. Worth seeing what's holding it steady.", actionLabel: "Show me" },
  ],
  statusQuiet: "Three conditions, one quiet day. Take it.", statusBusy: "A few things worth your time — heart, sugar, kidneys, handled together.",
  guideSeed: [
    { id: uid("gd"), kind: "Question", text: "Is my furosemide dose right, or should it flex with my weight?", addedFrom: "From your fluid logs · this week", resolved: false },
    { id: uid("gd"), kind: "Observation", text: "Two steady weeks on the scale — the low-sodium plan is landing.", addedFrom: "From your morning weigh-ins", resolved: false },
    { id: uid("gd"), kind: "Question", text: "Should cardiology and nephrology compare notes on my next eGFR?", addedFrom: "From the kidney-risk heads-up", resolved: false },
  ],
};

export function personaFor(pathway: Pathway): Persona {
  if (pathway === "metabolic") return marcusPersona;
  if (pathway === "oncology") return elenaPersona;
  if (pathway === "cardiometabolic") return rosaPersona;
  return samPersona;
}

// Shared Marcus records corpus (used regardless of pathway for the records drawer).
export const programs: Program[] = [
  { id: uid("p"), title: "Kidney-smart eating, made livable", summary: "Four weeks of small swaps that protect your kidneys without turning dinner into homework.", sponsor: "Meridian Therapeutics", sponsorDetail: "Meridian funds the dietitian content and your access — free to you. They receive program-level enrollment numbers, never your name or your records. Sponsorship never changes what we recommend; this program is here because your kidney function makes it clinically right for you.", clinicalWhy: "With CKD stage 2, the ADA and KDIGO guidance both point at sodium and protein balance as the highest-leverage food moves.", personalFit: "Built around real-life eating — including game-day food. No weighing, no logging meals.", provenance: "KDIGO 2024 · ADA Standards of Care", patientDividend: "Free dietitian content — would run about $120 elsewhere." },
  { id: uid("p"), title: "Home BP, mastered in two weeks", summary: "Get readings your care team actually trusts — timing, posture, and what to ignore.", sponsor: null, sponsorDetail: null, clinicalWhy: "AHA guidance: home readings beat office readings for steering treatment — when they're taken right.", personalFit: "Two minutes a morning, built around your existing cuff.", provenance: "AHA home monitoring guidance", patientDividend: null },
];

export const recordItems: RecordItem[] = [
  { id: uid("r"), category: "Labs", title: "A1c — 8.4%", detail: "Down from 8.7 in December", date: d(2026, 3, 12), source: "Piedmont · Privia", seriesID: "a1c" },
  { id: uid("r"), category: "Labs", title: "eGFR — 74", detail: "Stage 2, holding steady", date: d(2026, 3, 12), source: "Piedmont · Privia", seriesID: "egfr" },
  { id: uid("r"), category: "Labs", title: "LDL — 96", detail: "First time under 100", date: d(2026, 3, 12), source: "Piedmont · Privia", seriesID: "ldl" },
  { id: uid("r"), category: "Labs", title: "Potassium — 4.4", detail: "Comfortably normal", date: d(2026, 3, 12), source: "Piedmont · Privia" },
  { id: uid("r"), category: "Conditions", title: "Type 2 diabetes", detail: "Since 2019 · actively managed", date: d(2019, 8, 14), source: "Piedmont · Privia" },
  { id: uid("r"), category: "Conditions", title: "Hypertension", detail: "Since 2017 · trending calmer", date: d(2017, 5, 2), source: "Piedmont · Privia" },
  { id: uid("r"), category: "Conditions", title: "Chronic kidney disease, stage 2", detail: "Flagged 2024 · stable", date: d(2024, 4, 9), source: "Piedmont · Privia" },
  { id: uid("r"), category: "Medications", title: "Metformin 1000 mg", detail: "Active · twice daily", date: d(2025, 6, 10), source: "Piedmont · Privia" },
  { id: uid("r"), category: "Medications", title: "Lisinopril 10 mg", detail: "Active · once daily", date: d(2024, 4, 9), source: "Piedmont · Privia", conflicted: true, conflictNote: "Emory's list still shows 5 mg from 2023. Piedmont's 10 mg is current — want me to ask your care team to confirm?" },
  { id: uid("r"), category: "Medications", title: "Atorvastatin 20 mg", detail: "Active · evenings", date: d(2025, 3, 18), source: "Piedmont · Privia" },
  { id: uid("r"), category: "Immunizations", title: "Flu vaccine", detail: "Last: October 2025", date: d(2025, 10, 4), source: "CVS Peachtree" },
  { id: uid("r"), category: "Immunizations", title: "COVID-19 booster", detail: "Last: November 2025", date: d(2025, 11, 12), source: "CVS Peachtree" },
  { id: uid("r"), category: "Procedures", title: "Diabetic eye exam", detail: "Normal · repeat yearly", date: d(2025, 11, 20), source: "Emory · MyChart" },
  { id: uid("r"), category: "Notes", title: "Visit note — Dr. Patterson", detail: "\u201CReal progress. Keep the walking.\u201D", date: d(2026, 3, 12), source: "Piedmont · Privia" },
  { id: uid("r"), category: "Documents", title: "Insurance card", detail: "Scanned January 2026", date: d(2026, 1, 8), source: "You" },
];

export const sources: RecordSource[] = [
  { id: uid("src"), name: "Piedmont Internal Medicine", railLabel: "Privia · direct connection", connected: true, lastSync: hoursAgo(2) },
  { id: uid("src"), name: "Emory Healthcare", railLabel: "MyChart · patient access", connected: true, lastSync: hoursAgo(14) },
  { id: uid("src"), name: "CVS Pharmacy", railLabel: "Dispense records", connected: true, lastSync: Date.now() - 35 * 60000 },
  { id: uid("src"), name: "Apple Health", railLabel: "Steps, sleep, BP cuff", connected: true, lastSync: Date.now() - 8 * 60000 },
];

export const consents: ConsentEntry[] = [
  { id: uid("con"), source: "Piedmont · Privia", scope: "Labs, medications, conditions, notes", granted: true, at: d(2026, 4, 2) },
  { id: uid("con"), source: "Emory · MyChart", scope: "Labs, visit notes, procedures", granted: true, at: d(2026, 4, 2) },
  { id: uid("con"), source: "CVS Pharmacy", scope: "Dispense and refill status", granted: true, at: d(2026, 4, 2) },
  { id: uid("con"), source: "Apple Health", scope: "Steps, sleep, heart rate, BP, weight", granted: true, at: d(2026, 4, 2) },
  { id: uid("con"), source: "Consumer insights (Epsilon)", scope: "Timing, tone, and framing — never advertising", granted: true, at: d(2026, 4, 2) },
];

export const memorySeed: MemoryItem[] = [
  { id: uid("mem"), text: "What matters most: being there for DeShawn's college years", learnedFrom: "Your first conversation" },
  { id: uid("mem"), text: "Hardest part: night shifts wreck the routine", learnedFrom: "Your first conversation" },
  { id: uid("mem"), text: "Prefers straight talk — with warmth", learnedFrom: "Your tone setting" },
  { id: uid("mem"), text: "Braves fan — walk windows open after games", learnedFrom: "Conversations in April" },
  { id: uid("mem"), text: "Mornings are chaos; evenings are yours", learnedFrom: "Pattern in your check-ins" },
];

// ---- seed life entries / actions / memories per pathway (mirrors AppModel) ----
export function seedEntries(persona: Persona): CareEntry[] {
  const at = (da: number, h: number, m = 0) => daysAgo(da, h, m);
  const e: CareEntry[] = [];
  e.push({ id: uid("ce"), kind: "Meals", title: "Oatmeal & berries", detail: "Breakfast", at: at(0, 8, 5), imageName: "oatmeal_bowl_blueberries" });
  if (persona.medications[0]) {
    const fm = persona.medications[0];
    e.push({ id: uid("ce"), kind: "Meds", title: fm.name, detail: fm.dose, at: at(0, 8, 15), imageName: LifeLibrary.medImage(fm.id), linkedMedID: fm.id });
  }
  e.push({ id: uid("ce"), kind: "Meals", title: "Grain bowl", detail: "Lunch", at: at(0, 12, 40), imageName: "grain_bowl_chicken_quinoa" });
  e.push({ id: uid("ce"), kind: "Moves", title: "Evening walk", detail: "Felt good to be active", at: at(1, 19, 10), imageName: "terracotta_cream_sneakers" });
  e.push({ id: uid("ce"), kind: "Meals", title: "Lentil soup", detail: "Dinner", at: at(1, 18, 30), imageName: "lentil_soup_bowl" });
  if (persona.medications[1]) {
    const m = persona.medications[1];
    e.push({ id: uid("ce"), kind: "Meds", title: m.name, detail: m.dose, at: at(1, 8, 10), imageName: LifeLibrary.medImage(m.id), linkedMedID: m.id });
  }
  e.push({ id: uid("ce"), kind: "Meals", title: "Veggie omelette", detail: "Breakfast", at: at(1, 8, 0), imageName: "vegetable_omelette_plate" });
  e.push({ id: uid("ce"), kind: "Moves", title: persona.pathway === "procedure" ? "Quad sets & walk" : "Stretch & breathe", detail: "Felt good to be active", at: at(2, 9, 0), imageName: persona.pathway === "procedure" ? "dumbbells_towel_wellness" : "yoga_mat_rolled" });
  e.push({ id: uid("ce"), kind: "Meals", title: "Salmon & greens", detail: "Dinner", at: at(2, 18, 45), imageName: "grilled_salmon_lemon_greens" });
  e.push({ id: uid("ce"), kind: "Meals", title: "Yogurt parfait", detail: "Afternoon", at: at(2, 15, 30), imageName: "yogurt_parfait_glass" });
  return e.sort((a, b) => b.at - a.at);
}

export function seedActions(pathway: Pathway): AgentAction[] {
  const A = (title: string, detail: string, outcomeLine: string, glyph: string, leavesDevice: boolean): AgentAction =>
    ({ id: uid("act"), title, detail, outcomeLine, glyph, leavesDevice, state: "proposed" });
  if (pathway === "metabolic") return [
    A("Flip Thursday's refill to delivery", "Atorvastatin is ready at CVS Peachtree. I can switch it to free delivery so it just arrives.", "Done — delivery lands Thursday afternoon.", "truck", true),
    A("Send your BP week to Dr. Patterson", "Seven steady mornings, charted and worded the way clinics like — ahead of June 24.", "Sent — it'll be in your chart before the visit.", "send", true),
  ];
  if (pathway === "oncology") return [
    A("Pre-fill cycle 4's anti-nausea schedule", "Same rhythm that made cycle 3 your smoothest — ready for Dr. Rivera's sign-off.", "Drafted and queued for the team's sign-off.", "calendar-check", true),
    A("Send the tingling log before July 6", "Your fingertip notes since cycle 2, mapped — exactly what dosing decisions need.", "Sent — Dr. Rivera will see it before your visit.", "send", true),
  ];
  if (pathway === "cardiometabolic") return [
    A("Renew empagliflozin before it gaps", "Six days left. It guards your heart and kidneys both — I can renew it at your pharmacy so the cover never lapses.", "Renewed — no gap in the protection.", "pills", true),
    A("Send your weight-and-BP week to Dr. Reyes", "Seven days of morning weights and pressures, charted the way cardiology likes — ahead of your visit.", "Sent — it'll be in your chart before the visit.", "send", true),
  ];
  return [
    A("Set the NSAID stop reminder", "A gentle nudge the evening of June 15 — ibuprofen and friends stop the 16th.", "Set — I'll catch you the evening of the 15th.", "bell", false),
    A("Send your pain trend to Dr. Chen", "Two points lower on prehab days — worth showing at Tuesday's pre-op.", "Sent — it's on the pre-op summary now.", "send", true),
  ];
}

export function seedMemories(pathway: Pathway): MemoryGlimpse[] {
  const ago = (n: number) => daysAgo(n);
  if (pathway === "metabolic") return [
    { id: uid("mg"), imageName: "tree_path_sunset_walk", caption: "The walk that started it all", date: ago(12) },
    { id: uid("mg"), imageName: "cozy_dinner_table", caption: "Sunday dinner, done right", date: ago(5) },
    { id: uid("mg"), imageName: "recap_garden", caption: "First tomato of the season", date: ago(2) },
  ];
  if (pathway === "oncology") return [
    { id: uid("mg"), imageName: "recap_garden", caption: "Good-window morning in the garden", date: ago(8) },
    { id: uid("mg"), imageName: "cozy_dinner_table", caption: "Halfway dinner with the girls", date: ago(4) },
    { id: uid("mg"), imageName: "tree_path_sunset_walk", caption: "Ten gentle minutes, day 12", date: ago(2) },
  ];
  if (pathway === "cardiometabolic") return [
    { id: uid("mg"), imageName: "tree_path_sunset_walk", caption: "A good-breath morning walk", date: ago(9) },
    { id: uid("mg"), imageName: "cozy_dinner_table", caption: "Low-sodium, still Sunday", date: ago(4) },
    { id: uid("mg"), imageName: "recap_garden", caption: "Slow morning in the garden", date: ago(2) },
  ];
  return [
    { id: uid("mg"), imageName: "tree_path_sunset_walk", caption: "The path waiting for the new knee", date: ago(6) },
    { id: uid("mg"), imageName: "cozy_dinner_table", caption: "Carb-loading, allegedly", date: ago(3) },
    { id: uid("mg"), imageName: "recap_garden", caption: "Prehab garden break", date: ago(1) },
  ];
}
