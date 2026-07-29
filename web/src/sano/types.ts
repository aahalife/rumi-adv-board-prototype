import type { AccentKey } from "./theme";

export type Pathway = "metabolic" | "oncology" | "procedure" | "cardiometabolic";

export interface CareCondition {
  id: string;
  name: string;
  since: string;
  state: string;
  plainLine: string;
  glyph: string;
  accent: AccentKey;
}

export interface SymptomKind {
  name: string;
  glyph: string;
  needsBodyMap?: boolean;
}

export interface CarePlanGoal {
  id: string;
  title: string;
  detail: string;
  progressLine?: string | null;
  accent: AccentKey;
  provenance?: string;
}

export interface CarePlan {
  author: string;
  updated: string;
  intro: string;
  goals: CarePlanGoal[];
}

export interface ExpectationItem {
  id: string;
  window: string;
  title: string;
  detail: string;
  accent: AccentKey;
}

export interface CarePhase {
  kicker: string;
  headline: string;
  detail: string;
  progress?: number | null;
}

export type GuideKind = "Question" | "Observation";
export interface GuideItem {
  id: string;
  kind: GuideKind;
  text: string;
  addedFrom: string;
  resolved: boolean;
}

export interface SupportPlan {
  message: string;
  tips: string[];
  urgent: boolean;
  guideQuestion: string;
  draftMessage: string;
}

export type BodyRegion =
  | "Head" | "Chest" | "Belly" | "Left arm" | "Right arm"
  | "Lower back" | "Left leg" | "Right leg" | "Feet & hands";

// ---- Records ----
export interface LabPoint { date: number; value: number }
export interface LabSeries {
  id: string;
  name: string;
  unit: string;
  points: LabPoint[];
  band?: [number, number] | null;
  bandLabel?: string | null;
  annotation?: { date: number; label: string } | null;
  provenance: string;
  explainReading: string;
  explainNextStep: string;
  explainAsk: string;
}

export type RecordCategory =
  | "Labs" | "Medications" | "Conditions" | "Immunizations"
  | "Procedures" | "Notes" | "Documents";

export interface RecordItem {
  id: string;
  category: RecordCategory;
  title: string;
  detail: string;
  date: number;
  source: string;
  conflicted?: boolean;
  conflictNote?: string | null;
  seriesID?: string | null;
}

export interface Medication {
  id: string;
  name: string;
  dose: string;
  purposeLine: string;
  scheduleLine: string;
  supplyDaysRemaining: number;
  pharmacy: string;
  guidance: string[];
  watchlist: string[];
  history: string[];
  adherence30: number[];
}

export interface CareTeamMember { id: string; name: string; role: string; org: string }

export type AppointmentKind = "inPerson" | "telehealth";
export type AppointmentStatus = "confirmed" | "pending" | "cancelled";
export interface TripPlan {
  departBy: number;
  travelMinutes: number;
  routeHint: string;
  destinationDetail: string;
  mapQuery: string;
  checklist: string[];
  rideHint?: string | null;
  calendarConflict?: string | null;
  isVirtual?: boolean;
}
export interface Appointment {
  id: string;
  with: string;
  date: number;
  location: string;
  prepReady: boolean;
  kind: AppointmentKind;
  status: AppointmentStatus;
  joinLink?: string | null;
  trip?: TripPlan | null;
  planGoalHint?: string | null;
}

export interface RecordSource { id: string; name: string; railLabel: string; connected: boolean; lastSync: number }
export interface ConsentEntry { id: string; source: string; scope: string; granted: boolean; at: number }
export interface MemoryItem { id: string; text: string; learnedFrom: string }

// ---- Engagement ----
export type MomentKind = "insight" | "habit" | "task" | "checkIn";
export interface Moment {
  id: string;
  kind: MomentKind;
  title: string;
  body: string;
  actionLabel: string;
  insightID?: string;
  journeyID?: string;
  medID?: string;
}

export type InsightCategory = "Patterns" | "Milestones" | "Heads-ups" | "Opportunities";
export type InsightStatus =
  | { t: "fresh" } | { t: "seen" } | { t: "saved" } | { t: "acted"; outcome: string };
export type InsightVisual = { t: "chart"; id: string } | { t: "scene"; seed: number } | { t: "tide" };
export interface Insight {
  id: string;
  category: InsightCategory;
  headline: string;
  body: string;
  confidence?: string | null;
  provenance: string;
  actionLabel?: string | null;
  status: InsightStatus;
  visual: InsightVisual;
  sources: string[];
}

export interface AtomicHabit { id: string; title: string; contextLine: string; keptDates: number[] }
export interface Journey {
  id: string;
  title: string;
  why: string;
  habits: AtomicHabit[];
  gardenSeed: number;
  planGoal?: string | null;
}

export interface Program {
  id: string;
  title: string;
  summary: string;
  sponsor?: string | null;
  sponsorDetail?: string | null;
  clinicalWhy: string;
  personalFit: string;
  provenance: string;
  patientDividend?: string | null;
  enrolled?: boolean;
  declined?: boolean;
}

export interface SymptomLog {
  id: string;
  kind: string;
  severity: number;
  at: number;
  note?: string | null;
  bodyRegion?: string | null;
  linkedMedID?: string | null;
}

export type StoryKind = "diagnosis" | "result" | "visit" | "milestone" | "companion";
export interface StoryEvent { id: string; kind: StoryKind; date: number; title: string; detail: string }

// ---- Content ----
export type CurrentFormat = "Glance" | "Read" | "Watch" | "Listen";
export interface CurrentsPiece {
  id: string;
  format: CurrentFormat;
  kicker: string;
  headline: string;
  body: string;
  sceneSeed: number;
  imageName?: string | null;
  aiGenerated: boolean;
  intent: string;
  saved?: boolean;
  taste?: number;
}

export type RichElement =
  | { t: "none" }
  | { t: "trend"; id: string }
  | { t: "habitProposal"; title: string; context: string }
  | { t: "refillFix"; med: string; detail: string }
  | { t: "guideAdd"; question: string }
  | { t: "agentAction"; title: string; detail: string }
  | { t: "program"; title: string };

export interface ConversationTurn {
  id: string;
  role: "user" | "companion";
  text: string;
  rich: RichElement;
  richResolved: boolean;
  streaming: boolean;
}

// ---- Life ----
export type EntryKind = "Meals" | "Moves" | "Meds";
export interface CareEntry {
  id: string;
  kind: EntryKind;
  title: string;
  detail: string;
  at: number;
  imageName: string;
  note?: string | null;
  linkedMedID?: string | null;
}
export interface LifeFacts { calories?: number; protein?: number; carbs?: number; fat?: number; portion?: string; minutes?: number }

export type AgentState = "proposed" | "done" | "declined";
export interface AgentAction {
  id: string;
  title: string;
  detail: string;
  outcomeLine: string;
  glyph: string;
  leavesDevice: boolean;
  state: AgentState;
}

export interface MemoryGlimpse { id: string; imageName?: string | null; photoData?: string | null; caption: string; date: number }

export interface UserProfile {
  firstName: string;
  lastName: string;
  birthDate?: number | null;
  healthConnected: boolean;
  connectedSystems: string[];
}

// ---- Care hub ----
export type MessageMode = "inApp" | "portal";
export type MessageCategory = "medical" | "refill" | "admin" | "billing";
export type MessageState = "draft" | "sending" | "sent" | "delivered" | "replied" | "portalReady";
export interface CareMessage {
  id: string;
  author: "user" | "team";
  text: string;
  at: number;
  state: MessageState;
  origin?: string | null;
  attachment?: string | null;
}
export interface MessageThread {
  id: string;
  practice: string;
  memberName: string;
  memberRole: string;
  mode: MessageMode;
  category: MessageCategory;
  messages: CareMessage[];
  unread: boolean;
}

export type BillStatus = "open" | "paid" | "inDispute";
export interface BillLineItem { id: string; label: string; billed: number; planPaid: number; youOwe: number; reason: string }
export interface Bill {
  id: string;
  key: string;
  provider: string;
  encounter: string;
  statementDate: number;
  dueDate?: number | null;
  status: BillStatus;
  amount: number;
  lineItems: BillLineItem[];
  plainSummary: string;
  flag?: string | null;
  source: string;
}
export interface CostSummary {
  planName: string;
  deductibleMet: number;
  deductibleTotal: number;
  oopMet: number;
  oopTotal: number;
  upcomingEstimate?: number | null;
  upcomingLabel?: string | null;
}

export type DocumentType = "insuranceCard" | "labResult" | "form" | "referral" | "afterVisit" | "other";
export interface ExtractedField { id: string; label: string; value: string; lowConfidence?: boolean }
export interface CareDocument {
  id: string;
  title: string;
  type: DocumentType;
  capturedAt: number;
  source: string;
  fields: ExtractedField[];
  confirmed: boolean;
  pageCount?: number;
  bundledImage?: string | null;
}

export type SavingKind = "copayCard" | "assistance" | "cashPrice" | "alternative";
export interface MedicationSaving {
  id: string;
  medID: string;
  kind: SavingKind;
  title: string;
  estimateLine: string;
  basis: string;
  sponsor?: string | null;
  applied?: boolean;
  requiresPII: boolean;
}

export type RequestKind = "refill" | "records" | "form" | "appointment" | "referral";
export type RequestState = "submitted" | "acknowledged" | "resolved";
export interface CareRequest {
  id: string;
  kind: RequestKind;
  subject: string;
  detail: string;
  state: RequestState;
  routedTo: string;
  at: number;
}

export interface LookingAheadNudge { headline: string; body: string; basis: string; guideQuestion: string }

export interface Persona {
  pathway: Pathway;
  firstName: string;
  switcherLine: string;
  conditions: CareCondition[];
  conditionChip: string;
  heroImage: string;
  phase?: CarePhase | null;
  expectations: ExpectationItem[];
  carePlan: CarePlan;
  symptomKinds: SymptomKind[];
  labSeries: LabSeries[];
  medications: Medication[];
  careTeam: CareTeamMember[];
  officePhone: string;
  officeName: string;
  appointments: Appointment[];
  journeys: Journey[];
  insights: Insight[];
  storyEvents: StoryEvent[];
  currents: CurrentsPiece[];
  moments: Moment[];
  statusQuiet: string;
  statusBusy: string;
  guideSeed: GuideItem[];
}

export interface CareBundle {
  threads: MessageThread[];
  appointments: Appointment[];
  bills: Bill[];
  cost: CostSummary;
  documents: CareDocument[];
  savings: MedicationSaving[];
  requestsSeed: CareRequest[];
  resultToAck?: { title: string; detail: string; series?: string | null } | null;
  lookingAhead?: LookingAheadNudge | null;
}
