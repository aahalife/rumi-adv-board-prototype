import React, { useEffect, useState } from "react";
import { useSano } from "../store";
import { OrganicCard, Glass, Press, Kicker, ProvenanceChip, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { GlowChart, TideView, SceneVisual } from "../ui/DataViz";
import { useStack, SubScreen } from "./nav";
import { MedicationsScreen, MedDetailScreen, RecordsScreen, RecordCategoryScreen, LabDetailScreen, CarePlanScreen, GuideScreen, ConditionsScreen, CareTeamScreen, LifeCatalogScreen } from "./shared";
import { img, fmtMonthDay } from "../lifeLibrary";
import type { Insight, StoryEvent } from "../types";

export const YouHub: React.FC = () => {
  const s = useSano();
  const nav = useStack({ name: "hub" });
  const [seg, setSeg] = useState<"story" | "insights">("story");

  useEffect(() => {
    const openLife = () => nav.push({ name: "life" });
    const openConditions = () => nav.push({ name: "conditions" });
    window.addEventListener("sano.openLife", openLife);
    window.addEventListener("sano.openConditions", openConditions);
    return () => { window.removeEventListener("sano.openLife", openLife); window.removeEventListener("sano.openConditions", openConditions); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const push = (name: string, params?: Record<string, unknown>) => nav.push({ name, params });
  const p = (nav.top.params ?? {}) as Record<string, string>;

  if (nav.top.name !== "hub") {
    return (
      <SubScreen onBack={nav.pop} back={nav.stack.length > 2 ? "Back" : "You"}>
        {nav.top.name === "records" && <RecordsScreen push={push} />}
        {nav.top.name === "recordCategory" && <RecordCategoryScreen category={p.category as never} push={push} />}
        {nav.top.name === "labDetail" && <LabDetailScreen id={p.id} />}
        {nav.top.name === "medications" && <MedicationsScreen push={push} />}
        {nav.top.name === "medDetail" && <MedDetailScreen id={p.id} push={push} />}
        {nav.top.name === "conditions" && <ConditionsScreen push={push} />}
        {nav.top.name === "carePlan" && <CarePlanScreen />}
        {nav.top.name === "guide" && <GuideScreen />}
        {nav.top.name === "careTeam" && <CareTeamScreen push={push} />}
        {nav.top.name === "appointmentDetail" && <CareTeamScreen push={push} />}
        {nav.top.name === "life" && <LifeCatalogScreen />}
      </SubScreen>
    );
  }

  const unresolved = s.guideItems.filter((g) => !g.resolved).length;
  const doors = [
    { name: "conditions", label: s.persona.conditionChip, glyph: s.pathway === "metabolic" ? "heart" : s.pathway === "oncology" ? "sparkles" : s.pathway === "cardiometabolic" ? "heart" : "activity", accent: "warm" },
    { name: "guide", label: "Discussion guide", glyph: "book", accent: "gold", badge: unresolved },
    { name: "careTeam", label: "Care team & visits", glyph: "stethoscope", accent: "life" },
    { name: "medications", label: "Medications", glyph: "pills", accent: "sky" },
    { name: "life", label: "Life catalog", glyph: "forkKnife", accent: "rose" },
  ];

  return (
    <div className="absolute inset-0 overflow-y-auto px-5 pb-32">
      <div className="flex items-center justify-between pt-4">
        <Glass radius={22} className="flex p-1">
          {(["story", "insights"] as const).map((t) => <button key={t} onClick={() => setSeg(t)} className={`px-4 py-1.5 rounded-full text-[13px] font-rounded font-semibold transition-colors ${seg === t ? "text-base" : "text-ink"}`} style={seg === t ? { background: "rgb(var(--ink))" } : undefined}>{t === "story" ? "Story" : "Insights"}</button>)}
        </Glass>
      </div>

      <div className="flex gap-2 overflow-x-auto -mx-5 px-5 mt-4 pb-1">
        {doors.map((d) => (
          <Press key={d.name} onClick={() => push(d.name)} className="shrink-0 relative">
            <Glass radius={18} className="px-3.5 py-2.5 flex items-center gap-2">
              <Icon name={d.glyph} size={15} className={accentText[d.accent]} />
              <span className="font-rounded text-[12.5px] text-ink font-medium whitespace-nowrap">{d.label}</span>
              {d.badge ? <span className="size-4 rounded-full grid place-items-center text-[10px] font-bold text-base" style={{ background: "rgb(var(--gold))" }}>{d.badge}</span> : null}
            </Glass>
          </Press>
        ))}
      </div>

      <div className="mt-5">{seg === "story" ? <StoryTimeline push={push} /> : <InsightsHub />}</div>
    </div>
  );
};

const StoryTimeline: React.FC<{ push: (n: string, p?: Record<string, unknown>) => void }> = ({ push }) => {
  const s = useSano();
  const nodeColor: Record<string, string> = { milestone: "gold", result: "sky", visit: "life", diagnosis: "warm", companion: "gold" };
  return (
    <div className="anim-fade">
      <h1 className="font-display text-[32px] text-ink">Your story</h1>
      <p className="font-rounded text-[13.5px] text-ink-muted mt-1">Everything that brought you here — assembled, not filed.</p>
      <Press onClick={() => s.setShowRecap(true)} className="w-full text-left mt-4">
        <div className="relative rounded-3xl overflow-hidden h-24">
          <img src={img("recap_path") ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" />
          <div className="absolute inset-0" style={{ background: "linear-gradient(to right, rgb(0 0 0 / 0.6), transparent)" }} />
          <div className="absolute inset-0 flex items-center gap-3 px-4">
            <div className="size-12 rounded-full grid place-items-center glass-strong"><Icon name="play" size={20} className="text-white" /></div>
            <div><p className="font-serif text-[17px] text-white">Play your chapter</p><p className="font-rounded text-[11px] text-white/80">30 seconds · scored · yours</p></div>
          </div>
        </div>
      </Press>
      <div className="mt-5 relative pl-6">
        <div className="absolute left-2 top-2 bottom-2 w-px" style={{ background: "linear-gradient(to bottom, rgb(var(--gold)), rgb(var(--sky)), rgb(var(--warm)))" }} />
        {s.storyEvents.map((e) => (
          <div key={e.id} className="relative mb-5 anim-rise">
            <span className={`absolute -left-[18px] top-1 size-3 rounded-full ${dot(nodeColor[e.kind])}`} style={{ boxShadow: "0 0 10px currentColor" }} />
            <p className="tnum text-[11px] text-ink-muted">{new Date(e.date).toLocaleDateString([], { year: "numeric", month: "short", day: "numeric" })}</p>
            <h3 className="font-serif text-[17px] text-ink leading-tight mt-0.5">{e.title}</h3>
            <p className="font-rounded text-[13px] text-ink-muted mt-0.5 leading-snug">{e.detail}</p>
          </div>
        ))}
      </div>
    </div>
  );
};
function dot(a: string): string { return a === "gold" ? "bg-gold" : a === "sky" ? "bg-sky" : a === "life" ? "bg-life" : a === "warm" ? "bg-warm" : "bg-rose"; }

const InsightsHub: React.FC = () => {
  const s = useSano();
  const [filter, setFilter] = useState<string>("All");
  const cats = ["All", "Patterns", "Milestones", "Heads-ups", "Opportunities"];
  useEffect(() => { s.insights.forEach((i) => s.markInsightSeen(i.id)); /* eslint-disable-next-line */ }, []);
  const sorted = [...s.insights].sort((a, b) => (a.status.t === "saved" ? -1 : 0) - (b.status.t === "saved" ? -1 : 0));
  const filtered = filter === "All" ? sorted : sorted.filter((i) => i.category === filter);
  return (
    <div className="anim-fade">
      <div className="flex gap-2 overflow-x-auto -mx-5 px-5 pb-2">
        {cats.map((c) => <Press key={c} onClick={() => setFilter(c)} className={`shrink-0 rounded-full px-3.5 py-1.5 text-[12.5px] font-rounded font-medium ${filter === c ? "text-base" : "text-ink glass"}`} style={filter === c ? { background: "rgb(var(--ink))" } : undefined}>{c}</Press>)}
      </div>
      <div className="space-y-4 mt-2">{filtered.map((i) => <InsightSpread key={i.id} insight={i} />)}</div>
    </div>
  );
};
const catAccent: Record<string, string> = { Patterns: "sky", Milestones: "gold", "Heads-ups": "attention", Opportunities: "life" };
const InsightSpread: React.FC<{ insight: Insight }> = ({ insight }) => {
  const s = useSano();
  const [why, setWhy] = useState(false);
  const accent = catAccent[insight.category];
  const saved = insight.status.t === "saved";
  return (
    <OrganicCard className="overflow-hidden">
      <div className="h-28 relative">
        {insight.visual.t === "chart" && s.series(insight.visual.id) ? <div className="absolute inset-0 px-2"><GlowChart series={s.series(insight.visual.id)!} scheme={s.scheme} height={112} /></div> : insight.visual.t === "tide" ? <TideView level={0.85} height={112} /> : <SceneVisual seed={insight.visual.t === "scene" ? insight.visual.seed : 3} height={112} />}
      </div>
      <div className="p-4">
        <div className="flex items-center justify-between">
          <Kicker className={accentText[accent]}>{insight.category}</Kicker>
          <button onClick={() => s.toggleInsightSaved(insight.id)} className="press text-ink-muted"><Icon name="bookmark" size={16} className={saved ? "text-gold" : ""} /></button>
        </div>
        <h3 className="font-serif text-[18px] text-ink mt-1 leading-tight">{insight.headline}</h3>
        <p className="font-rounded text-[13px] text-ink-muted mt-1.5 leading-snug">{insight.body}</p>
        {insight.confidence && <p className="font-rounded text-[11.5px] text-ink-muted/80 mt-1.5 italic">{insight.confidence}</p>}
        {insight.status.t === "acted" && <div className="mt-2.5 rounded-xl p-2.5" style={{ background: "rgb(var(--life) / 0.12)" }}><p className="font-rounded text-[12px] text-life flex items-center gap-1.5"><Icon name="check" size={13} />{insight.status.outcome}</p></div>}
        <div className="flex items-center gap-3 mt-3">
          {insight.actionLabel && <Press onClick={() => s.openConversation("insight")} className="rounded-full px-3.5 py-1.5 text-[12.5px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>{insight.actionLabel}</Press>}
          <Press onClick={() => setWhy((v) => !v)} className="text-[12px] font-rounded text-ink-muted">Why am I seeing this?</Press>
        </div>
        {why && <div className="mt-2 space-y-1">{insight.sources.map((src, i) => <p key={i} className="text-[11.5px] font-rounded text-ink-muted">· {src}</p>)}</div>}
      </div>
    </OrganicCard>
  );
};
