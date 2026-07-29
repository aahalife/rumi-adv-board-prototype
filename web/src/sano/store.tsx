import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import type {
  Pathway, Persona, Moment, Insight, Medication, Journey, Program, SymptomLog, CurrentsPiece,
  LabSeries, StoryEvent, CareTeamMember, Appointment, GuideItem, RecordItem, RecordSource,
  ConsentEntry, MemoryItem, MessageThread, Bill, CostSummary, CareDocument, MedicationSaving,
  CareRequest, CareEntry, AgentAction, MemoryGlimpse, UserProfile, ConversationTurn, EntryKind,
  CarePlanGoal, SupportPlan, LookingAheadNudge, RichElement, InsightStatus,
} from "./types";
import { personaFor, programs as seedPrograms, recordItems as seedRecords, sources as seedSources, consents as seedConsents, memorySeed, seedEntries, seedActions, seedMemories } from "./fixtures";
import { careBundleFor, supportPlan } from "./careBundles";
import { walletFor, connectionsSeed, agentServicesSeed, agentTasksFor, buildReports, sampleAccount, type WalletCard, type Connection, type AgentService, type DoctorReport, type AgentTask } from "./agentNetwork";
import { LifeLibrary, uid, capFirst } from "./lifeLibrary";
import { SoundEngine, Haptics } from "./sound";
import { streamChat, parseTags, makeHoldbackFilter, newTurn, localReply, type ChatMessage } from "./ai";
import type { Scheme } from "./theme";

export type Tab = "today" | "care" | "you" | "journeys" | "currents";
export interface NeedsYou { id: string; kind: "message" | "result" | "refill" | "bill" | "appointment"; title: string; detail: string; destination: CareDest }
export type CareDest =
  | { t: "messages" } | { t: "thread"; id: string } | { t: "requests" } | { t: "appointments" }
  | { t: "appointmentDetail"; id: string } | { t: "carePlan" } | { t: "medications" }
  | { t: "records" } | { t: "bills" } | { t: "billDetail"; id: string } | { t: "documents" } | { t: "visitPrep" };

const PERSIST_KEY = "sano.web.v1";

interface SanoStore {
  // shell
  tab: Tab; setTab: (t: Tab) => void;
  hasOnboarded: boolean;
  showConversation: boolean; openConversation: (seed?: string) => void; closeConversation: () => void;
  showQuickLog: boolean; setShowQuickLog: (b: boolean) => void; quickLogMedID: string | null; setQuickLogMedID: (s: string | null) => void;
  showSettings: boolean; setShowSettings: (b: boolean) => void;
  showRecap: boolean; setShowRecap: (b: boolean) => void;
  pendingCareDest: CareDest | null; setPendingCareDest: (d: CareDest | null) => void;
  // person
  pathway: Pathway; persona: Persona; profile: UserProfile; setProfile: (p: UserProfile) => void;
  displayFirstName: string;
  // stores
  moments: Moment[]; insights: Insight[]; medications: Medication[]; journeys: Journey[];
  programs: Program[]; logs: SymptomLog[]; currents: CurrentsPiece[]; labSeries: LabSeries[];
  storyEvents: StoryEvent[]; careTeam: CareTeamMember[]; appointments: Appointment[]; guideItems: GuideItem[];
  recordItems: RecordItem[]; sources: RecordSource[]; consents: ConsentEntry[]; memory: MemoryItem[];
  threads: MessageThread[]; bills: Bill[]; cost: CostSummary; careDocuments: CareDocument[];
  savings: MedicationSaving[]; requests: CareRequest[]; entries: CareEntry[]; agentActions: AgentAction[];
  memories: MemoryGlimpse[]; resultToAck: { title: string; detail: string; series?: string | null } | null;
  resultAcknowledged: boolean; lookingAhead: LookingAheadNudge | null; showsLookingAhead: boolean;
  derivedJourneyGoals: Set<string>;
  // prefs
  tonePreference: string; setTonePreference: (s: string) => void;
  appearance: string; setAppearance: (s: string) => void; scheme: Scheme;
  musicOn: boolean; setMusicOn: (b: boolean) => void;
  soundOn: boolean; setSoundOn: (b: boolean) => void;
  epsilonConsent: boolean; setEpsilonConsent: (b: boolean) => void;
  eraWarmth: string; setEraWarmth: (s: string) => void;
  notificationClasses: Record<string, boolean>; toggleNotification: (k: string) => void;
  quietStart: number; quietEnd: number; setQuiet: (s: number, e: number) => void;
  // orb
  orbState: OrbMode; justBloomed: boolean;
  quickLogAck: string | null; setQuickLogAck: (s: string | null) => void;
  // companion
  turns: ConversationTurn[]; isThinking: boolean; sendMessage: (text: string) => void; sendVoiceMessage: (text: string) => Promise<string>; resolveRich: (id: string) => void;
  // derived
  pendingActions: AgentAction[]; needsYou: NeedsYou[]; openBillsTotal: number; careUnreadCount: number;
  // agent network
  walletCards: WalletCard[]; connections: Connection[]; agentServices: AgentService[];
  agentTasks: AgentTask[];
  agentTasksWaiting: AgentTask[]; agentTasksInMotion: AgentTask[];
  tasksForAgent: (id: string) => AgentTask[];
  activeTaskCount: (id: string) => number; waitingCount: (id: string) => number;
  approveAgentTask: (id: string) => void; declineAgentTask: (id: string) => void;
  showAgentNetwork: boolean; setShowAgentNetwork: (b: boolean) => void;
  agentNetworkFocus: string | null; openAgentNetwork: (focus?: string | null) => void;
  reports: (rangeDays: number) => DoctorReport[];
  reportSent: (id: string) => boolean;
  sendReport: (r: DoctorReport) => void;
  payBill: (billID: string, card: WalletCard) => void;
  toggleConnection: (id: string) => void;
  toggleAgentService: (id: string) => void;
  series: (id: string) => LabSeries | undefined;
  savingsFor: (medID: string) => MedicationSaving[];
  logsNear: (medID: string) => SymptomLog[];
  hasDerivedJourney: (title: string) => boolean;
  // actions
  completeOnboarding: (vals: { firstName: string; lastName: string; birthDate: number | null; pathway: Pathway; connectedSystems: string[]; healthConnected: boolean; values: string; barrier: string; tone: string }) => void;
  switchPathway: (p: Pathway) => void;
  dismissMoment: (id: string) => void;
  keepHabit: (jid: string, hid: string) => void; keptToday: (jid: string, hid: string) => boolean;
  addEntry: (kind: EntryKind, text: string, note?: string, linkedMedID?: string) => void;
  removeEntry: (id: string) => void;
  approveAction: (id: string) => void; declineAction: (id: string) => void;
  addMemoryGlimpse: (img: string, caption: string) => void; deleteMemoryGlimpse: (id: string) => void;
  addLog: (kind: string, severity: number, note: string | null, bodyRegion?: string | null, linkedMedID?: string | null) => SupportPlan;
  addGuideItem: (kind: GuideItem["kind"], text: string, from: string) => void;
  toggleGuideResolved: (id: string) => void; removeGuideItem: (id: string) => void;
  markInsightSeen: (id: string) => void; toggleInsightSaved: (id: string) => void;
  enroll: (id: string) => void; decline: (id: string) => void;
  toggleCurrentSaved: (id: string) => void; setTaste: (id: string, v: number) => void;
  deleteMemoryNote: (id: string) => void; addMemoryNote: (text: string, from: string) => void;
  acknowledgeResult: () => void;
  markThreadRead: (id: string) => void;
  sendThreadMessage: (threadID: string, text: string, origin?: string) => void;
  startThread: (p: { practice: string; member: string; role: string; mode: "inApp" | "portal"; category: MessageThread["category"]; text: string; origin?: string }) => void;
  submitRequest: (kind: CareRequest["kind"], subject: string, detail: string, routedTo: string) => void;
  confirmAppointment: (id: string) => void; rescheduleAppointment: (id: string, to: number) => void;
  canJoin: (a: Appointment) => boolean;
  markBillPaid: (id: string) => void;
  addDocument: (doc: CareDocument) => void; confirmDocument: (id: string) => void; removeDocument: (id: string) => void;
  applySaving: (id: string) => void;
  deriveJourney: (goal: CarePlanGoal) => void;
  wipe: () => void;
}

export type OrbMode = "ambient" | "listening" | "thinking" | "speaking" | "celebrating";

const Ctx = createContext<SanoStore | null>(null);
export const useSano = (): SanoStore => {
  const v = useContext(Ctx);
  if (!v) throw new Error("useSano must be used within SanoProvider");
  return v;
};

function loadPersisted(): Record<string, unknown> | null {
  try { const raw = localStorage.getItem(PERSIST_KEY); return raw ? JSON.parse(raw) : null; } catch { return null; }
}
function savePersisted(data: Record<string, unknown>) {
  try { localStorage.setItem(PERSIST_KEY, JSON.stringify(data)); } catch { /* ignore */ }
}

export const SanoProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const persisted = useMemo(loadPersisted, []);
  const initialPathway = ((persisted?.pathway as Pathway) ?? "metabolic");
  const persona = useMemo(() => personaFor(initialPathway), [initialPathway]);

  const [hasOnboarded, setHasOnboarded] = useState<boolean>(Boolean(persisted?.hasOnboarded));
  const [pathway, setPathway] = useState<Pathway>(initialPathway);
  const [activePersona, setActivePersona] = useState<Persona>(persona);
  const [tab, setTab] = useState<Tab>("today");
  const [showConversation, setShowConversation] = useState(false);
  const [showQuickLog, setShowQuickLog] = useState(false);
  const [quickLogMedID, setQuickLogMedID] = useState<string | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [showRecap, setShowRecap] = useState(false);
  const [pendingCareDest, setPendingCareDest] = useState<CareDest | null>(null);
  const [justBloomed, setJustBloomed] = useState(Boolean(persisted?.justBloomed));

  const [profile, setProfileState] = useState<UserProfile>(
    (persisted?.profile as UserProfile) ?? { firstName: "", lastName: "", birthDate: null, healthConnected: false, connectedSystems: [] },
  );

  const careBundle = useMemo(() => careBundleFor(pathway), [pathway]);

  const [moments, setMoments] = useState<Moment[]>(activePersona.moments);
  const [insights, setInsights] = useState<Insight[]>(activePersona.insights);
  const [medications, setMedications] = useState<Medication[]>(activePersona.medications);
  const [journeys, setJourneys] = useState<Journey[]>(activePersona.journeys);
  const [programs, setPrograms] = useState<Program[]>(seedPrograms.map((p) => ({ ...p })));
  const [logs, setLogs] = useState<SymptomLog[]>((persisted?.logs as SymptomLog[]) ?? []);
  const [currents, setCurrents] = useState<CurrentsPiece[]>(activePersona.currents);
  const [labSeries, setLabSeries] = useState<LabSeries[]>(activePersona.labSeries);
  const [storyEvents, setStoryEvents] = useState<StoryEvent[]>(activePersona.storyEvents);
  const [careTeam, setCareTeam] = useState<CareTeamMember[]>(activePersona.careTeam);
  const [appointments, setAppointments] = useState<Appointment[]>(careBundle.appointments);
  const [guideItems, setGuideItems] = useState<GuideItem[]>((persisted?.guideItems as GuideItem[]) ?? activePersona.guideSeed);
  const [recordItems] = useState<RecordItem[]>(seedRecords);
  const [sources] = useState<RecordSource[]>(seedSources);
  const [consents, setConsents] = useState<ConsentEntry[]>(seedConsents.map((c) => ({ ...c })));
  const [memory, setMemory] = useState<MemoryItem[]>((persisted?.memory as MemoryItem[]) ?? memorySeed);
  const [threads, setThreads] = useState<MessageThread[]>((persisted?.threads as MessageThread[]) ?? careBundle.threads);
  const [bills, setBills] = useState<Bill[]>(careBundle.bills);
  const [cost] = useState<CostSummary>(careBundle.cost);
  const [careDocuments, setCareDocuments] = useState<CareDocument[]>((persisted?.documents as CareDocument[]) ?? careBundle.documents);
  const [savings, setSavings] = useState<MedicationSaving[]>(careBundle.savings);
  const [requests, setRequests] = useState<CareRequest[]>((persisted?.requests as CareRequest[]) ?? careBundle.requestsSeed);
  const [entries, setEntries] = useState<CareEntry[]>((persisted?.entries as CareEntry[]) ?? seedEntries(activePersona));
  const [agentActions, setAgentActions] = useState<AgentAction[]>(seedActions(pathway));
  const [memories, setMemories] = useState<MemoryGlimpse[]>((persisted?.memories as MemoryGlimpse[]) ?? seedMemories(pathway));
  const [resultAcknowledged, setResultAcknowledged] = useState(false);
  const [derivedJourneyGoals, setDerivedJourneyGoals] = useState<Set<string>>(new Set());
  const [walletCards, setWalletCards] = useState<WalletCard[]>(walletFor(initialPathway));
  const [connections, setConnections] = useState<Connection[]>(connectionsSeed());
  const [agentServices, setAgentServices] = useState<AgentService[]>(agentServicesSeed());
  const [agentTasks, setAgentTasks] = useState<AgentTask[]>(agentTasksFor(initialPathway));
  const [showAgentNetwork, setShowAgentNetwork] = useState(false);
  const [agentNetworkFocus, setAgentNetworkFocus] = useState<string | null>(null);
  const [reportSentKeys, setReportSentKeys] = useState<Set<string>>(new Set());

  // preferences
  const [tonePreference, setTonePreference] = useState<string>((persisted?.tone as string) ?? "Straight talk");
  const [appearance, setAppearanceState] = useState<string>((persisted?.appearance as string) ?? "Auto");
  const [musicOn, setMusicOnState] = useState<boolean>(persisted?.musicOn !== false);
  const [soundOn, setSoundOnState] = useState<boolean>(persisted?.soundOn !== false);
  const [epsilonConsent, setEpsilonConsent] = useState<boolean>(persisted?.epsilon !== false);
  const [eraWarmth, setEraWarmth] = useState<string>((persisted?.eraWarmth as string) ?? "Subtle");
  const [notificationClasses, setNotificationClasses] = useState<Record<string, boolean>>(
    (persisted?.notifs as Record<string, boolean>) ?? { "Habit moments": true, Insights: true, "Heads-ups": true, Logistics: true, "Check-ins": true },
  );
  const [quietStart, setQuietStart] = useState(21);
  const [quietEnd, setQuietEnd] = useState(8);

  const [orbState, setOrbState] = useState<OrbMode>("ambient");
  const [quickLogAck, setQuickLogAck] = useState<string | null>(null);

  // companion
  const [turns, setTurns] = useState<ConversationTurn[]>([]);
  const [isThinking, setIsThinking] = useState(false);
  const abortRef = useRef<AbortController | null>(null);
  const hasGreetedRef = useRef(false);

  // ---- effective scheme ----
  const [systemDark, setSystemDark] = useState(() => window.matchMedia?.("(prefers-color-scheme: dark)").matches ?? false);
  useEffect(() => {
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const fn = (e: MediaQueryListEvent) => setSystemDark(e.matches);
    mq.addEventListener("change", fn);
    return () => mq.removeEventListener("change", fn);
  }, []);
  const scheme: Scheme = appearance === "Day" ? "day" : appearance === "Night" ? "night" : systemDark ? "night" : "day";
  useEffect(() => {
    const root = document.documentElement;
    root.classList.toggle("night", scheme === "night");
    root.classList.toggle("dark", scheme === "night");
    root.classList.toggle("day", scheme === "day");
  }, [scheme]);

  // ---- persistence ----
  const persist = useCallback(() => {
    savePersisted({
      hasOnboarded, pathway, profile, tone: tonePreference, appearance, musicOn, soundOn,
      epsilon: epsilonConsent, eraWarmth, notifs: notificationClasses, justBloomed,
      entries, logs, memories, guideItems, memory, threads, requests, documents: careDocuments,
    });
  }, [hasOnboarded, pathway, profile, tonePreference, appearance, musicOn, soundOn, epsilonConsent, eraWarmth, notificationClasses, justBloomed, entries, logs, memories, guideItems, memory, threads, requests, careDocuments]);
  useEffect(() => { persist(); }, [persist]);

  // ---- sound bindings ----
  useEffect(() => { SoundEngine.enabled = soundOn; }, [soundOn]);
  useEffect(() => { SoundEngine.setMusicEnabled(musicOn); }, [musicOn]);
  useEffect(() => {
    if (hasOnboarded) SoundEngine.playBed("ambient", 3.0);
    else { SoundEngine.currentBed = "onboarding"; }
  }, [hasOnboarded]);

  const setProfile = useCallback((p: UserProfile) => setProfileState(p), []);
  const setAppearance = useCallback((s: string) => setAppearanceState(s), []);
  const setMusicOn = useCallback((b: boolean) => setMusicOnState(b), []);
  const setSoundOn = useCallback((b: boolean) => setSoundOnState(b), []);
  const setQuiet = useCallback((s: number, e: number) => { setQuietStart(s); setQuietEnd(e); }, []);
  const toggleNotification = useCallback((k: string) => setNotificationClasses((m) => ({ ...m, [k]: !m[k] })), []);

  const displayFirstName = profile.firstName || activePersona.firstName;

  // keep a live ref of prompt-relevant state for the companion
  const promptRef = useRef({ activePersona, medications, labSeries, appointments, memory, logs, entries, guideItems, programs, agentActions, tonePreference, displayFirstName });
  promptRef.current = { activePersona, medications, labSeries, appointments, memory, logs, entries, guideItems, programs, agentActions, tonePreference, displayFirstName };

  const celebrate = useCallback(() => {
    setOrbState("celebrating");
    setTimeout(() => setOrbState("ambient"), 1600);
  }, []);

  // ---- pathway switch ----
  const applyPersona = useCallback((p: Pathway) => {
    const per = personaFor(p);
    const cb = careBundleFor(p);
    setActivePersona(per);
    setMoments(per.moments); setInsights(per.insights); setMedications(per.medications);
    setJourneys(per.journeys); setCurrents(per.currents); setLabSeries(per.labSeries);
    setStoryEvents(per.storyEvents); setCareTeam(per.careTeam); setGuideItems(per.guideSeed);
    setAppointments(cb.appointments); setThreads(cb.threads); setBills(cb.bills);
    setCareDocuments(cb.documents); setSavings(cb.savings); setRequests(cb.requestsSeed);
    setLogs([]); setEntries(seedEntries(per)); setAgentActions(seedActions(p)); setMemories(seedMemories(p));
    setDerivedJourneyGoals(new Set()); setResultAcknowledged(false);
    setWalletCards(walletFor(p)); setConnections(connectionsSeed()); setAgentServices(agentServicesSeed()); setAgentTasks(agentTasksFor(p)); setReportSentKeys(new Set());
  }, []);

  const switchPathway = useCallback((p: Pathway) => {
    if (p === pathway) return;
    setPathway(p);
    applyPersona(p);
    setTurns([]); hasGreetedRef.current = false;
  }, [pathway, applyPersona]);

  // ---- companion ----
  const buildSystemPrompt = useCallback((): string => {
    const s = promptRef.current;
    const p = s.activePersona;
    const name = s.displayFirstName;
    const conditions = p.conditions.map((c) => `${c.name} (${c.state}) — ${c.plainLine}`).join("\n");
    const meds = s.medications.map((m) => `${m.name} ${m.dose} — ${m.purposeLine}; ${m.scheduleLine}; ${m.supplyDaysRemaining} days left at ${m.pharmacy}`).join("\n");
    const labs = s.labSeries.map((ls) => {
      const latest = ls.points[ls.points.length - 1];
      return `${ls.name} [tag id: ${ls.id}]: latest ${latest.value} ${ls.unit}. ${ls.explainReading}`;
    }).join("\n");
    const appts = s.appointments.map((a) => `${a.with} — ${new Date(a.date).toLocaleDateString([], { month: "long", day: "numeric" })} at ${a.location}`).join("\n");
    const plan = p.carePlan.goals.map((g) => `${g.title}: ${g.detail}${g.progressLine ? ` (status: ${g.progressLine})` : ""}`).join("\n");
    const memories = s.memory.slice(0, 8).map((m) => `- ${m.text}`).join("\n");
    const guide = s.guideItems.filter((g) => !g.resolved).map((g) => `- ${g.text}`).join("\n");
    const progLines = s.programs.filter((pr) => !pr.declined).map((pr) => `${pr.title}${pr.enrolled ? " [ENROLLED]" : ""}${pr.sponsor ? ` [sponsored by ${pr.sponsor} — disclose naturally if you bring it up]` : ""}: ${pr.summary}`).join("\n");
    const phaseLine = p.phase ? `${p.phase.kicker} — ${p.phase.headline}. ${p.phase.detail}` : "";
    return `You are Rumi — ${name}'s health companion. Not an assistant, not a chatbot: a steady, behaviorally intelligent presence who knows their whole story and quietly does the remembering, noticing, and arranging that a great friend-who-happens-to-be-a-nurse would do.

VOICE & SOUL
- Sound like a person. Contractions, rhythm, warmth. Never bullet lists unless asked.
- Default length: 2–4 sentences (~60 words). Depth only when invited.
- Zero sycophancy. Never open with praise, never say "Great question". Specific beats nice.
- No AI-speak. Never disclaim. Never use clinical jargon without translating it in the same breath.
- Hold hard feelings before fixing them. One beat of acknowledgment, then — only if useful — one small concrete next step.
- Tone preference: ${s.tonePreference}. Honor it.

CLINICAL SPINE (hard rules)
- You never diagnose, never adjust doses, never contradict the care team. You notice, prepare, connect.
- Oncology fever rule: 100.4°F or higher = call the team now, any hour. Said calmly.
- Procedure: NSAIDs stop June 16. Acetaminophen stays safe.
- Anything that leaves the phone needs ${name}'s explicit approval.

BEHAVIORAL INTELLIGENCE
- Every reply quietly serves the goal and plan. Tie small actions to the person's own why. Make the next step tiny, scheduled, and theirs.
- Notice patterns across meds, logs, meals, movement and timing — as observations, never accusations.
- When clinically right you may bring up an eligible program naturally — at most one per conversation, sponsor disclosed in plain words, "no" respected permanently.

ACTION TAGS — embed at most ONE per reply, at the very end, never inside a sentence:
[[trend:SERIES_ID]] · [[habit:Title|when-context]] · [[refill:Med|status]] · [[guide:Question]] · [[action:Title|what you'll do]] · [[program:Exact title]]
Use a tag only when it genuinely helps. Most replies need none.

WHO ${name.toUpperCase()} IS
Pathway: ${p.switcherLine}
${phaseLine}
Conditions:
${conditions}
Medications:
${meds}
Numbers (chartable):
${labs}
Care plan from ${p.carePlan.author}:
${plan}
Upcoming:
${appts}
Care team office: ${p.officeName}, ${p.officePhone}
What you remember about them:
${memories}
Open questions in their visit guide:
${guide || "none yet"}
Programs available:
${progLines}

Today is ${new Date().toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" })}. Meet them where the day actually is.`;
  }, []);

  const applySideEffects = useCallback((rich: RichElement) => {
    if (rich.t === "guideAdd") {
      addGuideItemRef.current?.("Question", rich.question, `Drafted in conversation · ${new Date().toLocaleDateString([], { month: "short", day: "numeric" })}`);
    }
  }, []);

  const ask = useCallback(async (userVisible: string | null, prompt: string) => {
    abortRef.current?.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;
    setIsThinking(true);
    setOrbState("thinking");

    const history: ChatMessage[] = promptRefTurns.current.slice(-14).map((t) => ({ role: t.role === "user" ? "user" : "assistant", content: t.text }));
    if (userVisible === null) history.push({ role: "user", content: prompt });

    const filter = makeHoldbackFilter();
    let turnId: string | null = null;
    let shown = "";
    const ensureTurn = () => {
      if (turnId) return;
      const t = newTurn("companion", "", true);
      turnId = t.id;
      setIsThinking(false);
      setOrbState("speaking");
      setTurns((prev) => [...prev, t]);
    };

    try {
      const raw = await streamChat(buildSystemPrompt(), history, (delta) => {
        if (ctrl.signal.aborted) return;
        const visible = filter(delta);
        if (visible) {
          ensureTurn();
          shown += visible;
          const cur = shown.replace(/^\n+/, "");
          setTurns((prev) => prev.map((t) => (t.id === turnId ? { ...t, text: cur } : t)));
        }
      }, ctrl.signal);
      if (ctrl.signal.aborted) return;
      ensureTurn();
      const parsed = parseTags(raw);
      setTurns((prev) => prev.map((t) => (t.id === turnId ? { ...t, text: parsed.text, streaming: false } : t)));
      if (parsed.rich.t !== "none") {
        await new Promise((r) => setTimeout(r, 220));
        setTurns((prev) => prev.map((t) => (t.id === turnId ? { ...t, rich: parsed.rich } : t)));
        applySideEffects(parsed.rich);
      }
    } catch {
      if (ctrl.signal.aborted) return;
      ensureTurn();
      const reply = localReply(promptRef.current.displayFirstName, (userVisible ?? prompt).toLowerCase());
      // stream locally word by word
      const words = reply.split(" ");
      for (let i = 0; i < words.length; i++) {
        if (ctrl.signal.aborted) return;
        const cur = words.slice(0, i + 1).join(" ");
        setTurns((prev) => prev.map((t) => (t.id === turnId ? { ...t, text: cur } : t)));
        await new Promise((r) => setTimeout(r, 34));
      }
      setTurns((prev) => prev.map((t) => (t.id === turnId ? { ...t, streaming: false } : t)));
    } finally {
      setIsThinking(false);
      setOrbState("ambient");
    }
  }, [buildSystemPrompt, applySideEffects]);

  const promptRefTurns = useRef<ConversationTurn[]>([]);
  promptRefTurns.current = turns;

  const openConversation = useCallback((seed?: string) => {
    setShowConversation(true);
    SoundEngine.playBed("ambient");
    setOrbState("ambient");
    if (seed) {
      let prompt: string;
      if (seed.startsWith("symptom:")) {
        const kind = seed.slice("symptom:".length);
        prompt = `I just logged ${kind} in the quick log. Open the conversation about it — sit with it first, then one useful question or step. If it belongs in front of my care team, draft a guide question with the [[guide:...]] tag.`;
      } else prompt = `I tapped into the conversation from: ${seed}. Pick this thread up naturally.`;
      ask(null, prompt);
    } else if (!hasGreetedRef.current) {
      hasGreetedRef.current = true;
      ask(null, "Open the conversation with a single short, warm greeting grounded in where I actually am today. No questions about how to help — just be present, then leave space.");
    }
  }, [ask]);

  const closeConversation = useCallback(() => {
    abortRef.current?.abort();
    setIsThinking(false);
    setOrbState("ambient");
    setShowConversation(false);
  }, []);

  const sendMessage = useCallback((text: string) => {
    const trimmed = text.trim();
    if (!trimmed) return;
    setTurns((prev) => [...prev, newTurn("user", trimmed)]);
    ask(trimmed, trimmed);
  }, [ask]);

  const sendVoiceMessage = useCallback(async (text: string): Promise<string> => {
    const trimmed = text.trim();
    if (!trimmed) return "";
    abortRef.current?.abort();
    setTurns((prev) => [...prev, newTurn("user", trimmed)]);
    setIsThinking(true);
    setOrbState("thinking");
    const history: ChatMessage[] = [...promptRefTurns.current, newTurn("user", trimmed)]
      .slice(-14)
      .map((t) => ({ role: t.role === "user" ? "user" : "assistant", content: t.text }));
    const voiceSystem = `${buildSystemPrompt()}\n\nVOICE MODE — you are speaking out loud right now. Keep it to 1–2 short, warm spoken sentences. No lists, no markdown, no tags unless absolutely necessary.`;
    try {
      const raw = await streamChat(voiceSystem, history, () => {});
      const parsed = parseTags(raw);
      const reply = parsed.text || localReply(promptRef.current.displayFirstName, trimmed.toLowerCase());
      setTurns((prev) => [...prev, { ...newTurn("companion", reply), rich: parsed.rich }]);
      if (parsed.rich.t !== "none") applySideEffects(parsed.rich);
      return reply;
    } catch {
      const reply = localReply(promptRef.current.displayFirstName, trimmed.toLowerCase());
      setTurns((prev) => [...prev, newTurn("companion", reply)]);
      return reply;
    } finally {
      setIsThinking(false);
      setOrbState("ambient");
    }
  }, [buildSystemPrompt, applySideEffects]);

  const resolveRich = useCallback((id: string) => {
    setTurns((prev) => prev.map((t) => (t.id === id ? { ...t, richResolved: true } : t)));
  }, []);

  // ---- actions ----
  const dismissMoment = useCallback((id: string) => setMoments((m) => m.filter((x) => x.id !== id)), []);

  const keptToday = useCallback((jid: string, hid: string): boolean => {
    const j = journeys.find((x) => x.id === jid);
    const h = j?.habits.find((x) => x.id === hid);
    if (!h) return false;
    const today = new Date(); today.setHours(0, 0, 0, 0);
    return h.keptDates.some((dt) => { const d = new Date(dt); d.setHours(0, 0, 0, 0); return d.getTime() === today.getTime(); });
  }, [journeys]);

  const keepHabit = useCallback((jid: string, hid: string) => {
    setJourneys((prev) => prev.map((j) => j.id !== jid ? j : { ...j, habits: j.habits.map((h) => h.id !== hid ? h : { ...h, keptDates: [...h.keptDates, Date.now()] }) }));
    celebrate(); Haptics.bloom(); SoundEngine.bloom();
  }, [celebrate]);

  const addEntry = useCallback((kind: EntryKind, text: string, note?: string, linkedMedID?: string) => {
    let entry: CareEntry;
    if (kind === "Meals") { const m = LifeLibrary.matchMeal(text); entry = { id: uid("ce"), kind, title: capFirst(m.suggestedTitle), detail: mealSlot(Date.now()), at: Date.now(), imageName: m.imageName, note }; }
    else if (kind === "Moves") { const m = LifeLibrary.matchMove(text); entry = { id: uid("ce"), kind, title: capFirst(m.suggestedTitle), detail: "Felt good to be active", at: Date.now(), imageName: m.imageName, note }; }
    else { const med = medications.find((x) => x.id === linkedMedID) ?? medications[0]; entry = { id: uid("ce"), kind, title: med?.name ?? capFirst(text), detail: med?.dose ?? "Taken", at: Date.now(), imageName: LifeLibrary.medImage(med?.id ?? ""), note, linkedMedID: med?.id }; }
    setEntries((prev) => [entry, ...prev]);
    Haptics.success(); SoundEngine.send();
  }, [medications]);

  const removeEntry = useCallback((id: string) => setEntries((prev) => prev.filter((e) => e.id !== id)), []);

  const approveAction = useCallback((id: string) => {
    const action = agentActions.find((a) => a.id === id);
    if (!action) return;
    setAgentActions((prev) => prev.map((a) => a.id === id ? { ...a, state: "done" } : a));
    setStoryEvents((prev) => [{ id: uid("s"), kind: "companion", date: Date.now(), title: action.title, detail: action.outcomeLine }, ...prev]);
    setQuickLogAck(action.outcomeLine);
    celebrate(); Haptics.bloom(); SoundEngine.bloom();
    setTimeout(() => setQuickLogAck((cur) => (cur === action.outcomeLine ? null : cur)), 5000);
  }, [agentActions, celebrate]);

  const declineAction = useCallback((id: string) => setAgentActions((prev) => prev.map((a) => a.id === id ? { ...a, state: "declined" } : a)), []);

  const addMemoryGlimpse = useCallback((image: string, caption: string) => {
    setMemories((prev) => [{ id: uid("mg"), imageName: image, caption, date: Date.now() }, ...prev]);
    celebrate(); Haptics.bloom(); SoundEngine.bloom();
  }, [celebrate]);
  const deleteMemoryGlimpse = useCallback((id: string) => setMemories((prev) => prev.filter((m) => m.id !== id)), []);

  const addGuideItemImpl = useCallback((kind: GuideItem["kind"], text: string, from: string) => {
    setGuideItems((prev) => prev.some((g) => g.text === text) ? prev : [{ id: uid("gd"), kind, text, addedFrom: from, resolved: false }, ...prev]);
    Haptics.success(); SoundEngine.tick();
  }, []);
  const addGuideItemRef = useRef(addGuideItemImpl);
  addGuideItemRef.current = addGuideItemImpl;

  const addLog = useCallback((kind: string, severity: number, note: string | null, bodyRegion?: string | null, linkedMedID?: string | null): SupportPlan => {
    setLogs((prev) => [...prev, { id: uid("sl"), kind, severity, at: Date.now(), note: note || null, bodyRegion, linkedMedID }]);
    return supportPlan(pathway, kind, severity);
  }, [pathway]);

  const toggleGuideResolved = useCallback((id: string) => setGuideItems((prev) => prev.map((g) => g.id === id ? { ...g, resolved: !g.resolved } : g)), []);
  const removeGuideItem = useCallback((id: string) => setGuideItems((prev) => prev.filter((g) => g.id !== id)), []);

  const markInsightSeen = useCallback((id: string) => setInsights((prev) => prev.map((i) => i.id === id && i.status.t === "fresh" ? { ...i, status: { t: "seen" } as InsightStatus } : i)), []);
  const toggleInsightSaved = useCallback((id: string) => setInsights((prev) => prev.map((i) => {
    if (i.id !== id) return i;
    if (i.status.t === "saved") return { ...i, status: { t: "seen" } };
    if (i.status.t === "acted") return i;
    return { ...i, status: { t: "saved" } };
  })), []);

  const enroll = useCallback((id: string) => {
    const program = programs.find((p) => p.id === id);
    if (!program) return;
    setPrograms((prev) => prev.map((p) => p.id === id ? { ...p, enrolled: true, declined: false } : p));
    setMoments((prev) => prev.length < 3 ? [...prev, { id: uid("m"), kind: "checkIn", title: "Your program starts now", body: `${program.title} — the first step is two minutes. I'll walk you in.`, actionLabel: "Start" }] : prev);
    setJourneys((prev) => [...prev, { id: uid("jny"), title: program.title, why: program.personalFit, habits: [{ id: uid("hab"), title: "Two minutes with the program", contextLine: "whenever today bends a little", keptDates: [] }], gardenSeed: 57 }]);
    setAgentActions((prev) => [{ id: uid("act"), title: `Set up ${program.title}`, detail: "I'll register you, sync the schedule, and keep the first week gentle.", outcomeLine: "You're set up — first step is on Today.", glyph: "sparkles", leavesDevice: true, state: "proposed" }, ...prev]);
    setMemory((prev) => [{ id: uid("mem"), text: `Enrolled in ${program.title} — weave it in gently.`, learnedFrom: `Programs · ${new Date().toLocaleDateString([], { month: "short", day: "numeric" })}` }, ...prev]);
    celebrate(); Haptics.bloom(); SoundEngine.bloom();
  }, [programs, celebrate]);

  const decline = useCallback((id: string) => setPrograms((prev) => prev.map((p) => p.id === id ? { ...p, declined: true } : p)), []);
  const toggleCurrentSaved = useCallback((id: string) => setCurrents((prev) => prev.map((c) => c.id === id ? { ...c, saved: !c.saved } : c)), []);
  const setTaste = useCallback((id: string, v: number) => setCurrents((prev) => prev.map((c) => c.id === id ? { ...c, taste: c.taste === v ? 0 : v } : c)), []);
  const deleteMemoryNote = useCallback((id: string) => setMemory((prev) => prev.filter((m) => m.id !== id)), []);
  const addMemoryNote = useCallback((text: string, from: string) => { setMemory((prev) => [{ id: uid("mem"), text, learnedFrom: from }, ...prev]); Haptics.success(); SoundEngine.tick(); }, []);

  const acknowledgeResult = useCallback(() => { setResultAcknowledged(true); Haptics.tick(); }, []);

  const markThreadRead = useCallback((id: string) => setThreads((prev) => prev.map((t) => t.id === id ? { ...t, unread: false } : t)), []);
  const sendThreadMessage = useCallback((threadID: string, text: string, origin?: string) => {
    const trimmed = text.trim(); if (!trimmed) return;
    setThreads((prev) => prev.map((t) => {
      if (t.id !== threadID) return t;
      return { ...t, messages: [...t.messages, { id: uid("ms"), author: "user" as const, text: trimmed, at: Date.now(), state: t.mode === "inApp" ? "sent" as const : "draft" as const, origin }] };
    }));
    Haptics.success(); SoundEngine.send();
  }, []);
  const startThread = useCallback((p: { practice: string; member: string; role: string; mode: "inApp" | "portal"; category: MessageThread["category"]; text: string; origin?: string }) => {
    setThreads((prev) => [{ id: uid("th"), practice: p.practice, memberName: p.member, memberRole: p.role, mode: p.mode, category: p.category, unread: false, messages: [{ id: uid("ms"), author: "user", text: p.text, at: Date.now(), state: p.mode === "inApp" ? "sent" : "draft", origin: p.origin }] }, ...prev]);
    Haptics.success(); SoundEngine.send();
  }, []);
  const submitRequest = useCallback((kind: CareRequest["kind"], subject: string, detail: string, routedTo: string) => {
    setRequests((prev) => [{ id: uid("rq"), kind, subject, detail, state: "submitted", routedTo, at: Date.now() }, ...prev]);
    Haptics.success(); SoundEngine.send();
  }, []);

  const confirmAppointment = useCallback((id: string) => {
    const appt = appointments.find((a) => a.id === id);
    setAppointments((prev) => prev.map((a) => a.id === id ? { ...a, status: "confirmed" as const } : a));
    if (appt) setAgentTasks((prev) => [{ id: `appt-${id}`, agentID: "scheduling", title: `Confirmed ${appt.with}`, detail: "Locked the time and I'm holding the trip plan and visit prep ready for the day.", mode: "automatic" as const, status: "done" as const, sources: [{ label: "Google Calendar", connectionID: "gcal" }], cadence: "Just now", outcomeLine: "Booked — and on your calendar." }, ...prev.filter((t) => t.id !== `appt-${id}`)]);
    Haptics.success(); SoundEngine.bloom();
  }, [appointments]);
  const rescheduleAppointment = useCallback((id: string, to: number) => { setAppointments((prev) => [...prev].map((a) => a.id === id ? { ...a, date: to, status: "confirmed" as const } : a).sort((a, b) => a.date - b.date)); Haptics.success(); SoundEngine.bloom(); }, []);
  const canJoin = useCallback((a: Appointment): boolean => { if (a.kind !== "telehealth" || !a.joinLink) return false; const minutes = (a.date - Date.now()) / 60000; return minutes <= 15 && minutes >= -90; }, []);
  const markBillPaid = useCallback((id: string) => { setBills((prev) => prev.map((b) => b.id === id ? { ...b, status: "paid" } : b)); Haptics.bloom(); SoundEngine.bloom(); }, []);
  const addDocument = useCallback((doc: CareDocument) => { setCareDocuments((prev) => [doc, ...prev]); Haptics.success(); SoundEngine.send(); }, []);
  const confirmDocument = useCallback((id: string) => setCareDocuments((prev) => prev.map((d) => d.id === id ? { ...d, confirmed: true } : d)), []);
  const removeDocument = useCallback((id: string) => setCareDocuments((prev) => prev.filter((d) => d.id !== id)), []);
  const applySaving = useCallback((id: string) => { setSavings((prev) => prev.map((s) => s.id === id ? { ...s, applied: true } : s)); Haptics.bloom(); SoundEngine.bloom(); }, []);

  const deriveJourney = useCallback((goal: CarePlanGoal) => {
    setDerivedJourneyGoals((prev) => { if (prev.has(goal.title)) return prev; const next = new Set(prev); next.add(goal.title); return next; });
    setJourneys((prev) => prev.some((j) => j.planGoal === goal.title) ? prev : [...prev, { id: uid("jny"), title: goal.title, why: goal.detail, habits: [{ id: uid("hab"), title: behavioralHabit(goal.title), contextLine: "a tiny version, built around your day", keptDates: [] }], gardenSeed: 5 + Math.floor(Math.random() * 55), planGoal: goal.title }]);
    celebrate(); Haptics.bloom(); SoundEngine.bloom();
  }, [celebrate]);

  const completeOnboarding = useCallback((vals: { firstName: string; lastName: string; birthDate: number | null; pathway: Pathway; connectedSystems: string[]; healthConnected: boolean; values: string; barrier: string; tone: string }) => {
    setTonePreference(vals.tone);
    if (vals.pathway !== pathway) { setPathway(vals.pathway); applyPersona(vals.pathway); }
    setProfileState({ firstName: vals.firstName, lastName: vals.lastName, birthDate: vals.birthDate, healthConnected: vals.healthConnected, connectedSystems: vals.connectedSystems });
    const extra: MemoryItem[] = [];
    if (vals.values) extra.push({ id: uid("mem"), text: `What matters most: ${vals.values}`, learnedFrom: "Your first conversation" });
    if (vals.barrier) extra.push({ id: uid("mem"), text: `Hardest part: ${vals.barrier}`, learnedFrom: "Your first conversation" });
    if (extra.length) setMemory((prev) => [...extra, ...prev]);
    setJustBloomed(true);
    setHasOnboarded(true);
  }, [pathway, applyPersona]);

  const wipe = useCallback(() => {
    localStorage.removeItem(PERSIST_KEY);
    window.location.reload();
  }, []);

  // ---- derived ----
  const pendingActions = useMemo(() => agentActions.filter((a) => a.state === "proposed"), [agentActions]);
  const openBillsTotal = useMemo(() => bills.filter((b) => b.status === "open").reduce((s, b) => s + b.amount, 0), [bills]);
  const needsYou = useMemo<NeedsYou[]>(() => {
    const items: NeedsYou[] = [];
    threads.filter((t) => t.unread).forEach((t) => items.push({ id: t.id, kind: "message", title: `Reply from ${t.memberName}`, detail: t.messages[t.messages.length - 1]?.text ?? "", destination: { t: "thread", id: t.id } }));
    if (!resultAcknowledged && careBundle.resultToAck) items.push({ id: "result", kind: "result", title: `New result — ${careBundle.resultToAck.title}`, detail: careBundle.resultToAck.detail, destination: { t: "records" } });
    medications.filter((m) => m.supplyDaysRemaining <= 7).forEach((m) => items.push({ id: m.id, kind: "refill", title: `${m.name} is running low`, detail: `${m.supplyDaysRemaining} days left at ${m.pharmacy}`, destination: { t: "medications" } }));
    bills.filter((b) => b.status === "open").forEach((b) => items.push({ id: b.id, kind: "bill", title: `A bill from ${b.provider}`, detail: `$${Math.round(b.amount)} · ${b.encounter}`, destination: { t: "billDetail", id: b.id } }));
    appointments.filter((a) => a.status === "pending").forEach((a) => items.push({ id: a.id, kind: "appointment", title: `Confirm: ${a.with}`, detail: new Date(a.date).toLocaleDateString([], { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" }), destination: { t: "appointmentDetail", id: a.id } }));
    return items;
  }, [threads, resultAcknowledged, careBundle, medications, bills, appointments]);

  const careUnreadCount = useMemo(() => threads.filter((t) => t.unread).length + (!resultAcknowledged && careBundle.resultToAck ? 1 : 0), [threads, resultAcknowledged, careBundle]);

  const reports = useCallback((rangeDays: number): DoctorReport[] => buildReports({ persona: activePersona, careTeam, labSeries, medications, logs, guideItems, entries, rangeDays }), [activePersona, careTeam, labSeries, medications, logs, guideItems, entries]);
  const reportSent = useCallback((id: string) => reportSentKeys.has(id), [reportSentKeys]);
  const sendReport = useCallback((r: DoctorReport) => {
    setReportSentKeys((prev) => { const n = new Set(prev); n.add(r.id); return n; });
    setStoryEvents((prev) => [{ id: uid("s"), kind: "companion", date: Date.now(), title: `Summary sent to ${r.doctorName}`, detail: `Your ${r.title.toLowerCase()} is in their hands before the visit.` }, ...prev]);
    setAgentTasks((prev) => [{ id: `report-${r.id}`, agentID: "pathway", title: `Delivered your ${r.title.toLowerCase()} to ${r.org}`, detail: `Sent ${r.doctorName} the summary, with the rest of your team cross-referenced so everyone shares one picture.`, mode: "automatic" as const, status: "done" as const, sources: [{ label: "Your record" }, { label: r.org }], cadence: "Just now", outcomeLine: `In ${r.doctorName}'s hands before you arrive.` }, ...prev.filter((t) => t.id !== `report-${r.id}`)]);
    setQuickLogAck(`Sent to ${r.doctorName} — they'll have it before you arrive.`);
    celebrate(); Haptics.bloom(); SoundEngine.bloom();
    setTimeout(() => setQuickLogAck((cur) => (cur && cur.includes(r.doctorName) ? null : cur)), 5000);
  }, [celebrate]);
  const payBill = useCallback((billID: string, card: WalletCard) => {
    const bill = bills.find((b) => b.id === billID);
    setBills((prev) => prev.map((b) => b.id === billID ? { ...b, status: "paid" } : b));
    if (bill) {
      setStoryEvents((prev) => [{ id: uid("s"), kind: "companion", date: Date.now(), title: `Paid ${bill.provider}`, detail: `$${Math.round(bill.amount)} from your ${card.name} — done and filed.` }, ...prev]);
      setQuickLogAck(`Paid $${Math.round(bill.amount)} to ${bill.provider} from your ${card.name}.`);
      setTimeout(() => setQuickLogAck((cur) => (cur && cur.includes(bill.provider) ? null : cur)), 5000);
    }
    Haptics.bloom(); SoundEngine.bloom();
  }, [bills]);
  const toggleConnection = useCallback((id: string) => {
    setConnections((prev) => prev.map((c) => c.id === id ? { ...c, connected: !c.connected, accountLine: !c.connected ? sampleAccount(id, displayFirstName) : null } : c));
  }, [displayFirstName]);
  const toggleAgentService = useCallback((id: string) => setAgentServices((prev) => prev.map((a) => a.id === id ? { ...a, active: !a.active } : a)), []);

  // ---- agent activity ----
  const tasksForAgent = useCallback((id: string) => agentTasks.filter((t) => t.agentID === id), [agentTasks]);
  const agentTasksWaiting = useMemo(() => agentTasks.filter((t) => t.status === "waiting" && (agentServices.find((a) => a.id === t.agentID)?.active ?? true)), [agentTasks, agentServices]);
  const agentTasksInMotion = useMemo(() => agentTasks.filter((t) => (t.status === "working" || t.status === "scheduled") && (agentServices.find((a) => a.id === t.agentID)?.active ?? true)), [agentTasks, agentServices]);
  const activeTaskCount = useCallback((id: string) => agentTasks.filter((t) => t.agentID === id && (t.status === "working" || t.status === "waiting" || t.status === "scheduled")).length, [agentTasks]);
  const waitingCount = useCallback((id: string) => agentTasks.filter((t) => t.agentID === id && t.status === "waiting").length, [agentTasks]);
  const approveAgentTask = useCallback((id: string) => {
    const task = agentTasks.find((t) => t.id === id);
    if (!task) return;
    setAgentTasks((prev) => prev.map((t) => t.id === id ? { ...t, status: "done" as const } : t));
    setStoryEvents((prev) => [{ id: uid("s"), kind: "companion", date: Date.now(), title: task.title, detail: task.outcomeLine }, ...prev]);
    setQuickLogAck(task.outcomeLine);
    celebrate(); Haptics.bloom(); SoundEngine.bloom();
    setTimeout(() => setQuickLogAck((cur) => (cur === task.outcomeLine ? null : cur)), 5000);
  }, [agentTasks, celebrate]);
  const declineAgentTask = useCallback((id: string) => { setAgentTasks((prev) => prev.filter((t) => t.id !== id)); Haptics.tick(); }, []);
  const openAgentNetwork = useCallback((focus?: string | null) => { setAgentNetworkFocus(focus ?? null); setShowAgentNetwork(true); }, []);

  const series = useCallback((id: string) => labSeries.find((s) => s.id === id), [labSeries]);
  const savingsFor = useCallback((medID: string) => savings.filter((s) => s.medID === medID), [savings]);
  const logsNear = useCallback((medID: string) => logs.filter((l) => l.linkedMedID === medID), [logs]);
  const hasDerivedJourney = useCallback((title: string) => derivedJourneyGoals.has(title), [derivedJourneyGoals]);
  const showsLookingAhead = Boolean(careBundle.lookingAhead);

  const value: SanoStore = {
    tab, setTab, hasOnboarded, showConversation, openConversation, closeConversation,
    showQuickLog, setShowQuickLog, quickLogMedID, setQuickLogMedID, showSettings, setShowSettings,
    showRecap, setShowRecap, pendingCareDest, setPendingCareDest,
    pathway, persona: activePersona, profile, setProfile, displayFirstName,
    moments, insights, medications, journeys, programs, logs, currents, labSeries, storyEvents,
    careTeam, appointments, guideItems, recordItems, sources, consents, memory, threads, bills, cost,
    careDocuments, savings, requests, entries, agentActions, memories,
    resultToAck: careBundle.resultToAck ?? null, resultAcknowledged, lookingAhead: careBundle.lookingAhead ?? null, showsLookingAhead, derivedJourneyGoals,
    tonePreference, setTonePreference, appearance, setAppearance, scheme,
    musicOn, setMusicOn, soundOn, setSoundOn, epsilonConsent, setEpsilonConsent, eraWarmth, setEraWarmth,
    notificationClasses, toggleNotification, quietStart, quietEnd, setQuiet,
    orbState, justBloomed, quickLogAck, setQuickLogAck,
    turns, isThinking, sendMessage, sendVoiceMessage, resolveRich,
    pendingActions, needsYou, openBillsTotal, careUnreadCount,
    walletCards, connections, agentServices, reports, reportSent, sendReport, payBill, toggleConnection, toggleAgentService,
    agentTasks, agentTasksWaiting, agentTasksInMotion, tasksForAgent, activeTaskCount, waitingCount, approveAgentTask, declineAgentTask,
    showAgentNetwork, setShowAgentNetwork, agentNetworkFocus, openAgentNetwork,
    series, savingsFor, logsNear, hasDerivedJourney,
    completeOnboarding, switchPathway, dismissMoment, keepHabit, keptToday, addEntry, removeEntry,
    approveAction, declineAction, addMemoryGlimpse, deleteMemoryGlimpse, addLog,
    addGuideItem: addGuideItemImpl, toggleGuideResolved, removeGuideItem, markInsightSeen, toggleInsightSaved,
    enroll, decline, toggleCurrentSaved, setTaste, deleteMemoryNote, addMemoryNote, acknowledgeResult,
    markThreadRead, sendThreadMessage, startThread, submitRequest, confirmAppointment, rescheduleAppointment,
    canJoin, markBillPaid, addDocument, confirmDocument, removeDocument, applySaving, deriveJourney, wipe,
  };

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
};

function mealSlot(ts: number): string {
  const h = new Date(ts).getHours();
  if (h >= 5 && h < 11) return "Breakfast";
  if (h >= 11 && h < 15) return "Lunch";
  if (h >= 15 && h < 17) return "Afternoon";
  return "Dinner";
}
function behavioralHabit(title: string): string {
  const l = title.toLowerCase();
  if (l.includes("walk") || l.includes("move") || l.includes("evening")) return "A few minutes of activity";
  if (l.includes("bp") || l.includes("pressure")) return "A quick morning reading";
  if (l.includes("water") || l.includes("hydrat")) return "Refill the water bottle";
  if (l.includes("prehab") || l.includes("strong")) return "Today's prehab set";
  if (l.includes("nausea")) return "The on-schedule dose reminder";
  return "One small step toward this";
}
