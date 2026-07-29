import React, { useEffect, useRef, useState } from "react";
import { useSano, type CareDest } from "../store";
import { OrganicCard, Glass, Press, Kicker, ProvenanceChip, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { Sheet } from "../ui/Sheet";
import { useStack, SubScreen, HubHeader } from "./nav";
import { MedicationsScreen, MedDetailScreen, RecordsScreen, RecordCategoryScreen, LabDetailScreen, CarePlanScreen, GuideScreen } from "./shared";
import { fmtMonthDay, fmtTime } from "../lifeLibrary";
import type { MessageThread, Bill, Appointment } from "../types";
import { walletKindLabel, walletKindGlyph, type DoctorReport, type WalletCard, type ReportKind } from "../agentNetwork";

const destToRoute = (d: CareDest): { name: string; params?: Record<string, unknown> } => {
  switch (d.t) {
    case "thread": return { name: "thread", params: { id: d.id } };
    case "billDetail": return { name: "billDetail", params: { id: d.id } };
    case "appointmentDetail": return { name: "appointmentDetail", params: { id: d.id } };
    case "medications": return { name: "medications" };
    case "records": return { name: "records" };
    default: return { name: d.t };
  }
};

export const CareHub: React.FC = () => {
  const s = useSano();
  const nav = useStack({ name: "hub" });

  useEffect(() => {
    if (s.pendingCareDest) { nav.push(destToRoute(s.pendingCareDest)); s.setPendingCareDest(null); }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [s.pendingCareDest]);

  const push = (name: string, params?: Record<string, unknown>) => nav.push({ name, params });
  const p = (nav.top.params ?? {}) as Record<string, string>;

  if (nav.top.name === "hub") return <Hub push={push} />;
  return (
    <SubScreen onBack={nav.pop} back={nav.stack.length > 2 ? "Back" : "Care"}>
      {nav.top.name === "messages" && <Messages push={push} />}
      {nav.top.name === "thread" && <ThreadView id={p.id} />}
      {nav.top.name === "requests" && <Requests />}
      {nav.top.name === "appointments" && <Appointments push={push} />}
      {nav.top.name === "appointmentDetail" && <AppointmentDetail id={p.id} push={push} />}
      {nav.top.name === "bills" && <Bills push={push} />}
      {nav.top.name === "billDetail" && <BillDetail id={p.id} />}
      {nav.top.name === "carePlan" && <CarePlanScreen />}
      {nav.top.name === "documents" && <Documents />}
      {nav.top.name === "savings" && <Savings />}
      {nav.top.name === "visitPrep" && <GuideScreen />}
      {nav.top.name === "reports" && <Reports />}
      {nav.top.name === "wallet" && <WalletScreen />}
      {nav.top.name === "connections" && <Connections />}
      {nav.top.name === "medications" && <MedicationsScreen push={push} />}
      {nav.top.name === "medDetail" && <MedDetailScreen id={p.id} push={push} />}
      {nav.top.name === "records" && <RecordsScreen push={push} />}
      {nav.top.name === "recordCategory" && <RecordCategoryScreen category={p.category as never} push={push} />}
      {nav.top.name === "labDetail" && <LabDetailScreen id={p.id} />}
    </SubScreen>
  );
};

const tiles: { name: string; label: string; glyph: string; accent: string; status: (s: ReturnType<typeof useSano>) => string; badge?: (s: ReturnType<typeof useSano>) => number }[] = [
  { name: "messages", label: "Messages", glyph: "message-circle", accent: "sky", status: (s) => { const n = s.threads.filter((t) => t.unread).length; return n ? `${n} waiting for you` : "All caught up"; }, badge: (s) => s.threads.filter((t) => t.unread).length },
  { name: "appointments", label: "Appointments", glyph: "calendar", accent: "gold", status: (s) => s.appointments[0] ? `Next ${fmtMonthDay(s.appointments[0].date)}` : "Nothing scheduled" },
  { name: "carePlan", label: "Care plan", glyph: "leaf", accent: "life", status: (s) => `${s.persona.carePlan.goals.length} goals from your team` },
  { name: "medications", label: "Meds & refills", glyph: "pills", accent: "warm", status: (s) => { const n = s.medications.filter((m) => m.supplyDaysRemaining <= 7).length; return n ? `${n} running low` : "All stocked"; } },
  { name: "records", label: "Records", glyph: "droplet", accent: "rose", status: (s) => `${s.recordItems.length} items, reconciled`, badge: (s) => (!s.resultAcknowledged && s.resultToAck ? 1 : 0) },
  { name: "bills", label: "Bills", glyph: "receipt", accent: "gold", status: (s) => { const t = s.openBillsTotal; return t ? `$${Math.round(t)} to review` : "Nothing due"; } },
  { name: "documents", label: "Documents", glyph: "folder", accent: "sky", status: (s) => `${s.careDocuments.length} saved` },
  { name: "visitPrep", label: "Visit prep", glyph: "book", accent: "warm", status: (s) => `${s.guideItems.filter((g) => !g.resolved).length} on your guide` },
  { name: "reports", label: "Visit reports", glyph: "file", accent: "sky", status: (s) => { const n = s.careTeam.filter((m) => !m.role.toLowerCase().includes("pharmacy")).length; return n ? `${n} ready to review` : "For your visits"; } },
  { name: "wallet", label: "Wallet", glyph: "wallet", accent: "life", status: (s) => (s.openBillsTotal > 0 ? `$${Math.round(s.openBillsTotal)} ready to pay` : `${s.walletCards.length} cards on file`) },
  { name: "connections", label: "Connections", glyph: "link", accent: "rose", status: (s) => { const c = s.connections.filter((x) => x.connected).length; return c ? `${c} connected` : "Bring your world in"; } },
];

const Hub: React.FC<{ push: (n: string, p?: Record<string, unknown>) => void }> = ({ push }) => {
  const s = useSano();
  const subtitle = s.pathway === "metabolic" ? "Your team, your plan, and the day-to-day — handled." : s.pathway === "oncology" ? "Everything around treatment, in one calm place." : "Surgery logistics, your team, and the road to recovery.";
  return (
    <div className="absolute inset-0 overflow-y-auto px-5 pb-32">
      <HubHeader title="Care" subtitle={subtitle} rightPad />
      {s.needsYou.length > 0 && (
        <div className="mt-5">
          <Kicker className="text-warm mb-2">Needs you</Kicker>
          <div className="space-y-2">
            {s.needsYou.map((n) => (
              <Press key={n.id + n.kind} onClick={() => push(destToRoute(n.destination).name, destToRoute(n.destination).params)} className="w-full text-left">
                <OrganicCard className="p-3.5 flex items-center gap-3">
                  <div className="size-9 rounded-full grid place-items-center shrink-0" style={{ background: "rgb(var(--warm) / 0.18)" }}><Icon name={needGlyph(n.kind)} size={16} className="text-warm" /></div>
                  <div className="flex-1 min-w-0"><p className="font-rounded text-[14px] text-ink font-medium leading-tight">{n.title}</p><p className="font-rounded text-[12px] text-ink-muted truncate">{n.detail}</p></div>
                  <Icon name="chevronRight" size={16} className="text-ink-muted" />
                </OrganicCard>
              </Press>
            ))}
          </div>
        </div>
      )}
      <div className="grid grid-cols-2 gap-3 mt-5">
        {tiles.map((t) => {
          const badge = t.badge?.(s) ?? 0;
          return (
            <Press key={t.name} onClick={() => push(t.name)} className="text-left">
              <OrganicCard className="p-4 h-full min-h-[96px] relative">
                {badge > 0 && <span className="absolute top-3 right-3 min-w-5 h-5 px-1.5 rounded-full grid place-items-center text-[11px] font-rounded font-bold text-base" style={{ background: "rgb(var(--warm))" }}>{badge}</span>}
                <div className="size-9 rounded-full grid place-items-center" style={{ background: `rgb(var(--${t.accent}) / 0.18)` }}><Icon name={t.glyph} size={17} className={accentText[t.accent]} /></div>
                <p className="font-serif text-[16px] text-ink mt-2.5">{t.label}</p>
                <p className="font-rounded text-[11.5px] text-ink-muted mt-0.5">{t.status(s)}</p>
              </OrganicCard>
            </Press>
          );
        })}
      </div>
      {s.showsLookingAhead && s.lookingAhead && <LookingAhead push={push} />}
      <ProvenanceChip text="One secure place — synced from your providers and plan" className="mt-5 px-1" />
    </div>
  );
};
function needGlyph(k: string): string { return k === "message" ? "message-circle" : k === "result" ? "droplet" : k === "refill" ? "pills" : k === "bill" ? "receipt" : "calendar"; }

const LookingAhead: React.FC<{ push: (n: string, p?: Record<string, unknown>) => void }> = ({ push }) => {
  const s = useSano();
  const la = s.lookingAhead!;
  const [why, setWhy] = useState(false);
  const [added, setAdded] = useState(false);
  return (
    <OrganicCard className="p-4 mt-5">
      <Kicker className="text-sky">A gentle look ahead</Kicker>
      <h3 className="font-serif text-[18px] text-ink mt-1">{la.headline}</h3>
      <p className="font-rounded text-[13px] text-ink-muted mt-1 leading-snug">{la.body}</p>
      <Press onClick={() => setWhy((v) => !v)} className="text-[12px] font-rounded text-sky font-medium mt-2">Why am I seeing this?</Press>
      {why && <p className="font-rounded text-[12px] text-ink-muted mt-1.5 leading-snug">{la.basis}</p>}
      <Press onClick={() => { if (!added) { s.addGuideItem("Question", la.guideQuestion, "A gentle look ahead"); setAdded(true); push("visitPrep"); } }} className="mt-3 rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>{added ? "Added to your guide" : "Add to my guide"}</Press>
    </OrganicCard>
  );
};

// ---------- Messages ----------
const Messages: React.FC<{ push: (n: string, p?: Record<string, unknown>) => void }> = ({ push }) => {
  const s = useSano();
  return (
    <div className="space-y-3">
      <div><h1 className="font-serif text-[28px] text-ink">Messages</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">Your care teams, one place. Tap to read or reply.</p></div>
      {[...s.threads].sort((a, b) => lastAt(b) - lastAt(a)).map((t) => (
        <Press key={t.id} onClick={() => push("thread", { id: t.id })} className="w-full text-left">
          <OrganicCard className="p-4 flex items-center gap-3">
            <div className="size-11 rounded-full grid place-items-center font-serif text-[15px] text-base shrink-0" style={{ background: "rgb(var(--sky))" }}>{t.memberName.split(" ").map((w) => w[0]).slice(0, 2).join("")}</div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2"><p className="font-serif text-[15px] text-ink truncate">{t.memberName}</p>{t.unread && <span className="size-2 rounded-full bg-warm shrink-0" />}</div>
              <p className="font-rounded text-[12.5px] text-ink-muted truncate">{t.messages[t.messages.length - 1]?.text}</p>
            </div>
            <Icon name={t.mode === "inApp" ? "lock" : "arrowUpRight"} size={14} className={t.mode === "inApp" ? "text-life" : "text-gold"} />
          </OrganicCard>
        </Press>
      ))}
      <Press onClick={() => push("requests")} className="w-full text-left">
        <OrganicCard className="p-4 flex items-center gap-3"><Icon name="tray" size={18} className="text-gold" /><span className="font-serif text-[15px] text-ink flex-1">Requests</span><Icon name="chevronRight" size={16} className="text-ink-muted" /></OrganicCard>
      </Press>
    </div>
  );
};
function lastAt(t: MessageThread): number { return t.messages[t.messages.length - 1]?.at ?? 0; }

const ThreadView: React.FC<{ id: string }> = ({ id }) => {
  const s = useSano();
  const thread = s.threads.find((t) => t.id === id);
  const [draft, setDraft] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);
  useEffect(() => { s.markThreadRead(id); /* eslint-disable-next-line */ }, [id]);
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: "smooth" }); }, [thread?.messages.length]);
  if (!thread) return null;
  return (
    <div className="space-y-3 pb-20">
      <div><h1 className="font-serif text-[24px] text-ink">{thread.memberName}</h1><p className="font-rounded text-[12px] text-ink-muted">{thread.memberRole}</p></div>
      {thread.messages.map((m) => (
        <div key={m.id} className={`flex ${m.author === "user" ? "justify-end" : "justify-start"}`}>
          <div className={`max-w-[80%] rounded-3xl px-4 py-2.5 ${m.author === "user" ? "text-base" : "organic text-ink"}`} style={m.author === "user" ? { background: "rgb(var(--ink))" } : undefined}>
            {m.origin && <p className="text-[10.5px] opacity-70 mb-1 flex items-center gap-1"><Icon name="cornerDownRight" size={10} />{m.origin}</p>}
            <p className="font-rounded text-[14px] leading-snug">{m.text}</p>
            <p className={`text-[10px] mt-1 ${m.author === "user" ? "text-base/70" : "text-ink-muted"}`}>{m.state === "draft" ? "Ready for the portal" : m.state} · {fmtTime(m.at)}</p>
          </div>
        </div>
      ))}
      <div ref={bottomRef} />
      <div className="fixed-none" />
      <Glass radius={24} className="flex items-center gap-2 pl-4 pr-2 py-2 sticky bottom-2">
        <input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder={thread.mode === "portal" ? "Draft a message…" : "Write a reply…"} className="flex-1 bg-transparent outline-none font-rounded text-[14px] text-ink" />
        <button onClick={() => { if (draft.trim()) { s.sendThreadMessage(id, draft); setDraft(""); } }} className="press grid place-items-center size-9 rounded-full" style={{ background: "rgb(var(--ink))" }}><Icon name="send" size={15} className="text-base" /></button>
      </Glass>
    </div>
  );
};

const Requests: React.FC = () => {
  const s = useSano();
  const stepIndex: Record<string, number> = { submitted: 0, acknowledged: 1, resolved: 2 };
  return (
    <div className="space-y-3">
      <div><h1 className="font-serif text-[28px] text-ink">Requests</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">Refills, records, forms — tracked end to end.</p></div>
      {s.requests.map((r) => (
        <OrganicCard key={r.id} className="p-4">
          <div className="flex items-center gap-2.5"><Icon name="tray" size={16} className="text-gold" /><p className="font-serif text-[15px] text-ink">{r.subject}</p></div>
          <p className="font-rounded text-[12.5px] text-ink-muted mt-1">{r.detail}</p>
          <div className="flex items-center gap-1.5 mt-3">
            {["Submitted", "Acknowledged", "Resolved"].map((st, i) => (
              <div key={st} className="flex-1 flex items-center gap-1.5">
                <div className="h-1.5 flex-1 rounded-full" style={{ background: i <= stepIndex[r.state] ? "rgb(var(--life))" : "rgb(var(--ink-muted) / 0.2)" }} />
              </div>
            ))}
          </div>
          <p className="font-rounded text-[11px] text-ink-muted mt-2">{r.routedTo} · {fmtMonthDay(r.at)}</p>
        </OrganicCard>
      ))}
    </div>
  );
};

// ---------- Appointments ----------
const Appointments: React.FC<{ push: (n: string, p?: Record<string, unknown>) => void }> = ({ push }) => {
  const s = useSano();
  return (
    <div className="space-y-3">
      <div><h1 className="font-serif text-[28px] text-ink">Appointments</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">Everything coming up, and how to get there easily.</p></div>
      {[...s.appointments].sort((a, b) => a.date - b.date).map((a) => (
        <Press key={a.id} onClick={() => push("appointmentDetail", { id: a.id })} className="w-full text-left">
          <OrganicCard className="p-4 flex items-center gap-3.5">
            <div className="size-14 rounded-2xl grid place-items-center shrink-0" style={{ background: "rgb(var(--base))" }}>
              <span className="kicker text-warm leading-none">{new Date(a.date).toLocaleDateString([], { month: "short" })}</span>
              <span className="font-serif text-[22px] text-ink leading-none mt-0.5">{new Date(a.date).getDate()}</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-serif text-[16px] text-ink leading-tight">{a.with}</p>
              <p className="font-rounded text-[12px] text-ink-muted truncate">{a.location}</p>
              <div className="flex items-center gap-1.5 mt-1.5">
                <span className="rounded-full px-2 py-0.5 text-[10px] font-rounded font-semibold glass text-sky">{a.kind === "telehealth" ? "Video" : "In person"}</span>
                {a.status === "pending" && <span className="rounded-full px-2 py-0.5 text-[10px] font-rounded font-semibold text-attention">To confirm</span>}
                {a.prepReady && <span className="text-[10px] font-rounded text-warm flex items-center gap-0.5"><Icon name="sparkles" size={10} />Prep ready</span>}
              </div>
            </div>
            <Icon name="chevronRight" size={16} className="text-ink-muted" />
          </OrganicCard>
        </Press>
      ))}
    </div>
  );
};

const AppointmentDetail: React.FC<{ id: string; push: (n: string, p?: Record<string, unknown>) => void }> = ({ id, push }) => {
  const s = useSano();
  const a = s.appointments.find((x) => x.id === id);
  const [check, setCheck] = useState<Set<number>>(new Set());
  if (!a) return null;
  return (
    <div className="space-y-4">
      <OrganicCard className="p-5">
        <div className="flex gap-2"><span className="rounded-full px-2.5 py-1 text-[11px] font-rounded font-semibold glass text-sky">{a.kind === "telehealth" ? "Video visit" : "In person"}</span><span className={`rounded-full px-2.5 py-1 text-[11px] font-rounded font-semibold ${a.status === "confirmed" ? "text-life" : "text-attention"}`}>{a.status}</span></div>
        <h1 className="font-serif text-[24px] text-ink mt-3">{a.with}</h1>
        <p className="font-rounded text-[13px] text-ink-muted mt-1 flex items-center gap-1.5"><Icon name="calendar" size={13} />{new Date(a.date).toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" })} · {fmtTime(a.date)}</p>
        <p className="font-rounded text-[13px] text-ink-muted mt-1 flex items-center gap-1.5"><Icon name="mapPin" size={13} />{a.location}</p>
      </OrganicCard>
      {a.planGoalHint && <OrganicCard className="p-4"><Kicker className="text-life">What this visit moves</Kicker><p className="font-rounded text-[14px] text-ink mt-1">{a.planGoalHint}</p></OrganicCard>}
      <div className="space-y-2">
        {a.kind === "telehealth" && <Press onClick={() => a.joinLink && window.open(a.joinLink, "_blank")} className="w-full rounded-full py-3 font-rounded font-semibold text-[14px]" style={{ background: s.canJoin(a) ? "rgb(var(--ink))" : "rgb(var(--ink-muted) / 0.25)", color: s.canJoin(a) ? "rgb(var(--base))" : "rgb(var(--ink) / 0.6)" }}>{s.canJoin(a) ? "Join the video visit" : "Join opens 15 min before"}</Press>}
        {a.status === "pending" && <Press onClick={() => s.confirmAppointment(a.id)} className="w-full rounded-full py-3 font-rounded font-semibold text-[14px]" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Confirm this time</Press>}
        {a.prepReady && <Press onClick={() => push("visitPrep")} className="w-full rounded-full py-3 font-rounded font-semibold text-[14px] glass text-ink">See your visit prep</Press>}
      </div>
      {a.trip && (
        <OrganicCard className="p-4">
          <Kicker className="text-gold">{a.trip.isVirtual ? "Get ready to connect" : "Plan your trip"}</Kicker>
          {!a.trip.isVirtual && <div className="mt-2"><p className="font-rounded text-[12px] text-ink-muted">Leave by</p><p className="font-serif text-[26px] text-ink">{fmtTime(a.trip.departBy)}</p><p className="font-rounded text-[12px] text-ink-muted">{a.trip.routeHint}</p></div>}
          {a.trip.calendarConflict && <p className="mt-2 rounded-xl p-2.5 text-[12px] font-rounded text-attention" style={{ background: "rgb(var(--attention) / 0.12)" }}>{a.trip.calendarConflict}</p>}
          <div className="mt-3 space-y-1.5">
            {a.trip.checklist.map((c, i) => (
              <button key={i} onClick={() => setCheck((s) => { const n = new Set(s); n.has(i) ? n.delete(i) : n.add(i); return n; })} className="press flex items-center gap-2.5 w-full text-left">
                <span className={`size-5 rounded-full grid place-items-center shrink-0 ${check.has(i) ? "bg-life" : "glass"}`}>{check.has(i) && <Icon name="check" size={11} className="text-base" />}</span>
                <span className={`font-rounded text-[13px] ${check.has(i) ? "line-through text-ink-muted" : "text-ink"}`}>{c}</span>
              </button>
            ))}
          </div>
          {a.trip.rideHint && <p className="font-rounded text-[12px] text-ink-muted mt-3">{a.trip.rideHint}</p>}
        </OrganicCard>
      )}
    </div>
  );
};

// ---------- Bills ----------
const Bills: React.FC<{ push: (n: string, p?: Record<string, unknown>) => void }> = ({ push }) => {
  const s = useSano();
  const open = s.bills.filter((b) => b.status === "open");
  const settled = s.bills.filter((b) => b.status !== "open");
  return (
    <div className="space-y-4">
      <div><h1 className="font-serif text-[28px] text-ink">Bills & costs</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">What you owe, what's covered, and why — no surprises.</p></div>
      <OrganicCard className="p-4">
        <Kicker>This year so far · {s.cost.planName}</Kicker>
        <CostBar label="Deductible" met={s.cost.deductibleMet} total={s.cost.deductibleTotal} />
        <CostBar label="Out-of-pocket" met={s.cost.oopMet} total={s.cost.oopTotal} />
        {s.cost.upcomingEstimate != null && <p className="font-rounded text-[12px] text-ink-muted mt-3">Upcoming: ~${s.cost.upcomingEstimate} — {s.cost.upcomingLabel}</p>}
      </OrganicCard>
      {open.length > 0 && <><Kicker className="text-attention">Worth a look</Kicker>{open.map((b) => <BillRow key={b.id} bill={b} push={push} />)}</>}
      {settled.length > 0 && <><Kicker className="text-life mt-2">Settled</Kicker>{settled.map((b) => <BillRow key={b.id} bill={b} push={push} />)}</>}
    </div>
  );
};
const CostBar: React.FC<{ label: string; met: number; total: number }> = ({ label, met, total }) => (
  <div className="mt-3"><div className="flex justify-between mb-1"><span className="font-rounded text-[12.5px] text-ink">{label}</span><span className="tnum text-[12px] text-ink-muted">${met} of ${total}</span></div><div className="h-2.5 rounded-full overflow-hidden" style={{ background: "rgb(var(--ink-muted) / 0.15)" }}><div className="h-full rounded-full" style={{ width: `${Math.min(100, (met / total) * 100)}%`, background: "linear-gradient(90deg, rgb(var(--sky)), rgb(var(--life)))", boxShadow: "0 0 10px rgb(var(--sky) / 0.5)" }} /></div></div>
);
const BillRow: React.FC<{ bill: Bill; push: (n: string, p?: Record<string, unknown>) => void }> = ({ bill, push }) => (
  <Press onClick={() => push("billDetail", { id: bill.id })} className="w-full text-left">
    <OrganicCard className="p-4 flex items-center justify-between">
      <div><p className="font-serif text-[15px] text-ink">{bill.provider}</p><p className="font-rounded text-[12px] text-ink-muted">{bill.encounter}</p></div>
      <div className="text-right"><p className="tnum text-[18px] font-bold text-ink">${Math.round(bill.amount)}</p><span className={`text-[10.5px] font-rounded ${bill.status === "open" ? "text-attention" : "text-life"}`}>{bill.status === "open" ? "open" : "paid"}</span></div>
    </OrganicCard>
  </Press>
);
const BillDetail: React.FC<{ id: string }> = ({ id }) => {
  const s = useSano();
  const b = s.bills.find((x) => x.id === id);
  const [confirmPaid, setConfirmPaid] = useState(false);
  const [payOpen, setPayOpen] = useState(false);
  if (!b) return null;
  return (
    <div className="space-y-4">
      <OrganicCard className="p-5">
        <span className={`rounded-full px-2.5 py-1 text-[11px] font-rounded font-semibold ${b.status === "open" ? "text-attention" : "text-life"}`}>{b.status}</span>
        <h1 className="font-serif text-[24px] text-ink mt-2">{b.provider}</h1>
        <p className="font-rounded text-[12px] text-ink-muted">{b.encounter}</p>
        <p className="tnum text-[38px] font-bold text-ink mt-2">${Math.round(b.amount)}<span className="font-rounded text-[14px] text-ink-muted font-normal ml-2">{b.amount > 0 ? "your share" : "settled"}</span></p>
      </OrganicCard>
      <OrganicCard className="p-4 flex items-start gap-3"><div className="size-8 rounded-full grid place-items-center shrink-0" style={{ background: "rgb(var(--warm) / 0.18)" }}><Icon name="message-circle" size={15} className="text-warm" /></div><div><Kicker className="text-warm">In plain words</Kicker><p className="font-rounded text-[13.5px] text-ink/90 mt-1 leading-snug">{b.plainSummary}</p></div></OrganicCard>
      <OrganicCard className="p-4">
        <Kicker>The breakdown</Kicker>
        <div className="mt-2 space-y-2.5">
          {b.lineItems.map((li) => (
            <div key={li.id}><div className="flex justify-between"><span className="font-rounded text-[13px] text-ink">{li.label}</span><span className="tnum text-[13px] text-ink font-semibold">${li.youOwe}</span></div><p className="text-[11px] font-rounded text-ink-muted">Billed ${li.billed} · Plan paid ${li.planPaid} · {li.reason}</p></div>
          ))}
        </div>
      </OrganicCard>
      {b.status === "open" && (
        <div className="space-y-2">
          <Press onClick={() => setPayOpen(true)} className="w-full rounded-full py-3.5 font-rounded font-semibold text-[14px] flex items-center justify-center gap-2" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}><Icon name="sparkles" size={14} />Pay ${Math.round(b.amount)} from your wallet</Press>
          <Press onClick={() => window.open("https://example.com/pay", "_blank")} className="w-full rounded-full py-3 font-rounded font-semibold text-[13.5px] glass text-ink flex items-center justify-center gap-2"><Icon name="lock" size={13} />Pay on the provider's secure page instead</Press>
          {confirmPaid ? <Press onClick={() => s.markBillPaid(b.id)} className="w-full rounded-full py-2.5 font-rounded text-[12.5px] text-life font-semibold">Tap again to confirm it's paid</Press> : <Press onClick={() => setConfirmPaid(true)} className="w-full rounded-full py-2.5 font-rounded text-[12.5px] text-ink-muted">I've already paid this</Press>}
          <p className="text-[11px] font-rounded text-ink-muted text-center">Rumi keeps only a label and the last four digits, and asks before every payment.</p>
        </div>
      )}
      <Sheet open={payOpen} onClose={() => setPayOpen(false)}>
        <div className="px-5 pt-2 pb-10">
          <h2 className="font-serif text-[22px] text-ink">Pay ${Math.round(b.amount)} to {b.provider}</h2>
          <p className="font-rounded text-[13px] text-ink-muted mt-1">Choose a card — Rumi pays it and files the receipt.</p>
          <div className="space-y-2.5 mt-4">
            {s.walletCards.map((c) => (
              <Press key={c.id} onClick={() => { s.payBill(b.id, c); setPayOpen(false); }} className="w-full text-left rounded-2xl glass p-3.5 flex items-center gap-3">
                <div className="size-10 rounded-xl grid place-items-center shrink-0" style={{ background: `rgb(var(--${c.accent}) / 0.2)` }}><Icon name={walletKindGlyph(c.kind)} size={17} className={accentText[c.accent]} /></div>
                <div className="flex-1 min-w-0"><p className="font-serif text-[15px] text-ink leading-tight">{c.name} •••• {c.last4}</p><p className="font-rounded text-[11.5px] text-ink-muted">{c.balanceLine ?? c.issuer}</p></div>
                <Icon name="chevronRight" size={16} className="text-ink-muted" />
              </Press>
            ))}
          </div>
        </div>
      </Sheet>
    </div>
  );
};

// ---------- Documents ----------
const Documents: React.FC = () => {
  const s = useSano();
  const [detail, setDetail] = useState<string | null>(null);
  const doc = s.careDocuments.find((d) => d.id === detail);
  return (
    <div className="space-y-4">
      <div><h1 className="font-serif text-[28px] text-ink">Documents</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">Cards, results, forms — kept private and easy to find.</p></div>
      <div className="grid grid-cols-2 gap-3">
        {s.careDocuments.map((d) => (
          <Press key={d.id} onClick={() => setDetail(d.id)} className="text-left">
            <OrganicCard className="p-3">
              <div className="h-20 rounded-xl mb-2 grid place-items-center" style={{ background: "linear-gradient(140deg, rgb(var(--sky) / 0.2), rgb(var(--gold) / 0.12))" }}><Icon name="file" size={26} className="text-sky" /></div>
              <p className="font-serif text-[14px] text-ink leading-tight">{d.title}</p>
              <p className="font-rounded text-[11px] text-ink-muted">{d.type}</p>
              {!d.confirmed && <span className="inline-block mt-1 size-2 rounded-full bg-attention" />}
            </OrganicCard>
          </Press>
        ))}
      </div>
      <Sheet open={detail != null} onClose={() => setDetail(null)}>
        {doc && (
          <div className="px-5 pt-2 pb-10">
            <div className="h-44 rounded-2xl grid place-items-center mb-4" style={{ background: "linear-gradient(140deg, rgb(var(--sky) / 0.2), rgb(var(--gold) / 0.12))" }}><Icon name="file" size={40} className="text-sky" /></div>
            <h2 className="font-serif text-[24px] text-ink">{doc.title}</h2>
            <p className="font-rounded text-[12px] text-ink-muted">{doc.type} · {fmtMonthDay(doc.capturedAt)}</p>
            <OrganicCard className="p-4 mt-4"><Kicker>Pulled from your scan</Kicker><div className="mt-2 space-y-2">{doc.fields.map((f) => <div key={f.id} className="flex justify-between"><span className="font-rounded text-[13px] text-ink-muted">{f.label}</span><span className="font-rounded text-[13px] text-ink font-medium">{f.value}</span></div>)}</div></OrganicCard>
            <ProvenanceChip text={doc.source} className="mt-3 px-1" />
          </div>
        )}
      </Sheet>
    </div>
  );
};

const Savings: React.FC = () => {
  const s = useSano();
  return (
    <div className="space-y-3">
      <div><h1 className="font-serif text-[28px] text-ink">Ways to save</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">Copay cards, assistance, cash prices.</p></div>
      {s.savings.map((sv) => (
        <OrganicCard key={sv.id} className="p-4">
          <div className="flex items-start gap-2.5"><Icon name="sprout" size={18} className="text-gold mt-0.5" /><div className="flex-1"><p className="font-serif text-[15px] text-ink">{sv.title}</p><p className="font-rounded text-[13px] text-life mt-0.5">{sv.estimateLine}</p><p className="font-rounded text-[11px] text-ink-muted mt-1">{sv.basis}</p></div></div>
          <Press onClick={() => s.applySaving(sv.id)} className="mt-3 rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>{sv.applied ? "Applied ✓" : sv.requiresPII ? "Review & apply" : "Use this"}</Press>
          {sv.sponsor && <p className="text-[11px] font-rounded text-ink-muted mt-2">Supported by {sv.sponsor} — never changes which medication is right for you.</p>}
        </OrganicCard>
      ))}
      <OrganicCard className="p-4 flex items-center gap-2.5"><Icon name="shield" size={16} className="text-life" /><p className="font-rounded text-[12.5px] text-ink-muted">These never change which medication is right for you.</p></OrganicCard>
    </div>
  );
};

// ---------- Visit reports (per doctor) ----------
const Reports: React.FC = () => {
  const s = useSano();
  const [range, setRange] = useState(30);
  const [open, setOpen] = useState<DoctorReport | null>(null);
  const reports = s.reports(range);
  return (
    <div className="space-y-4">
      <div><h1 className="font-serif text-[28px] text-ink">Visit reports</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">A clear summary for each doctor — tailored to them, shared across the team.</p></div>
      <div className="flex items-center gap-2">
        <span className="font-rounded text-[12.5px] text-ink-muted">Window</span>
        {[30, 60, 90].map((d) => <Press key={d} onClick={() => setRange(d)} className={`rounded-full px-3 py-1.5 text-[12.5px] font-rounded font-medium ${range === d ? "text-base" : "text-ink glass"}`} style={range === d ? { background: "rgb(var(--ink))" } : undefined}>{d} days</Press>)}
      </div>
      {reports.map((r) => (
        <Press key={r.id} onClick={() => setOpen(r)} className="w-full text-left">
          <OrganicCard className="p-4">
            <div className="flex items-center gap-3">
              <div className="size-10 rounded-full grid place-items-center shrink-0" style={{ background: "rgb(var(--sky) / 0.16)" }}><Icon name="stethoscope" size={17} className="text-sky" /></div>
              <div className="flex-1 min-w-0"><p className="font-serif text-[16px] text-ink leading-tight">{r.doctorName}</p><p className="font-rounded text-[12px] text-ink-muted">{r.doctorRole}</p></div>
              {s.reportSent(r.id) && <span className="text-[11.5px] font-rounded font-semibold text-life flex items-center gap-1"><Icon name="check" size={13} />Sent</span>}
            </div>
            <p className="font-rounded text-[13px] text-ink/85 mt-2">Leads with {r.focusLine}.</p>
            <div className="flex items-center justify-between mt-2"><p className="font-rounded text-[11px] text-ink-muted">{r.preparedLine}</p><span className="font-rounded text-[12.5px] text-warm font-semibold flex items-center gap-1">Review<Icon name="chevronRight" size={12} /></span></div>
          </OrganicCard>
        </Press>
      ))}
      <Sheet open={open != null} onClose={() => setOpen(null)}>{open && <ReportDoc report={open} />}</Sheet>
      <ProvenanceChip text="Drafted from your record — you review and approve before anything sends" className="px-1" />
    </div>
  );
};

const reportAccent: Record<ReportKind, string> = { headline: "ink", numbers: "sky", meds: "warm", logging: "life", crossRef: "gold", questions: "rose" };
const ReportDoc: React.FC<{ report: DoctorReport }> = ({ report }) => {
  const s = useSano();
  const [confirm, setConfirm] = useState(false);
  const sent = s.reportSent(report.id);
  return (
    <div className="px-4 pt-1 pb-8">
      <div className="organic rounded-3xl p-5">
        <p className="kicker text-warm">{report.title}</p>
        <h2 className="font-display text-[24px] text-ink mt-1">For {report.doctorName}</h2>
        <p className="font-rounded text-[12.5px] text-ink-muted">{report.doctorRole} · {report.org}</p>
        <p className="font-rounded text-[11.5px] text-ink-muted">{report.preparedLine}</p>
        <div className="h-px my-4" style={{ background: "rgb(var(--edge))" }} />
        <div className="space-y-5">
          {report.sections.map((sec) => (
            <div key={sec.id}>
              <h3 className="font-serif text-[16px] text-ink mb-2">{sec.title}</h3>
              <div className="space-y-2">
                {sec.lines.map((ln, i) => sec.kind === "headline" ? (
                  <div key={i}><p className="font-rounded text-[14px] text-ink font-semibold">{ln.primary}</p>{ln.secondary && <p className="font-rounded text-[12.5px] text-ink-muted mt-0.5">{ln.secondary}</p>}</div>
                ) : (
                  <div key={i} className="flex gap-2.5 items-start"><span className="size-1.5 rounded-full mt-1.5 shrink-0" style={{ background: `rgb(var(--${reportAccent[sec.kind]}))` }} /><div><p className="font-rounded text-[13px] text-ink font-medium">{ln.primary}</p>{ln.secondary && <p className="font-rounded text-[11.5px] text-ink-muted">{ln.secondary}</p>}</div></div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
      <div className="mt-4">
        {sent ? (
          <p className="text-center font-rounded text-[14px] text-life font-semibold flex items-center justify-center gap-1.5"><Icon name="check" size={16} />Sent to {report.doctorName}</p>
        ) : confirm ? (
          <Press onClick={() => s.sendReport(report)} className="w-full rounded-full py-3.5 font-rounded font-semibold text-[14px]" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Tap again to send to {report.doctorName}</Press>
        ) : (
          <Press onClick={() => setConfirm(true)} className="w-full rounded-full py-3.5 font-rounded font-semibold text-[14px] flex items-center justify-center gap-2" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}><Icon name="send" size={15} />Review & send to {report.doctorName}</Press>
        )}
        <p className="text-center font-rounded text-[11px] text-ink-muted mt-2">Nothing sends without you.</p>
      </div>
    </div>
  );
};

// ---------- Wallet ----------
const WalletScreen: React.FC = () => {
  const s = useSano();
  const open = s.bills.filter((b) => b.status === "open");
  return (
    <div className="space-y-4">
      <div><h1 className="font-serif text-[28px] text-ink">Wallet</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">Cards on file for bills and copays — used only with your tap.</p></div>
      <div className="space-y-3.5">{s.walletCards.map((c) => <WalletCardView key={c.id} card={c} />)}</div>
      {open.length > 0 && (
        <OrganicCard className="p-4">
          <Kicker className="text-warm">Waiting to pay</Kicker>
          <div className="mt-2 space-y-2">{open.map((b) => <div key={b.id} className="flex items-center justify-between"><div><p className="font-rounded text-[13.5px] text-ink font-medium">{b.provider}</p><p className="font-rounded text-[11px] text-ink-muted">{b.encounter}</p></div><span className="tnum text-[15px] text-ink font-semibold">${Math.round(b.amount)}</span></div>)}</div>
          <p className="font-rounded text-[11.5px] text-ink-muted mt-2">Open a bill to pay it from a card here.</p>
        </OrganicCard>
      )}
      <OrganicCard className="p-4 flex items-start gap-2.5"><Icon name="shield" size={16} className="text-life mt-0.5" /><p className="font-rounded text-[12px] text-ink-muted">Rumi only keeps a label and the last four digits. It asks before every payment.</p></OrganicCard>
    </div>
  );
};
const WalletCardView: React.FC<{ card: WalletCard }> = ({ card }) => (
  <div className="relative rounded-3xl p-4 h-32 overflow-hidden" style={{ background: `linear-gradient(135deg, rgb(var(--${card.accent}) / 0.92), rgb(var(--${card.accent}) / 0.55))`, boxShadow: `0 14px 30px -12px rgb(var(--${card.accent}) / 0.6)` }}>
    <div className="flex items-center justify-between"><Icon name={walletKindGlyph(card.kind)} size={18} className="text-white" /><span className="kicker text-white/90">{walletKindLabel(card.kind)}</span></div>
    <div className="absolute bottom-4 left-4 right-4">
      <p className="font-serif text-[18px] text-white">{card.name}</p>
      <div className="flex items-center gap-2 mt-0.5"><span className="tnum text-[13px] text-white/90">•••• {card.last4}</span><span className="font-rounded text-[11px] text-white/80">{card.issuer}</span><span className="flex-1" />{card.balanceLine && <span className="font-rounded text-[11px] font-semibold text-white rounded-full px-2 py-0.5" style={{ background: "rgb(255 255 255 / 0.18)" }}>{card.balanceLine}</span>}</div>
    </div>
  </div>
);

// ---------- Connections + agent family ----------
const Connections: React.FC = () => {
  const s = useSano();
  const google = s.connections.filter((c) => c.group === "google");
  const channels = s.connections.filter((c) => c.group === "channel");
  return (
    <div className="space-y-5">
      <div><h1 className="font-serif text-[28px] text-ink">Connections</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">Bring your world in — Rumi gets smarter and meets you where you already are.</p></div>
      <ConnGroup title="Google" subtitle="Context and sending, with your permission" items={google} />
      <ConnGroup title="Your channels" subtitle="Where Rumi can reach you, and you can reply" items={channels} />
      <div>
        <div className="flex items-start justify-between gap-2">
          <div>
            <h2 className="font-serif text-[18px] text-ink">Your Rumi network</h2>
            <p className="font-rounded text-[12.5px] text-ink-muted">A family of specialized agents. Tap any one to see what it's doing.</p>
          </div>
          <Press onClick={() => s.openAgentNetwork()} className="shrink-0 flex items-center gap-1 text-[12px] font-rounded font-semibold text-sky">See all<Icon name="arrowUpRight" size={11} /></Press>
        </div>
        <div className="grid grid-cols-2 gap-2.5 mt-3">{s.agentServices.map((a) => {
          const waiting = s.waitingCount(a.id);
          const active = s.activeTaskCount(a.id);
          const status = !a.active ? "Paused" : waiting > 0 ? `${waiting} waiting · ${active} in motion` : active > 0 ? `${active} in motion` : a.role;
          return (
          <Press key={a.id} onClick={() => s.openAgentNetwork(a.id)} className="text-left"><OrganicCard className={`p-3 h-full min-h-[112px] ${a.active ? "" : "opacity-60"}`}>
            <div className="flex items-center justify-between"><div className="size-9 rounded-full grid place-items-center" style={{ background: `rgb(var(--${a.accent}) / 0.16)` }}><Icon name={a.glyph} size={15} className={accentText[a.accent]} /></div>{waiting > 0 ? <span className="min-w-4 h-4 px-1 rounded-full grid place-items-center text-[10px] font-rounded font-bold text-base" style={{ background: "rgb(var(--warm))" }}>{waiting}</span> : <span className="size-2 rounded-full" style={{ background: a.active ? "rgb(var(--life))" : "rgb(var(--ink-muted) / 0.4)" }} />}</div>
            <p className="font-serif text-[14px] text-ink mt-2">{a.name}</p><p className={`font-rounded text-[11px] mt-0.5 leading-snug ${waiting > 0 ? "text-warm" : "text-ink-muted"}`}>{status}</p>
          </OrganicCard></Press>
          );
        })}</div>
      </div>
      <ProvenanceChip text="Connect or disconnect any time — Rumi only uses what you allow" className="px-1" />
    </div>
  );
};
const ConnGroup: React.FC<{ title: string; subtitle: string; items: ReturnType<typeof useSano>["connections"] }> = ({ title, subtitle, items }) => {
  const s = useSano();
  return (
    <div>
      <h2 className="font-serif text-[18px] text-ink">{title}</h2>
      <p className="font-rounded text-[12.5px] text-ink-muted">{subtitle}</p>
      <div className="space-y-2.5 mt-3">
        {items.map((c) => (
          <OrganicCard key={c.id} className="p-3.5">
            <div className="flex items-center gap-3">
              <div className="size-10 rounded-full grid place-items-center shrink-0" style={{ background: `rgb(var(--${c.accent}) / 0.16)` }}><Icon name={c.glyph} size={16} className={accentText[c.accent]} /></div>
              <div className="flex-1 min-w-0"><p className="font-serif text-[15px] text-ink leading-tight">{c.name}</p><p className={`font-rounded text-[12px] truncate ${c.connected ? "text-life" : "text-ink-muted"}`}>{c.connected ? (c.accountLine ?? "Connected") : c.detail}</p></div>
              <Press onClick={() => s.toggleConnection(c.id)} className={`rounded-full px-3.5 py-2 text-[12.5px] font-rounded font-semibold ${c.connected ? "text-life glass" : "text-base"}`} style={c.connected ? undefined : { background: "rgb(var(--ink))" }}>{c.connected ? "Connected" : "Connect"}</Press>
            </div>
            {c.connected && <p className="font-rounded text-[12px] text-ink-muted mt-2.5">{c.enables}</p>}
          </OrganicCard>
        ))}
      </div>
    </div>
  );
};

