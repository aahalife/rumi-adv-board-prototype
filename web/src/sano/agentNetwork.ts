import type { AccentKey } from "./theme";
import type { CareTeamMember, LabSeries, Medication, SymptomLog, CareEntry, GuideItem, Persona, Pathway } from "./types";

// ---- Wallet ----
export type WalletKind = "hsa" | "card" | "insurance";
export interface WalletCard {
  id: string;
  kind: WalletKind;
  name: string;
  issuer: string;
  last4: string;
  accent: AccentKey;
  balanceLine?: string | null;
}
export const walletKindLabel = (k: WalletKind): string => (k === "hsa" ? "HSA card" : k === "insurance" ? "Insurance" : "Card");
export const walletKindGlyph = (k: WalletKind): string => (k === "hsa" ? "heart" : k === "insurance" ? "cross.case" : "creditcard");

export function walletFor(pathway: Pathway): WalletCard[] {
  const insurer = pathway === "metabolic" ? ["Anthem Blue Cross", "PPO"] : pathway === "oncology" ? ["Aetna", "PPO"] : pathway === "cardiometabolic" ? ["Cigna", "PPO"] : ["UnitedHealthcare", "PPO"];
  return [
    { id: "hsa", kind: "hsa", name: "HSA card", issuer: "HealthEquity", last4: "4821", accent: "life", balanceLine: "$1,940 available" },
    { id: "visa", kind: "card", name: "Visa", issuer: "Personal", last4: "7390", accent: "sky" },
    { id: "insurance", kind: "insurance", name: insurer[0], issuer: insurer[1], last4: "0142", accent: "gold" },
  ];
}

// ---- Connections ----
export type ConnectionGroup = "google" | "channel";
export interface Connection {
  id: string;
  name: string;
  group: ConnectionGroup;
  glyph: string;
  detail: string;
  accent: AccentKey;
  connected: boolean;
  accountLine?: string | null;
  enables: string;
}
export function connectionsSeed(): Connection[] {
  return [
    { id: "gmail", name: "Gmail", group: "google", glyph: "envelope", detail: "Spot bills, receipts and results in your inbox", accent: "rose", connected: false, enables: "Rumi can flag a bill or result the moment it lands, and send on your behalf with one tap." },
    { id: "gcal", name: "Google Calendar", group: "google", glyph: "calendar", detail: "Keep visits and reminders in sync", accent: "sky", connected: false, enables: "New appointments and stop-med reminders drop straight onto your calendar." },
    { id: "imessage", name: "iMessage", group: "channel", glyph: "message-circle", detail: "Gentle nudges and check-ins by text", accent: "life", connected: false, enables: "Rumi can reach you with a check-in by text, and you can reply back into the app." },
    { id: "sms", name: "SMS", group: "channel", glyph: "message-circle", detail: "Reminders even without the app open", accent: "gold", connected: false, enables: "Time-sensitive reminders arrive by text wherever you are." },
    { id: "instagram", name: "Instagram", group: "channel", glyph: "camera", detail: "Your daily 'for you' care content, where you already scroll", accent: "warm", connected: false, enables: "Your daily Currents pieces can arrive as saved reels — still logged here." },
  ];
}
export function sampleAccount(id: string, name: string): string {
  const handle = name.toLowerCase();
  switch (id) {
    case "gmail":
    case "gcal": return `${handle}@gmail.com`;
    case "imessage": return `Apple ID · ${handle}`;
    case "sms": return "(404) 555-0149";
    case "instagram": return `@${handle}_atl`;
    default: return "Connected";
  }
}

// ---- Agent family ----
export interface AgentService { id: string; name: string; role: string; glyph: string; accent: AccentKey; active: boolean }
export function agentServicesSeed(): AgentService[] {
  return [
    { id: "risk", name: "Risk watch", role: "Flags possible issues early from your record and history", glyph: "shield", accent: "warm", active: true },
    { id: "monitor", name: "Continuous monitoring", role: "Notices warning signs across your day-to-day", glyph: "activity", accent: "sky", active: true },
    { id: "alerts", name: "Alerts & escalation", role: "Routes time-sensitive things to the right person", glyph: "bell", accent: "rose", active: true },
    { id: "scheduling", name: "Smart scheduling", role: "Books and moves visits around your life", glyph: "calendar", accent: "gold", active: true },
    { id: "education", name: "Support & education", role: "A 24/7 voice for questions, coaching and reassurance", glyph: "message-circle", accent: "life", active: true },
    { id: "pathway", name: "Care pathway", role: "Walks you through your plan and keeps your team posted", glyph: "map", accent: "sky", active: true },
    { id: "adherence", name: "Medication adherence", role: "Refills, reminders and insurance navigation", glyph: "pills", accent: "warm", active: true },
    { id: "lifestyle", name: "Lifestyle support", role: "Tiny, sustainable habits tuned to your condition", glyph: "leaf", accent: "life", active: true },
  ];
}

// ---- Agent activity: what each helper is doing ----
export type AgentTaskMode = "automatic" | "needsApproval";
export type AgentTaskStatus = "working" | "waiting" | "scheduled" | "done";
export interface AgentSource { label: string; connectionID?: string | null }
export interface AgentTask {
  id: string;
  agentID: string;
  title: string;
  detail: string;
  mode: AgentTaskMode;
  status: AgentTaskStatus;
  sources: AgentSource[];
  cadence: string;
  outcomeLine: string;
}
export const agentModeLabel = (m: AgentTaskMode): string => (m === "automatic" ? "Automatic" : "Needs your ok");

const sRecord: AgentSource = { label: "Your record" };
const sHealth: AgentSource = { label: "Apple Health" };
const sLogs: AgentSource = { label: "Your logs" };
const sPharmacy: AgentSource = { label: "Your pharmacy" };
const sGmail: AgentSource = { label: "Gmail", connectionID: "gmail" };
const sCalendar: AgentSource = { label: "Google Calendar", connectionID: "gcal" };
const sInstagram: AgentSource = { label: "Instagram", connectionID: "instagram" };
const tk = (id: string, agentID: string, title: string, detail: string, mode: AgentTaskMode, status: AgentTaskStatus, sources: AgentSource[], cadence: string, outcomeLine: string): AgentTask => ({ id, agentID, title, detail, mode, status, sources, cadence, outcomeLine });

const metabolicTasks: AgentTask[] = [
  tk("m-risk-1", "risk", "Watching your kidney trend", "Your eGFR has held at stage 2 for a year. I read every new panel the moment it lands — and your blood pressure right alongside it — so a real drift never sneaks up.", "automatic", "working", [sRecord, sHealth], "Always on", "I'll flag the first true change, gently."),
  tk("m-mon-1", "monitor", "Reading your morning BP", "Each home-cuff reading syncs straight to me. I'm tracking the slow drift toward your calm zone — and how a night-shift week bends it.", "automatic", "working", [sHealth], "Every morning", "A heads-up only when a week runs high."),
  tk("m-mon-2", "monitor", "The late-statin cramp pattern", "I'm holding your atorvastatin dose times against your cramp logs. It's clustered 4 of 5 times — already drafted as a question for Dr. Patterson.", "automatic", "working", [sLogs], "Ongoing", "Caught, so you don't have to remember it."),
  tk("m-adh-1", "adherence", "Your statin is low — delivery's ready", "Five days left at CVS Peachtree. I can switch Thursday's refill to free delivery so it simply arrives — no errand.", "needsApproval", "waiting", [sPharmacy, sGmail], "By Thursday", "Done — it lands Thursday afternoon."),
  tk("m-adh-2", "adherence", "Folding three refills into one day", "Metformin, lisinopril and the statin have drifted apart. I'm lining them up to a single monthly pickup.", "automatic", "working", [sPharmacy], "This month", "One trip instead of three."),
  tk("m-sch-1", "scheduling", "Holding a lab slot before June 24", "Your A1c and kidney panel are due. I'm holding an early-morning draw so the results beat your visit with Dr. Patterson.", "needsApproval", "waiting", [sCalendar], "Before June 24", "Booked — and on your calendar."),
  tk("m-alert-1", "alerts", "Routing anything urgent, the right way", "If a reading or result crosses a line, I send it to the right person and keep nudging until it's truly seen.", "automatic", "working", [sRecord, sHealth], "Always on", "You'll never have to chase it."),
  tk("m-edu-1", "education", "Curating your 'for you' shelf", "I pick the few pieces most worth your minutes this week — the evening walk, the salt hiding in Sunday — and skip the noise.", "automatic", "working", [sLogs, sInstagram], "Daily", "A short, kind shelf — never a feed."),
  tk("m-path-1", "pathway", "Keeping Dr. Patterson's chart current", "Between visits I keep your trends and open questions tidy, so each appointment starts where the last one left off.", "automatic", "working", [sRecord], "Ongoing", "Your team always has the latest picture."),
  tk("m-life-1", "lifestyle", "Guarding your after-dinner walk", "On quiet nights I nudge the 15 minutes; on Braves nights I move it earlier so it still happens.", "automatic", "working", [sCalendar], "Most evenings", "The streak keeps itself."),
];

const oncologyTasks: AgentTask[] = [
  tk("o-alert-1", "alerts", "The fever rule, always armed", "100.4°F or higher is a call-now, any hour. If you log a fever, I open the line to Dr. Rivera's team and stay with you through the call.", "automatic", "working", [sLogs], "Always on", "Never sat on, never missed."),
  tk("o-mon-1", "monitor", "Watching your low-count window", "I know your counts dip days 7–10. I'm counting you into that window now, so the small-crowds, good-handwashing week starts on time.", "automatic", "working", [sRecord, sLogs], "This cycle", "A gentle nudge the day it opens."),
  tk("o-risk-1", "risk", "Tracking the fingertip tingling", "Neuropathy is the thing taxane dosing turns on. I'm logging when and how strong, so Dr. Rivera has the real picture before cycle 4.", "automatic", "working", [sLogs], "Ongoing", "Every note shapes the next dose."),
  tk("o-sch-1", "scheduling", "Carrying cycle 3's plan into cycle 4", "Your smoothest cycle yet ran on a scheduled anti-nausea plan. I've queued the same for the 22nd — your team just signs off.", "needsApproval", "waiting", [sRecord], "Before June 22", "Drafted and ready for their ok."),
  tk("o-adh-1", "adherence", "Pre-staging your infusion meds", "Ondansetron and dexamethasone are stocked at Northside ahead of cycle 4. I'm keeping the timing card ready for day one.", "automatic", "working", [sPharmacy], "Before cycle 4", "Nothing to pick up, nothing to forget."),
  tk("o-sch-2", "scheduling", "A ride home after infusion", "You shouldn't drive after the 22nd. Connect your calendar and I'll line up a ride and hold the afternoon clear.", "needsApproval", "waiting", [sCalendar], "June 22", "A ride confirmed, the day kept gentle."),
  tk("o-edu-1", "education", "Good-window living, queued", "For days 10–21 I'm gathering the things that make you feel like you — not chores, the living. Yours to spend.", "automatic", "working", [sLogs, sInstagram], "Each cycle", "The good window, planned for joy."),
  tk("o-path-1", "pathway", "Keeping your team in rhythm", "Oncology, your infusion nurse, pharmacy — I keep each cycle's notes flowing between them so nothing repeats and nothing drops.", "automatic", "working", [sRecord], "Ongoing", "One picture, every visit."),
  tk("o-life-1", "lifestyle", "Hydration that does the heavy lifting", "Eight glasses on infusion days eases almost everything. I count quietly and only mention it when it helps.", "automatic", "working", [sHealth, sLogs], "Infusion weeks", "Softer days, fewer rough ones."),
];

const procedureTasks: AgentTask[] = [
  tk("p-alert-1", "alerts", "The NSAID stop, locked to June 16", "Ibuprofen and friends thin the blood around surgery. I'll catch you the evening of the 15th — and watch for any that slip into your logs.", "automatic", "working", [sLogs], "Until June 16", "The hard rule, kept for you."),
  tk("p-mon-1", "monitor", "Reading your prehab pain trend", "Evenings have drifted from 6s to 4s on quad-set days. I'm charting it so the pre-op visit opens with proof the plan's working.", "automatic", "working", [sLogs], "Daily", "A trend, ready to show Dr. Chen."),
  tk("p-sch-1", "scheduling", "Booking your first PT within a week", "Recovery lives in physical therapy. I'm holding a post-op slot with Priya so week one doesn't slip.", "needsApproval", "waiting", [sCalendar], "After June 23", "First session locked before you're home."),
  tk("p-sch-2", "scheduling", "Moving your June 23 work call", "Your calendar shows a 5pm call the day of surgery — you'll be recovering. I can move it and protect the day.", "needsApproval", "waiting", [sCalendar], "June 23", "Cleared, with a kind note sent."),
  tk("p-risk-1", "risk", "Watching the week-one clot signs", "Calf pain, one-sided swelling, shortness of breath. I keep these few specifics close so a real one becomes a call-now, fast.", "automatic", "working", [sLogs], "Weeks 1–2 after", "The few that matter, never missed."),
  tk("p-adh-1", "adherence", "Acetaminophen stocked, the safe one", "Your green-lit option is in at Walgreens, and the post-op script is set for surgery day. I'm keeping the timing simple.", "automatic", "working", [sPharmacy], "Through recovery", "The right pill, ready when you need it."),
  tk("p-life-1", "lifestyle", "Readying the home for after", "Ice packs, clear walkways, the raised seat. I'm pacing one readiness item a day so future-you arrives to a kind house.", "automatic", "working", [sLogs], "Until surgery", "Home, ready before you are."),
  tk("p-path-1", "pathway", "Bridging surgery to rehab", "Dr. Chen's team and Priya's rehab don't share a chart — so I do. Your prehab trend travels with you to week one.", "automatic", "working", [sRecord], "Ongoing", "No detail lost in the handoff."),
  tk("p-edu-1", "education", "Week-one expectations, in plain words", "I'm cueing up the honest version — swelling that travels, the wins that look like shuffles — so nothing surprises you.", "automatic", "working", [sInstagram], "Before surgery", "Calm, because you knew it was coming."),
];

const cardiometabolicTasks: AgentTask[] = [
  tk("c-risk-1", "risk", "Watching your kidney risk early", "Your pattern points to early kidney strain. I track eGFR, weight and pressure together — the three that move first — so we act early, never late.", "automatic", "working", [sRecord, sHealth], "Always on", "You'll hear it from me before it's a problem."),
  tk("c-risk-2", "risk", "Worth looping in nephrology now", "Yours is the pattern kidney doctors like to see early, not late. I've drafted a referral note to Dr. Okafor for you to review.", "needsApproval", "waiting", [sRecord], "When you're ready", "Sent the moment you say go."),
  tk("c-mon-1", "monitor", "Reading your daily weight for fluid", "A two-pound overnight jump is the heart's first whisper. I check your morning weight and ankle notes every single day.", "automatic", "working", [sHealth, sLogs], "Every morning", "A flag the day it shifts — not the week after."),
  tk("c-alert-1", "alerts", "The breathlessness rule, armed", "If you log shortness of breath or a fluid jump, I route it to your heart team the same day — any hour, no hesitating.", "automatic", "working", [sLogs], "Always on", "Never sat on, never missed."),
  tk("c-adh-1", "adherence", "Empagliflozin refill — ready to send", "Your SGLT2 protects heart and kidney both, and you're down to six days. I can renew it now so the protection never gaps.", "needsApproval", "waiting", [sPharmacy], "This week", "Renewed — no gap in the cover."),
  tk("c-sch-1", "scheduling", "Cardiology + nephrology, one trip", "Two specialists, one morning in town. I'm holding back-to-back slots so you're not making the drive twice.", "needsApproval", "waiting", [sCalendar], "This month", "Both booked, same morning."),
  tk("c-edu-1", "education", "Heart- and kidney-smart plates", "Low-sodium, kidney-gentle, and pulled toward the vegetarian dinners you already like. I curate a few you'll actually cook.", "automatic", "working", [sLogs, sInstagram], "Daily", "Dinner, made simpler."),
  tk("c-path-1", "pathway", "Keeping three doctors on one page", "Primary care, cardiology, nephrology — I reconcile what each one knows so no one's working blind, and your context follows you in.", "automatic", "working", [sRecord], "Ongoing", "One shared picture, always current."),
  tk("c-life-1", "lifestyle", "Pacing movement around your heart", "Short, kind walks on good-breath days. I read your energy from Apple Health and never push past it.", "automatic", "working", [sHealth], "Most days", "Movement that helps, never strains."),
  tk("c-mon-2", "monitor", "Glucose and pressure, read together", "I watch how your sugar and blood pressure move as a pair — in this body they pull on the same strings, and the kidneys feel both.", "automatic", "working", [sHealth, sLogs], "Ongoing", "The whole picture, not one number."),
];

export function agentTasksFor(pathway: Pathway): AgentTask[] {
  if (pathway === "oncology") return oncologyTasks.map((t) => ({ ...t }));
  if (pathway === "procedure") return procedureTasks.map((t) => ({ ...t }));
  if (pathway === "cardiometabolic") return cardiometabolicTasks.map((t) => ({ ...t }));
  return metabolicTasks.map((t) => ({ ...t }));
}

// ---- Per-doctor reports ----
export interface ReportLine { primary: string; secondary?: string | null }
export type ReportKind = "headline" | "numbers" | "meds" | "logging" | "crossRef" | "questions";
export interface ReportSection { id: string; title: string; kind: ReportKind; lines: ReportLine[] }
export interface DoctorReport {
  id: string;
  doctorName: string;
  doctorRole: string;
  org: string;
  title: string;
  focusLine: string;
  preparedLine: string;
  sections: ReportSection[];
}

interface ReportInputs {
  persona: Persona;
  careTeam: CareTeamMember[];
  labSeries: LabSeries[];
  medications: Medication[];
  logs: SymptomLog[];
  guideItems: GuideItem[];
  entries: CareEntry[];
  rangeDays: number;
}

export function buildReports(inp: ReportInputs): DoctorReport[] {
  return inp.careTeam
    .filter((m) => !m.role.toLowerCase().includes("pharmacy"))
    .map((m) => buildOne(m, inp));
}

let _rid = 0;
const sid = (): string => `rs_${_rid++}`;

function buildOne(member: CareTeamMember, inp: ReportInputs): DoctorReport {
  const cutoff = Date.now() - inp.rangeDays * 86_400_000;
  const focus = focusLine(member.role);

  const headline: ReportSection = { id: sid(), title: "Summary", kind: "headline", lines: [
    { primary: `${inp.persona.firstName} — ${inp.persona.conditionChip}.`, secondary: `Prepared for ${member.name} (${member.role}). Centered on ${focus}.` },
  ] };

  const orderedLabs = [...inp.labSeries].sort((a, b) => relevance(b.name, member.role) - relevance(a.name, member.role));
  const numbers: ReportSection = { id: sid(), title: "Your numbers", kind: "numbers", lines: orderedLabs.map((s) => {
    const latest = s.points[s.points.length - 1];
    return { primary: `${s.name}: ${latest ? fmt(latest.value) : "—"} ${s.unit}`, secondary: trendLine(s) };
  }) };

  const meds: ReportSection = { id: sid(), title: "Medications", kind: "meds", lines: inp.medications.map((m) => {
    const pct = Math.round((m.adherence30.reduce((a, b) => a + b, 0) * 100) / Math.max(1, m.adherence30.length));
    return { primary: `${m.name} ${m.dose}`, secondary: `${pct}% taken (30d) · ${m.supplyDaysRemaining} days on hand` };
  }) };

  const rangeLogs = inp.logs.filter((l) => l.at > cutoff);
  const meal = inp.entries.filter((e) => e.kind === "Meals" && e.at > cutoff).length;
  const move = inp.entries.filter((e) => e.kind === "Moves" && e.at > cutoff).length;
  const grouped = new Map<string, SymptomLog[]>();
  rangeLogs.forEach((l) => { const a = grouped.get(l.kind) ?? []; a.push(l); grouped.set(l.kind, a); });
  const loggingLines: ReportLine[] = [...grouped.entries()].sort((a, b) => b[1].length - a[1].length)
    .map(([kind, items]) => ({ primary: `${kind}: ${items.length} log${items.length === 1 ? "" : "s"}`, secondary: severitySummary(items) }));
  loggingLines.push({ primary: "Daily life", secondary: `${meal} meals and ${move} active sessions logged` });
  const logging: ReportSection = { id: sid(), title: `What ${inp.persona.firstName} has been logging`, kind: "logging", lines: loggingLines };

  const crossRef: ReportSection = { id: sid(), title: "From your wider care team", kind: "crossRef", lines: inp.careTeam.filter((o) => o.id !== member.id).map((o) => ({ primary: `${o.name} · ${o.role}`, secondary: crossRefLine(o.role) })) };

  const qLines = inp.guideItems.filter((g) => !g.resolved).map((g) => ({ primary: g.text }));
  const questions: ReportSection = { id: sid(), title: "Worth covering this visit", kind: "questions", lines: qLines.length ? qLines : [{ primary: "Nothing flagged — a steady stretch." }] };

  return {
    id: `${member.id}-${inp.rangeDays}`,
    doctorName: member.name,
    doctorRole: member.role,
    org: member.org,
    title: `${roleTitle(member.role)} summary`,
    focusLine: focus,
    preparedLine: `Prepared from your last ${inp.rangeDays} days · ${new Date().toLocaleDateString([], { month: "long", day: "numeric", year: "numeric" })}`,
    sections: [headline, numbers, meds, logging, crossRef, questions],
  };
}

function roleTitle(role: string): string {
  const l = role.toLowerCase();
  if (l.includes("primary")) return "Primary care";
  if (l.includes("oncolog")) return "Oncology";
  if (l.includes("nephro")) return "Nephrology";
  if (l.includes("ortho") || l.includes("surg")) return "Surgical";
  if (l.includes("physical")) return "Physical therapy";
  if (l.includes("nurse") || l.includes("navigator")) return "Care navigation";
  return role;
}
function focusLine(role: string): string {
  const l = role.toLowerCase();
  if (l.includes("primary")) return "the whole picture across your specialists";
  if (l.includes("oncolog")) return "chemo tolerance, counts and symptom burden";
  if (l.includes("nephro")) return "kidney function and protective habits";
  if (l.includes("ortho") || l.includes("surg")) return "the procedure, prehab and recovery readiness";
  if (l.includes("physical")) return "mobility, strength and your pain trend";
  if (l.includes("nurse") || l.includes("navigator")) return "how each cycle is landing day to day";
  return "your overall progress";
}
function crossRefLine(role: string): string {
  const l = role.toLowerCase();
  if (l.includes("pharmacy")) return "Keeps refills synced and flags interactions.";
  if (l.includes("primary")) return "Holds the whole-person view and reconciles every specialist.";
  if (l.includes("oncolog")) return "Leads treatment; watching counts and tolerance.";
  if (l.includes("nephro")) return "Protecting kidney function alongside the metabolic plan.";
  if (l.includes("ortho") || l.includes("surg")) return "Owns the procedure and recovery milestones.";
  if (l.includes("physical")) return "Rebuilding strength and range after the procedure.";
  if (l.includes("nurse") || l.includes("navigator")) return "Closest to the day-to-day between visits.";
  return "Part of the shared plan.";
}
function relevance(name: string, role: string): number {
  const n = name.toLowerCase(); const r = role.toLowerCase();
  if (r.includes("nephro") && (n.includes("kidney") || n.includes("egfr") || n.includes("creatinine"))) return 3;
  if ((r.includes("primary") || r.includes("endo")) && (n.includes("a1c") || n.includes("glucose") || n.includes("pressure"))) return 3;
  if (r.includes("oncolog") && (n.includes("anc") || n.includes("count") || n.includes("immune"))) return 3;
  if ((r.includes("ortho") || r.includes("physical") || r.includes("surg")) && n.includes("pain")) return 3;
  return 1;
}
function trendLine(s: LabSeries): string | null {
  if (s.points.length < 2) return s.bandLabel ?? null;
  const first = s.points[s.points.length - 2].value;
  const last = s.points[s.points.length - 1].value;
  if (Math.abs(last - first) < 0.0001) return "holding steady";
  return last < first ? `down from ${fmt(first)}` : `up from ${fmt(first)}`;
}
function severitySummary(logs: SymptomLog[]): string | null {
  if (!logs.length) return null;
  const avg = logs.reduce((a, l) => a + l.severity, 0) / logs.length;
  if (avg < 0.35) return "mostly mild";
  if (avg < 0.65) return "moderate on average";
  return "running high — worth a look";
}
function fmt(v: number): string { return v === Math.round(v) ? String(Math.round(v)) : v.toFixed(1); }
