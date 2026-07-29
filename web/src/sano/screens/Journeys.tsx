import React, { useMemo, useState } from "react";
import { useSano } from "../store";
import { OrganicCard, Glass, Press, Kicker, ProvenanceChip, SponsorChip, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { Sheet } from "../ui/Sheet";
import { HubHeader, SectionTitle } from "./nav";
import { img, fmtMonthDay } from "../lifeLibrary";
import type { Journey, Program, MemoryGlimpse } from "../types";

export const Journeys: React.FC = () => {
  const s = useSano();
  const [viewer, setViewer] = useState<number | null>(null);
  const [sponsor, setSponsor] = useState<Program | null>(null);
  const gardenCount = s.journeys.reduce((a, j) => a + j.habits.reduce((x, h) => x + h.keptDates.length, 0), 0);

  return (
    <div className="absolute inset-0 overflow-y-auto px-5 pb-32">
      <HubHeader title="Journeys" subtitle="Small things, placed where your life actually is." />

      {/* held moments */}
      <div className="mt-5">
        <Kicker className="text-rose mb-2.5">Held moments</Kicker>
        <div className="flex gap-3 overflow-x-auto -mx-5 px-5 pb-2">
          {s.memories.map((m, i) => <MemoryOrb key={m.id} mem={m} onClick={() => setViewer(i)} index={i} />)}
          <button onClick={() => s.addMemoryGlimpse("recap_garden", "A small good moment")} className="press shrink-0 size-24 rounded-full grid place-items-center glass"><Icon name="plus" size={22} className="text-ink-muted" /></button>
        </div>
      </div>

      {/* light garden */}
      <OrganicCard className="mt-5 p-4">
        <LightGarden count={gardenCount} />
        <p className="font-rounded text-[13px] text-ink-muted mt-3">Your light garden — every kept habit adds a glow. {gardenCount} and growing.</p>
      </OrganicCard>

      {/* journeys */}
      <div className="mt-5 space-y-3">
        {s.journeys.map((j) => <JourneyCard key={j.id} journey={j} />)}
      </div>

      {/* programs */}
      <div className="mt-6">
        <SectionTitle>Programs</SectionTitle>
        <p className="font-rounded text-[12.5px] text-ink-muted mt-1 mb-3">Structured support, offered only when clinically right for you.</p>
        <div className="space-y-3">
          {s.programs.filter((p) => !p.declined).map((p) => <ProgramCard key={p.id} program={p} onSponsor={() => setSponsor(p)} />)}
        </div>
      </div>

      {viewer != null && <MemoryViewer memories={s.memories} start={viewer} onClose={() => setViewer(null)} />}
      <Sheet open={sponsor != null} onClose={() => setSponsor(null)}>
        {sponsor && <div className="px-6 pt-3 pb-10"><Kicker className="text-ink-muted">About this sponsorship</Kicker><h2 className="font-serif text-[22px] text-ink mt-1">{sponsor.sponsor}</h2><p className="font-rounded text-[14px] text-ink/90 mt-2 leading-relaxed">{sponsor.sponsorDetail}</p></div>}
      </Sheet>
    </div>
  );
};

const MemoryOrb: React.FC<{ mem: MemoryGlimpse; onClick: () => void; index: number }> = ({ mem, onClick, index }) => (
  <button onClick={onClick} className="press shrink-0 anim-bob" style={{ animationDelay: `${-index * 0.6}s` }}>
    <div className="relative size-24">
      <div className="absolute inset-0 rounded-full overflow-hidden" style={{ boxShadow: "inset 0 2px 8px rgba(255,255,255,0.5), 0 10px 30px -8px rgba(0,0,0,0.3)" }}>
        <img src={img(mem.imageName) ?? mem.photoData ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" />
        <div className="absolute inset-0" style={{ background: "radial-gradient(120% 90% at 32% 22%, rgba(255,255,255,0.55), transparent 45%)" }} />
        <div className="absolute inset-0 rounded-full" style={{ boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.4)" }} />
      </div>
    </div>
  </button>
);

const MemoryViewer: React.FC<{ memories: MemoryGlimpse[]; start: number; onClose: () => void }> = ({ memories, start, onClose }) => {
  const [idx, setIdx] = useState(start);
  const m = memories[idx];
  return (
    <div className="absolute inset-0 z-[60] grid place-items-center" data-no-ripple onClick={onClose} style={{ background: "rgb(0 0 0 / 0.7)", backdropFilter: "blur(8px)" }}>
      <div className="relative" onClick={(e) => e.stopPropagation()}>
        <div className="relative size-72 anim-bloom">
          <div className="absolute inset-0 rounded-full overflow-hidden" style={{ boxShadow: "inset 0 4px 16px rgba(255,255,255,0.45), 0 30px 80px -10px rgba(0,0,0,0.6)" }}>
            <img src={img(m.imageName) ?? m.photoData ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" />
            <div className="absolute inset-0" style={{ background: "radial-gradient(120% 90% at 30% 20%, rgba(255,255,255,0.5), transparent 50%)" }} />
          </div>
        </div>
        <p className="font-serif text-[18px] text-white text-center mt-5">{m.caption}</p>
        <p className="font-rounded text-[12px] text-white/70 text-center mt-1">{fmtMonthDay(m.date)}</p>
        <div className="flex justify-center gap-6 mt-5">
          <button onClick={() => setIdx((i) => (i - 1 + memories.length) % memories.length)} className="press grid place-items-center size-11 rounded-full glass-strong text-white"><Icon name="chevronLeft" size={20} /></button>
          <button onClick={() => setIdx((i) => (i + 1) % memories.length)} className="press grid place-items-center size-11 rounded-full glass-strong text-white"><Icon name="chevronRight" size={20} /></button>
        </div>
      </div>
    </div>
  );
};

const LightGarden: React.FC<{ count: number }> = ({ count }) => {
  const lights = useMemo(() => {
    const n = Math.min(40, Math.max(6, count));
    let seed = 42;
    const rnd = () => { seed = (seed * 9301 + 49297) % 233280; return seed / 233280; };
    return Array.from({ length: n }, (_, i) => ({ x: 4 + rnd() * 92, h: 30 + rnd() * 60, c: ["var(--life)", "var(--gold)", "var(--warm)", "var(--rose)"][i % 4], delay: rnd() * 3 }));
  }, [count]);
  return (
    <div className="relative h-32 overflow-hidden rounded-2xl" style={{ background: "linear-gradient(to top, rgb(var(--life) / 0.12), transparent)" }}>
      {lights.map((l, i) => (
        <div key={i} className="absolute bottom-0 anim-bob" style={{ left: `${l.x}%`, animationDelay: `${l.delay}s`, animationDuration: "4s" }}>
          <div style={{ width: 2, height: `${l.h}px`, background: `rgb(${l.c} / 0.5)`, marginInline: "auto" }} />
          <div className="rounded-full" style={{ width: 8, height: 8, marginTop: -4, background: `rgb(${l.c})`, boxShadow: `0 0 12px rgb(${l.c})` }} />
        </div>
      ))}
    </div>
  );
};

const JourneyCard: React.FC<{ journey: Journey }> = ({ journey }) => {
  const s = useSano();
  return (
    <OrganicCard className="p-4">
      <h3 className="font-serif text-[19px] text-ink leading-tight">{journey.title}</h3>
      <p className="font-rounded text-[13px] text-ink-muted mt-1">{journey.why}</p>
      <div className="mt-3 space-y-2.5">
        {journey.habits.map((h) => {
          const kept = s.keptToday(journey.id, h.id);
          return (
            <div key={h.id} className="flex items-center gap-3">
              <button onClick={() => !kept && s.keepHabit(journey.id, h.id)} className={`press size-10 rounded-full grid place-items-center shrink-0 ${kept ? "" : "glass"}`} style={kept ? { background: "radial-gradient(circle, rgb(var(--gold)), rgb(var(--gold) / 0.6))", boxShadow: "0 0 18px rgb(var(--gold) / 0.7)" } : undefined}>
                {kept ? <Icon name="check" size={18} className="text-base" /> : <span className="size-3 rounded-full" style={{ background: "rgb(var(--ink-muted) / 0.3)" }} />}
              </button>
              <div className="flex-1 min-w-0"><p className="font-rounded text-[14px] text-ink leading-tight">{h.title}</p><p className="font-rounded text-[11.5px] text-ink-muted">{h.contextLine}</p></div>
            </div>
          );
        })}
      </div>
      {journey.planGoal && <p className="mt-2.5 text-[11px] font-rounded text-life flex items-center gap-1"><Icon name="leaf" size={11} />From your care plan</p>}
    </OrganicCard>
  );
};

const ProgramCard: React.FC<{ program: Program; onSponsor: () => void }> = ({ program, onSponsor }) => {
  const s = useSano();
  return (
    <OrganicCard className="p-4">
      <h3 className="font-serif text-[18px] text-ink leading-tight">{program.title}</h3>
      <p className="font-rounded text-[13px] text-ink-muted mt-1">{program.summary}</p>
      <div className="mt-2.5 space-y-1.5">
        <Grammar accent="sky" text={program.clinicalWhy} />
        <Grammar accent="life" text={program.personalFit} />
        {program.patientDividend && <Grammar accent="gold" text={program.patientDividend} />}
      </div>
      {program.enrolled ? (
        <p className="mt-3 flex items-center gap-1.5 text-[13px] font-rounded text-life"><Icon name="check" size={15} />You're in — woven into your world.</p>
      ) : (
        <div className="flex gap-2 mt-3">
          <Press onClick={() => s.enroll(program.id)} className="rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Count me in</Press>
          <Press onClick={() => s.decline(program.id)} className="rounded-full px-4 py-2 text-[13px] font-rounded glass text-ink">Not for me</Press>
        </div>
      )}
      <div className="flex items-center justify-between mt-3">
        <ProvenanceChip text={program.provenance} />
        {program.sponsor && <SponsorChip sponsor={program.sponsor} onClick={onSponsor} />}
      </div>
    </OrganicCard>
  );
};
const Grammar: React.FC<{ accent: string; text: string }> = ({ accent, text }) => (
  <div className="flex gap-2 items-start"><span className={`size-1.5 rounded-full mt-1.5 shrink-0 ${accent === "sky" ? "bg-sky" : accent === "life" ? "bg-life" : "bg-gold"}`} /><p className={`font-rounded text-[12.5px] leading-snug ${accentText[accent]}`}>{text}</p></div>
);
