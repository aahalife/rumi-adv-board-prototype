import React, { useState } from "react";
import { useSano } from "../store";
import { SoundEngine } from "../sound";
import { OrganicCard, Glass, Press, Kicker, ProvenanceChip, FreshnessChip, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { GlowChart, TideView, SceneVisual } from "../ui/DataViz";
import { Sheet } from "../ui/Sheet";
import { SectionTitle } from "./nav";
import { img, fmtMonthDay, fmtTime, fmtWeekday } from "../lifeLibrary";
import type { LabSeries, Medication, CarePlanGoal, RecordCategory, CareEntry } from "../types";

type Push = (name: string, params?: Record<string, unknown>) => void;

// ---------- Medications ----------
export const MedicationsScreen: React.FC<{ push: Push }> = ({ push }) => {
  const s = useSano();
  const overall = s.medications.reduce((a, m) => a + m.adherence30.reduce((x, y) => x + y, 0) / m.adherence30.length, 0) / Math.max(1, s.medications.length);
  return (
    <div className="space-y-4">
      <h1 className="font-serif text-[28px] text-ink">Medications</h1>
      <OrganicCard className="p-4">
        <TideView level={overall} />
        <p className="font-rounded text-[12.5px] text-ink-muted mt-2">Your last 30 days, as a tide — full and steady.</p>
      </OrganicCard>
      <div className="space-y-3">
        {s.medications.map((m) => (
          <OrganicCard key={m.id} className="p-4 flex items-center gap-3.5">
            <Press onClick={() => push("medDetail", { id: m.id })} className="size-14 rounded-2xl overflow-hidden relative shrink-0">
              <img src={img(`med:${m.id}`) ?? `/img/${medImg(m.id)}.png`} alt="" className="absolute inset-0 w-full h-full object-cover" />
            </Press>
            <div className="flex-1 min-w-0">
              <Press onClick={() => push("medDetail", { id: m.id })} className="text-left w-full">
                <h3 className="font-serif text-[18px] text-ink leading-tight">{m.name}</h3>
                <p className="font-rounded text-[12.5px] text-ink-muted">{m.purposeLine}</p>
              </Press>
              <div className="flex items-center gap-2 mt-1.5">
                {m.supplyDaysRemaining <= 7 && <span className="rounded-full px-2 py-0.5 text-[10.5px] font-rounded font-semibold" style={{ background: "rgb(var(--attention) / 0.2)", color: "rgb(var(--attention))" }}>{m.supplyDaysRemaining} days left</span>}
                <Press onClick={() => { s.setQuickLogMedID(m.id); s.setShowQuickLog(true); }} className="text-[12px] font-rounded text-warm font-medium">Log near this</Press>
              </div>
            </div>
          </OrganicCard>
        ))}
      </div>
    </div>
  );
};
function medImg(id: string): string {
  const m: Record<string, string> = { metformin: "medicine_bottle_tablets", lisinopril: "blister_pack_tablets", atorvastatin: "medicine_bottle_pills", ondansetron: "medicine_bottle_tablets", dexamethasone: "blister_pack_tablets", acetaminophen: "medicine_bottle_pills" };
  return m[id] ?? "medicine_bottle_pills";
}

export const MedDetailScreen: React.FC<{ id: string; push: Push }> = ({ id, push }) => {
  const s = useSano();
  const m = s.medications.find((x) => x.id === id);
  if (!m) return null;
  const near = s.logsNear(m.id);
  return (
    <div className="space-y-4">
      <div>
        <h1 className="font-serif text-[28px] text-ink leading-tight">{m.name}</h1>
        <p className="font-rounded text-[14px] text-ink-muted mt-0.5">{m.dose} · {m.purposeLine}</p>
      </div>
      {m.supplyDaysRemaining <= 14 && (
        <OrganicCard className="p-4" style={{ background: "linear-gradient(150deg, rgb(var(--attention) / 0.16), rgb(var(--surface)))" }}>
          <Kicker className="text-attention">Heads up</Kicker>
          <p className="font-serif text-[16px] text-ink mt-1">You'll run low in about {m.supplyDaysRemaining} days.</p>
          <Press onClick={() => s.openConversation("refill")} className="mt-2.5 rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Sort it with me</Press>
        </OrganicCard>
      )}
      <OrganicCard className="p-4"><TideView level={m.adherence30.reduce((a, b) => a + b, 0) / m.adherence30.length} /><p className="font-rounded text-[12px] text-ink-muted mt-2">For the data-curious: {Math.round(m.adherence30.reduce((a, b) => a + b, 0) / m.adherence30.length * 100)}% of doses, last 30 days.</p></OrganicCard>
      <BulletCard title="Good to know" accent="sky" items={m.guidance} />
      <BulletCard title="We watch for" accent="warm" items={m.watchlist} />
      <BulletCard title="Dose history" accent="life" items={m.history} />
      <OrganicCard className="p-4">
        <Kicker className="text-rose">How it's been feeling</Kicker>
        <Press onClick={() => { s.setQuickLogMedID(m.id); s.setShowQuickLog(true); }} className="mt-2 w-full rounded-full py-2.5 text-[13.5px] font-rounded font-semibold glass text-ink">Log near this med</Press>
        {near.length > 0 && <div className="mt-3 space-y-1.5">{near.map((l) => <p key={l.id} className="font-rounded text-[12.5px] text-ink-muted">{l.kind} · {fmtMonthDay(l.at)}</p>)}</div>}
      </OrganicCard>
      <ProvenanceChip text={`Prescribed at ${m.pharmacy}`} className="px-1" />
    </div>
  );
};
const BulletCard: React.FC<{ title: string; accent: string; items: string[] }> = ({ title, accent, items }) => (
  <OrganicCard className="p-4">
    <Kicker className={accentText[accent]}>{title}</Kicker>
    <div className="mt-2 space-y-2">{items.map((it, i) => <div key={i} className="flex gap-2.5 items-start"><span className={`size-1.5 rounded-full mt-1.5 ${accent === "sky" ? "bg-sky" : accent === "warm" ? "bg-warm" : "bg-life"}`} /><p className="font-rounded text-[13px] text-ink/90 leading-snug">{it}</p></div>)}</div>
  </OrganicCard>
);

// ---------- Records ----------
const categories: RecordCategory[] = ["Labs", "Medications", "Conditions", "Immunizations", "Procedures", "Notes", "Documents"];
const catGlyph: Record<RecordCategory, string> = { Labs: "droplet", Medications: "pills", Conditions: "heart", Immunizations: "syringe", Procedures: "cross.case", Notes: "book", Documents: "file" };

export const RecordsScreen: React.FC<{ push: Push }> = ({ push }) => {
  const s = useSano();
  return (
    <div className="space-y-4">
      <div><h1 className="font-serif text-[28px] text-ink">Records</h1><p className="font-rounded text-[13.5px] text-ink-muted mt-1">One unified record from every source — reconciled, with provenance.</p></div>
      <OrganicCard className="p-4 space-y-3">
        {s.sources.map((src) => (
          <div key={src.id} className="flex items-center justify-between">
            <div><p className="font-rounded text-[13.5px] text-ink font-medium">{src.name}</p><p className="font-rounded text-[11.5px] text-ink-muted">{src.railLabel}</p></div>
            <FreshnessChip ts={src.lastSync} />
          </div>
        ))}
      </OrganicCard>
      <div className="grid grid-cols-2 gap-3">
        {categories.map((c) => {
          const count = s.recordItems.filter((r) => r.category === c).length;
          if (count === 0) return null;
          return (
            <Press key={c} onClick={() => push("recordCategory", { category: c })} className="text-left">
              <OrganicCard className="p-4 h-full">
                <Icon name={catGlyph[c]} size={20} className="text-warm" />
                <p className="font-serif text-[16px] text-ink mt-2">{c}</p>
                <p className="font-rounded text-[12px] text-ink-muted">{count} items</p>
              </OrganicCard>
            </Press>
          );
        })}
      </div>
    </div>
  );
};

export const RecordCategoryScreen: React.FC<{ category: RecordCategory; push: Push }> = ({ category, push }) => {
  const s = useSano();
  const items = s.recordItems.filter((r) => r.category === category);
  const [explain, setExplain] = useState<string | null>(null);
  return (
    <div className="space-y-3">
      <h1 className="font-serif text-[28px] text-ink">{category}</h1>
      {category === "Medications" && <Press onClick={() => push("medications")} className="text-warm font-rounded text-[13px] font-medium">Open the full medications space →</Press>}
      {items.map((r) => (
        <OrganicCard key={r.id} className="p-4">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <h3 className="font-serif text-[16px] text-ink leading-tight">{r.title}</h3>
              <p className="font-rounded text-[12.5px] text-ink-muted mt-0.5">{r.detail}</p>
            </div>
            <span className="tnum text-[11px] text-ink-muted shrink-0">{fmtMonthDay(r.date)}</span>
          </div>
          <div className="flex items-center gap-3 mt-2">
            {r.seriesID && <Press onClick={() => push("labDetail", { id: r.seriesID })} className="text-[12px] font-rounded text-sky font-medium">Trend</Press>}
            <Press onClick={() => setExplain(r.id)} className="text-[12px] font-rounded text-warm font-medium">What does this mean for me?</Press>
          </div>
          {r.conflicted && <p className="mt-2 text-[11.5px] font-rounded text-attention">Sources differ here — {r.conflictNote}</p>}
          <p className="mt-2 text-[10.5px] font-rounded text-ink-muted">From {r.source}</p>
        </OrganicCard>
      ))}
      <Sheet open={explain != null} onClose={() => setExplain(null)}>
        <div className="px-6 pt-3 pb-8">
          <h2 className="font-serif text-[22px] text-ink">{items.find((i) => i.id === explain)?.title}</h2>
          <p className="font-rounded text-[14px] text-ink/90 mt-3 leading-relaxed">In plain words: this is part of your record kept here so the whole picture stays in one place. Tap below and I'll talk it through with what it means specifically for you.</p>
          <Press onClick={() => { setExplain(null); s.openConversation("record"); }} className="mt-4 w-full rounded-full py-3 font-rounded font-semibold text-[14px]" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Ask me anything about this</Press>
        </div>
      </Sheet>
    </div>
  );
};

export const LabDetailScreen: React.FC<{ id: string }> = ({ id }) => {
  const s = useSano();
  const series = s.series(id);
  const [explain, setExplain] = useState(false);
  if (!series) return null;
  const latest = series.points[series.points.length - 1];
  return (
    <div className="space-y-4">
      <div>
        <h1 className="font-serif text-[28px] text-ink">{series.name}</h1>
        <div className="flex items-baseline gap-2 mt-1">
          <span className="tnum text-[36px] font-bold text-ink">{latest.value}</span>
          <span className="font-rounded text-[14px] text-ink-muted">{series.unit}</span>
          <FreshnessChip ts={latest.date} />
        </div>
      </div>
      <OrganicCard className="p-3"><GlowChart series={series} scheme={s.scheme} height={220} /></OrganicCard>
      <Press onClick={() => setExplain(true)} className="w-full rounded-full py-3 font-rounded font-semibold text-[14px] flex items-center justify-center gap-2" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}><Icon name="sparkles" size={15} />What does this mean for me?</Press>
      <ProvenanceChip text={series.provenance} className="px-1" />
      <Sheet open={explain} onClose={() => setExplain(false)}>
        <div className="px-6 pt-3 pb-8 space-y-4">
          <h2 className="font-serif text-[23px] text-ink">{series.name}, in plain words</h2>
          <Tier accent="sky" label="The reading" text={series.explainReading} />
          <Tier accent="life" label="What to do next" text={series.explainNextStep} />
          <Tier accent="warm" label="Ask" text={series.explainAsk} />
          <Press onClick={() => { setExplain(false); s.openConversation("lab"); }} className="w-full rounded-full py-3 font-rounded font-semibold text-[14px]" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Talk it through</Press>
        </div>
      </Sheet>
    </div>
  );
};
const Tier: React.FC<{ accent: string; label: string; text: string }> = ({ accent, label, text }) => (
  <div><Kicker className={accentText[accent]}>{label}</Kicker><p className="font-rounded text-[14px] text-ink/90 mt-1 leading-relaxed">{text}</p></div>
);

// ---------- Care plan ----------
export const CarePlanScreen: React.FC = () => {
  const s = useSano();
  const plan = s.persona.carePlan;
  return (
    <div className="space-y-4">
      <div><h1 className="font-serif text-[28px] text-ink">Care plan</h1><p className="font-rounded text-[13px] text-ink-muted mt-1">From {plan.author} · updated {plan.updated}</p></div>
      <OrganicCard className="p-4"><p className="font-serif text-[16px] text-ink/90 leading-relaxed italic">{plan.intro}</p></OrganicCard>
      <SectionTitle>Your goals</SectionTitle>
      <div className="space-y-3">
        {plan.goals.map((g) => <GoalCard key={g.id} goal={g} />)}
      </div>
      <ProvenanceChip text="From your visit notes — turning a goal into a habit is always your choice" className="px-1" />
    </div>
  );
};
const GoalCard: React.FC<{ goal: CarePlanGoal }> = ({ goal }) => {
  const s = useSano();
  const derived = s.hasDerivedJourney(goal.title);
  return (
    <OrganicCard className="p-4">
      <div className="flex items-start gap-2.5">
        <span className={`size-2.5 rounded-full mt-1.5 shrink-0 ${goal.accent === "gold" ? "bg-gold" : goal.accent === "warm" ? "bg-warm" : goal.accent === "life" ? "bg-life" : goal.accent === "sky" ? "bg-sky" : "bg-rose"}`} style={{ boxShadow: "0 0 10px currentColor" }} />
        <div className="flex-1">
          <h3 className="font-serif text-[16px] text-ink leading-tight">{goal.title}</h3>
          <p className="font-rounded text-[13px] text-ink-muted mt-0.5">{goal.detail}</p>
          {goal.progressLine && <p className={`font-rounded text-[12px] mt-1 font-medium ${accentText[goal.accent]}`}>{goal.progressLine}</p>}
          {derived ? (
            <p className="mt-2.5 flex items-center gap-1.5 text-[12.5px] font-rounded text-life"><Icon name="check" size={14} />Following along in Journeys</p>
          ) : (
            <Press onClick={() => s.deriveJourney(goal)} className={`mt-2.5 rounded-full px-3.5 py-1.5 text-[12.5px] font-rounded font-semibold ${accentText[goal.accent]} glass`}>Make it a tiny journey</Press>
          )}
        </div>
      </div>
    </OrganicCard>
  );
};

// ---------- Discussion guide ----------
export const GuideScreen: React.FC = () => {
  const s = useSano();
  const [text, setText] = useState("");
  const [kind, setKind] = useState<"Question" | "Observation">("Question");
  const [sent, setSent] = useState(false);
  const questions = s.guideItems.filter((g) => g.kind === "Question");
  const observations = s.guideItems.filter((g) => g.kind === "Observation");
  const next = s.appointments[0];
  return (
    <div className="space-y-4">
      <div><h1 className="font-serif text-[28px] text-ink">Discussion guide</h1>{next && <p className="font-rounded text-[13px] text-ink-muted mt-1">For {next.with} · {fmtMonthDay(next.date)}</p>}</div>
      <OrganicCard className="p-4">
        <div className="flex gap-2 mb-2.5">
          {(["Question", "Observation"] as const).map((k) => <Press key={k} onClick={() => setKind(k)} className={`rounded-full px-3 py-1.5 text-[12px] font-rounded font-medium ${kind === k ? "text-base" : "text-ink glass"}`} style={kind === k ? { background: "rgb(var(--ink))" } : undefined}>{k === "Question" ? "A question" : "Something to tell them"}</Press>)}
        </div>
        <div className="flex gap-2">
          <input value={text} onChange={(e) => setText(e.target.value)} placeholder="Add it to the list…" className="flex-1 rounded-2xl glass px-3.5 py-2.5 font-rounded text-[14px] text-ink outline-none" />
          <button onClick={() => { if (text.trim()) { s.addGuideItem(kind, text.trim(), "Added by you"); setText(""); } }} className="press grid place-items-center size-10 rounded-full" style={{ background: "rgb(var(--ink))" }}><Icon name="plus" size={18} className="text-base" /></button>
        </div>
      </OrganicCard>
      {s.guideItems.length === 0 ? (
        <OrganicCard className="p-5"><SceneVisual seed={9} height={56} /><p className="font-serif text-[15px] text-ink mt-3 text-center">The list will write itself as we go — you approve every line.</p></OrganicCard>
      ) : (
        <>
          {questions.length > 0 && <><Kicker className="text-gold">Worth asking</Kicker>{questions.map((g) => <GuideRow key={g.id} g={g} />)}</>}
          {observations.length > 0 && <><Kicker className="text-life mt-2">Worth telling them</Kicker>{observations.map((g) => <GuideRow key={g.id} g={g} />)}</>}
          <Press onClick={() => setSent(true)} className="w-full rounded-full py-3 font-rounded font-semibold text-[14px]" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>{sent ? "Sent ahead ✓" : `Send these ahead to ${s.persona.officeName}`}</Press>
        </>
      )}
      <ProvenanceChip text="Captured as you live — yours to edit, always" className="px-1" />
    </div>
  );
};
const GuideRow: React.FC<{ g: { id: string; text: string; addedFrom: string; resolved: boolean } }> = ({ g }) => {
  const s = useSano();
  return (
    <OrganicCard className="p-3.5 flex items-start gap-3">
      <button onClick={() => s.toggleGuideResolved(g.id)} className={`press mt-0.5 size-5 rounded-full grid place-items-center shrink-0 ${g.resolved ? "bg-life" : "glass"}`}>{g.resolved && <Icon name="check" size={12} className="text-base" />}</button>
      <div className="flex-1 min-w-0">
        <p className={`font-rounded text-[13.5px] leading-snug ${g.resolved ? "line-through text-ink-muted" : "text-ink"}`}>{g.text}</p>
        <p className="text-[10.5px] font-rounded text-ink-muted mt-0.5">{g.addedFrom}</p>
      </div>
      <button onClick={() => s.removeGuideItem(g.id)} className="press text-ink-muted/60"><Icon name="x" size={14} /></button>
    </OrganicCard>
  );
};

// ---------- Conditions ----------
export const ConditionsScreen: React.FC<{ push: Push }> = ({ push }) => {
  const s = useSano();
  const p = s.persona;
  return (
    <div className="space-y-4">
      <div className="relative rounded-3xl overflow-hidden h-48">
        <img src={img(p.heroImage) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" />
        <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgb(0 0 0 / 0.6), transparent 60%)" }} />
        <div className="absolute bottom-4 left-4 right-4"><Kicker className="text-white/80">Your picture</Kicker><h1 className="font-serif text-[23px] text-white mt-0.5">{p.conditionChip}</h1></div>
      </div>
      {p.phase && (
        <OrganicCard className="p-4">
          <Kicker className="text-warm">{p.phase.kicker}</Kicker>
          <h2 className="font-serif text-[18px] text-ink mt-1">{p.phase.headline}</h2>
          <p className="font-rounded text-[13px] text-ink-muted mt-1 leading-snug">{p.phase.detail}</p>
          {p.phase.progress != null && <div className="mt-3 h-2 rounded-full overflow-hidden" style={{ background: "rgb(var(--ink-muted) / 0.18)" }}><div className="h-full rounded-full" style={{ width: `${p.phase.progress * 100}%`, background: "linear-gradient(90deg, rgb(var(--warm)), rgb(var(--gold)))" }} /></div>}
        </OrganicCard>
      )}
      <SectionTitle>What you're carrying</SectionTitle>
      {p.conditions.map((c) => (
        <OrganicCard key={c.id} className="p-4 flex items-start gap-3">
          <span className={`size-2.5 rounded-full mt-1.5 ${accentDot(c.accent)}`} style={{ boxShadow: "0 0 10px currentColor" }} />
          <div><h3 className="font-serif text-[16px] text-ink">{c.name}</h3><p className="font-rounded text-[11.5px] text-ink-muted">Since {c.since} · {c.state}</p><p className="font-rounded text-[13px] text-ink/90 mt-1.5 leading-snug">{c.plainLine}</p></div>
        </OrganicCard>
      ))}
      <OrganicCard className="p-4">
        <Kicker className="text-life">The plan from {p.carePlan.author}</Kicker>
        <Press onClick={() => push("carePlan")} className="mt-2 flex items-center justify-between w-full"><span className="font-serif text-[15px] text-ink">See your full care plan</span><Icon name="chevronRight" size={16} className="text-ink-muted" /></Press>
      </OrganicCard>
      <SectionTitle>What to expect</SectionTitle>
      {p.expectations.map((e) => (
        <OrganicCard key={e.id} className="p-4">
          <span className={`inline-block rounded-full px-2.5 py-1 text-[11px] font-rounded font-semibold ${accentText[e.accent]} glass`}>{e.window}</span>
          <h3 className="font-serif text-[16px] text-ink mt-2">{e.title}</h3>
          <p className="font-rounded text-[13px] text-ink-muted mt-1 leading-snug">{e.detail}</p>
        </OrganicCard>
      ))}
      <OrganicCard className="p-4">
        <Kicker className="text-sky">Your numbers, one tap away</Kicker>
        <div className="mt-2 space-y-2">
          {s.labSeries.map((ls) => (
            <Press key={ls.id} onClick={() => push("labDetail", { id: ls.id })} className="flex items-center justify-between w-full py-1">
              <span className="font-rounded text-[14px] text-ink">{ls.name}</span>
              <span className="flex items-center gap-2"><span className="tnum text-[14px] text-ink font-semibold">{ls.points[ls.points.length - 1].value}{ls.unit}</span><Icon name="chevronRight" size={14} className="text-ink-muted" /></span>
            </Press>
          ))}
        </div>
      </OrganicCard>
    </div>
  );
};
function accentDot(a: string): string { return a === "gold" ? "bg-gold" : a === "warm" ? "bg-warm" : a === "life" ? "bg-life" : a === "sky" ? "bg-sky" : "bg-rose"; }

// ---------- Care team ----------
export const CareTeamScreen: React.FC<{ push: Push }> = ({ push }) => {
  const s = useSano();
  return (
    <div className="space-y-4">
      <h1 className="font-serif text-[28px] text-ink">Care team & visits</h1>
      <SectionTitle>Your people</SectionTitle>
      {s.careTeam.map((m) => (
        <OrganicCard key={m.id} className="p-4 flex items-center gap-3">
          <div className="size-11 rounded-full grid place-items-center font-serif text-[16px] text-base shrink-0" style={{ background: "rgb(var(--sky))" }}>{m.name.split(" ").map((w) => w[0]).slice(0, 2).join("")}</div>
          <div><p className="font-serif text-[15px] text-ink">{m.name}</p><p className="font-rounded text-[12px] text-ink-muted">{m.role} · {m.org}</p></div>
        </OrganicCard>
      ))}
      <SectionTitle>Upcoming</SectionTitle>
      {s.appointments.map((a) => (
        <Press key={a.id} onClick={() => push("appointmentDetail", { id: a.id })} className="w-full text-left">
          <OrganicCard className="p-4 flex items-center justify-between"><div><p className="font-serif text-[15px] text-ink">{a.with}</p><p className="font-rounded text-[12px] text-ink-muted">{fmtMonthDay(a.date)} · {a.location}</p></div><Icon name="chevronRight" size={16} className="text-ink-muted" /></OrganicCard>
        </Press>
      ))}
    </div>
  );
};

// ---------- Life catalog ----------
export const LifeCatalogScreen: React.FC = () => {
  const s = useSano();
  const [filter, setFilter] = useState<"All" | CareEntry["kind"]>("All");
  const [detail, setDetail] = useState<CareEntry | null>(null);
  const filtered = filter === "All" ? s.entries : s.entries.filter((e) => e.kind === filter);
  const groups = groupByDay(filtered);
  return (
    <div className="space-y-4">
      <h1 className="font-display text-[36px] text-ink">Life</h1>
      <div className="flex gap-2 overflow-x-auto -mx-5 px-5 pb-1">
        {(["All", "Meals", "Moves", "Meds"] as const).map((f) => <Press key={f} onClick={() => setFilter(f)} className={`shrink-0 rounded-full px-3.5 py-1.5 text-[12.5px] font-rounded font-medium ${filter === f ? "text-base" : "text-ink glass"}`} style={filter === f ? { background: "rgb(var(--ink))" } : undefined}>{f === "All" ? "Everything" : f === "Moves" ? "Activity" : f}</Press>)}
      </div>
      {groups.map(([day, items]) => (
        <div key={day}>
          <div className="flex items-end justify-between mb-2.5">
            <div><Kicker>{day}</Kicker></div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {items.map((e, i) => (
              <Press key={e.id} onClick={() => setDetail(e)} className={`text-left ${i % 3 === 0 ? "col-span-2" : ""}`}>
                <div className="relative rounded-2xl overflow-hidden" style={{ height: i % 3 === 0 ? 180 : 140 }}>
                  <img src={img(e.imageName) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" />
                  <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgb(0 0 0 / 0.55), transparent 55%)" }} />
                  <div className="absolute bottom-2.5 left-3 right-3"><p className="font-serif text-[15px] text-white leading-tight">{e.title}</p><p className="font-rounded text-[11px] text-white/80">{e.detail} · {fmtTime(e.at)}</p></div>
                </div>
              </Press>
            ))}
          </div>
        </div>
      ))}
      {filtered.length === 0 && <OrganicCard className="p-6 text-center"><p className="font-serif text-[16px] text-ink">Nothing here yet — log a meal, an activity, or a med.</p></OrganicCard>}
      <Sheet open={detail != null} onClose={() => setDetail(null)}>{detail && <LifeDetail entry={detail} onClose={() => setDetail(null)} />}</Sheet>
    </div>
  );
};
function groupByDay(entries: CareEntry[]): [string, CareEntry[]][] {
  const map = new Map<string, CareEntry[]>();
  for (const e of entries) {
    const d = new Date(e.at);
    const today = new Date(); const yest = new Date(); yest.setDate(yest.getDate() - 1);
    const label = d.toDateString() === today.toDateString() ? "Today" : d.toDateString() === yest.toDateString() ? "Yesterday" : fmtWeekday(e.at);
    if (!map.has(label)) map.set(label, []);
    map.get(label)!.push(e);
  }
  return Array.from(map.entries());
}
const LifeDetail: React.FC<{ entry: CareEntry; onClose: () => void }> = ({ entry, onClose }) => {
  const s = useSano();
  const facts = entry.imageName ? factsFor(entry.imageName) : null;
  return (
    <div className="px-5 pt-2 pb-10">
      <h2 className="font-display text-[30px] text-ink">{entry.title}</h2>
      <p className="font-rounded text-[13px] text-ink-muted">{entry.detail} · {fmtTime(entry.at)}</p>
      <div className="relative rounded-3xl overflow-hidden mt-4" style={{ height: 260 }}><img src={img(entry.imageName) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" /></div>
      {facts && (
        <div className="mt-4">
          {facts.calories ? <div className="flex items-baseline gap-2"><span className="tnum text-[44px] font-bold text-ink">{facts.calories}</span><span className="font-rounded text-[14px] text-ink-muted">calories · {facts.portion}</span></div> : facts.minutes ? <div className="flex items-baseline gap-2"><span className="tnum text-[44px] font-bold text-ink">{facts.minutes}</span><span className="font-rounded text-[14px] text-ink-muted">minutes · {facts.portion}</span></div> : null}
          {facts.calories ? (
            <div className="mt-3 space-y-2">
              <MacroBar label="PROTEIN" value={facts.protein ?? 0} max={50} color="life" />
              <MacroBar label="CARBS" value={facts.carbs ?? 0} max={70} color="gold" />
              <MacroBar label="FAT" value={facts.fat ?? 0} max={40} color="rose" />
            </div>
          ) : null}
        </div>
      )}
      <div className="mt-5 space-y-2">
        <Press onClick={() => { onClose(); s.openConversation("life"); }} className="w-full rounded-full py-3 font-rounded font-semibold text-[14px] glass text-ink">Ask Rumi about it</Press>
        <Press onClick={() => { s.removeEntry(entry.id); onClose(); }} className="w-full rounded-full py-3 font-rounded text-[14px]" style={{ color: "rgb(var(--destructive))" }}>Remove from the log</Press>
      </div>
    </div>
  );
};
const MacroBar: React.FC<{ label: string; value: number; max: number; color: string }> = ({ label, value, max, color }) => (
  <div><div className="flex justify-between mb-1"><span className="kicker text-ink-muted">{label}</span><span className="tnum text-[12px] text-ink">{value}g</span></div><div className="h-2 rounded-full overflow-hidden" style={{ background: "rgb(var(--ink-muted) / 0.15)" }}><div className={`h-full rounded-full ${color === "life" ? "bg-life" : color === "gold" ? "bg-gold" : "bg-rose"}`} style={{ width: `${Math.min(100, (value / max) * 100)}%` }} /></div></div>
);
function factsFor(image: string) {
  const t: Record<string, { calories?: number; protein?: number; carbs?: number; fat?: number; portion?: string; minutes?: number }> = {
    oatmeal_bowl_blueberries: { calories: 320, protein: 12, carbs: 54, fat: 8, portion: "1 warm bowl" },
    grain_bowl_chicken_quinoa: { calories: 520, protein: 38, carbs: 52, fat: 16, portion: "1 hearty bowl" },
    grilled_salmon_lemon_greens: { calories: 460, protein: 42, carbs: 12, fat: 26, portion: "1 plate" },
    vegetable_omelette_plate: { calories: 340, protein: 22, carbs: 8, fat: 24, portion: "2-egg omelette" },
    lentil_soup_bowl: { calories: 310, protein: 18, carbs: 45, fat: 6, portion: "1 bowl" },
    yogurt_parfait_glass: { calories: 280, protein: 14, carbs: 38, fat: 9, portion: "1 glass" },
    terracotta_cream_sneakers: { portion: "an easy pace", minutes: 25 },
    yoga_mat_rolled: { portion: "breath first", minutes: 20 },
    dumbbells_towel_wellness: { portion: "steady sets", minutes: 30 },
  };
  return t[image] ?? null;
}
