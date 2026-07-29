import React, { useMemo, useState } from "react";
import { useSano } from "../store";
import { SoundEngine, Haptics } from "../sound";
import { OrganicCard, Press, Kicker, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { Orb } from "../ui/Orb";
import { LifeLibrary, img, capFirst, feelingImage } from "../lifeLibrary";
import type { EntryKind, BodyRegion, SymptomKind, SupportPlan, Medication } from "../types";

type Mode = "pick" | "symptom" | "entry" | "plan" | "done";

const bodyRegions: { id: BodyRegion; x: number; y: number }[] = [
  { id: "Head", x: 60, y: 26 }, { id: "Chest", x: 60, y: 74 },
  { id: "Left arm", x: 26, y: 92 }, { id: "Right arm", x: 94, y: 92 },
  { id: "Belly", x: 60, y: 112 }, { id: "Lower back", x: 60, y: 140 },
  { id: "Left leg", x: 44, y: 186 }, { id: "Right leg", x: 76, y: 186 },
  { id: "Feet & hands", x: 60, y: 222 },
];

const severityLevels: { label: string; v: number }[] = [
  { label: "Barely there", v: 0.15 }, { label: "A little", v: 0.35 },
  { label: "Noticeable", v: 0.55 }, { label: "A lot", v: 0.78 }, { label: "Severe", v: 0.95 },
];

/** Quick log — the heart of the app. A symptom can summon Rumi's support; a meal,
 *  activity, or med becomes a beautiful catalog entry. */
export const QuickLog: React.FC = () => {
  const s = useSano();
  const linkedMed = s.quickLogMedID ? s.medications.find((m) => m.id === s.quickLogMedID) ?? null : null;

  const [mode, setMode] = useState<Mode>("pick");
  const [entryKind, setEntryKind] = useState<EntryKind>("Meals");
  const [plan, setPlan] = useState<SupportPlan | null>(null);
  const [planKind, setPlanKind] = useState<string>("");

  const close = () => { s.setShowQuickLog(false); s.setQuickLogMedID(null); };

  return (
    <div className="px-5 pt-2 pb-10 min-h-[60vh]">
      {mode !== "pick" && mode !== "done" && (
        <button onClick={() => setMode("pick")} className="press inline-flex items-center gap-1 text-ink-muted mb-3"><Icon name="chevronLeft" size={16} /><span className="font-rounded text-[13px]">Back</span></button>
      )}

      {mode === "pick" && <PickStep linkedMed={linkedMed} onSymptom={() => setMode("symptom")} onEntry={(k) => { setEntryKind(k); setMode("entry"); }} />}

      {mode === "symptom" && (
        <SymptomStep
          linkedMedID={linkedMed?.id ?? null}
          onLogged={(p, kind) => { setPlan(p); setPlanKind(kind); setMode("plan"); }}
        />
      )}

      {mode === "entry" && <EntryStep kind={entryKind} linkedMed={linkedMed} onDone={() => setMode("done")} />}

      {mode === "plan" && plan && <PlanStep plan={plan} kind={planKind} onClose={close} />}

      {mode === "done" && <DoneStep onClose={close} />}
    </div>
  );
};

// ---------- Step 1: pick ----------
const PickStep: React.FC<{ linkedMed: Medication | null; onSymptom: () => void; onEntry: (k: EntryKind) => void }> = ({ linkedMed, onSymptom, onEntry }) => {
  const s = useSano();
  return (
    <div className="anim-rise">
      <h2 className="font-display text-[32px] text-ink">What's worth noting?</h2>
      <p className="font-rounded text-[13.5px] text-ink-muted mt-0.5">{linkedMed ? `Near ${linkedMed.name} — I'll keep it together.` : "A quick log. I'll do the remembering."}</p>
      <div className="grid grid-cols-2 gap-3 mt-5">
        <BigTile imageName={s.persona.heroImage} accent="warm" label="A symptom" detail="How you're feeling" onClick={onSymptom} />
        <BigTile imageName="grain_bowl_chicken_quinoa" accent="life" label="A meal" detail="What's on the plate" onClick={() => onEntry("Meals")} />
        <BigTile imageName="yoga_mat_rolled" accent="sky" label="Activity" detail="Walk, yoga, gardening — any active moment" onClick={() => onEntry("Moves")} />
        <BigTile imageName="medicine_bottle_pills" accent="gold" label="A medication" detail="What you took" onClick={() => onEntry("Meds")} />
      </div>
    </div>
  );
};

const BigTile: React.FC<{ imageName: string; accent: string; label: string; detail: string; onClick: () => void }> = ({ imageName, accent, label, detail, onClick }) => (
  <Press onClick={onClick} className="text-left">
    <OrganicCard className="p-3.5 h-full overflow-hidden">
      <div className="h-20 rounded-2xl overflow-hidden ring-1 ring-white/30 relative"><img src={img(imageName) ?? ""} alt="" className="absolute inset-0 h-full w-full object-cover" /></div>
      <p className="font-serif text-[17px] text-ink mt-3">{label}</p>
      <p className="font-rounded text-[12px] text-ink-muted mt-0.5">{detail}</p>
    </OrganicCard>
  </Press>
);

// ---------- Step 2a: symptom ----------
const SymptomStep: React.FC<{ linkedMedID: string | null; onLogged: (p: SupportPlan, kind: string) => void }> = ({ linkedMedID, onLogged }) => {
  const s = useSano();
  const [kind, setKind] = useState<SymptomKind | null>(null);
  const [sev, setSev] = useState<number>(2);
  const [region, setRegion] = useState<BodyRegion | null>(null);
  const [note, setNote] = useState("");

  const log = () => {
    if (!kind) return;
    const plan = s.addLog(kind.name, severityLevels[sev].v, note.trim() || null, region, linkedMedID);
    Haptics.bloom();
    SoundEngine.bloom();
    onLogged(plan, kind.name);
  };

  if (!kind) {
    return (
      <div className="anim-rise">
        <h2 className="font-display text-[30px] text-ink">What's going on?</h2>
        <p className="font-rounded text-[13px] text-ink-muted mt-0.5">Pick what fits — these are tuned to {s.persona.conditionChip.toLowerCase()}.</p>
        <div className="grid grid-cols-2 gap-2.5 mt-4">
          {s.persona.symptomKinds.map((k) => (
            <Press key={k.name} onClick={() => { setKind(k); SoundEngine.glass(); }} className="text-left">
              <OrganicCard className="p-3.5 flex items-center gap-3">
                <div className="size-14 rounded-2xl overflow-hidden shrink-0 relative ring-1 ring-white/30"><img src={img(symptomImageName(k, s.persona.heroImage)) ?? ""} alt="" className="absolute inset-0 h-full w-full object-cover" /></div>
                <span className="font-serif text-[15px] text-ink leading-tight">{k.name}</span>
              </OrganicCard>
            </Press>
          ))}
        </div>
      </div>
    );
  }

  const high = severityLevels[sev].v >= 0.65;
  return (
    <div className="anim-rise space-y-5">
      <div className="flex items-center gap-3">
        <div className="size-14 rounded-2xl overflow-hidden shrink-0 relative ring-1 ring-white/30"><img src={img(symptomImageName(kind, s.persona.heroImage)) ?? ""} alt="" className="absolute inset-0 h-full w-full object-cover" /></div>
        <div><h2 className="font-serif text-[22px] text-ink leading-tight">{kind.name}</h2><button onClick={() => setKind(null)} className="press text-[12px] font-rounded text-ink-muted">change</button></div>
      </div>

      {/* severity */}
      <div>
        <Kicker className="mb-2.5">How strong?</Kicker>
        <div className="flex items-end gap-1.5">
          {severityLevels.map((lvl, i) => (
            <button key={i} onClick={() => { setSev(i); SoundEngine.tick(); Haptics.tick(); }} className="press flex-1 rounded-xl transition-all" style={{ height: 26 + i * 12, background: i <= sev ? `rgb(var(--${high && i >= 3 ? "attention" : "warm"}))` : "rgb(var(--ink-muted) / 0.18)", opacity: i <= sev ? 1 : 0.6 }} />
          ))}
        </div>
        <p className={`font-rounded text-[14px] mt-2 font-medium ${high ? "text-attention" : "text-warm"}`}>{severityLevels[sev].label}</p>
      </div>

      {/* body map */}
      {kind.needsBodyMap && (
        <div>
          <Kicker className="mb-2">Where? <span className="text-ink-muted/60 normal-case tracking-normal font-normal">(tap the map)</span></Kicker>
          <BodyMap selected={region} onSelect={(r) => { setRegion(r); SoundEngine.tick(); Haptics.tick(); }} />
        </div>
      )}

      {/* note */}
      <div>
        <Kicker className="mb-2">Anything to add?</Kicker>
        <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={2} placeholder="When it started, what helped, how it felt…" className="w-full rounded-2xl glass px-4 py-3 font-rounded text-[14px] text-ink outline-none resize-none placeholder:text-ink-muted/60" />
      </div>

      <Press onClick={log} className="w-full rounded-full py-3.5 font-rounded font-semibold text-[15px] flex items-center justify-center gap-2" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>
        <Icon name="check" size={17} />Log it{kind.needsBodyMap && !region ? " anyway" : ""}
      </Press>
    </div>
  );
};

const BodyMap: React.FC<{ selected: BodyRegion | null; onSelect: (r: BodyRegion) => void }> = ({ selected, onSelect }) => (
  <OrganicCard className="p-3">
    <div className="flex items-center gap-3">
      <svg viewBox="0 0 120 248" width="108" height="220" className="shrink-0">
        {/* connective silhouette */}
        <g stroke="rgb(var(--ink-muted) / 0.25)" strokeWidth="2" fill="none" strokeLinecap="round">
          <path d="M60 26 L60 140" />
          <path d="M60 74 L26 92 M60 74 L94 92" />
          <path d="M60 140 L44 186 L60 222 M60 140 L76 186 L60 222" />
        </g>
        {bodyRegions.map((r) => {
          const on = selected === r.id;
          return (
            <g key={r.id} onClick={() => onSelect(r.id)} style={{ cursor: "pointer" }}>
              <circle cx={r.x} cy={r.y} r="16" fill="transparent" />
              <circle cx={r.x} cy={r.y} r={on ? 11 : 8} fill={on ? "rgb(var(--warm))" : "rgb(var(--surface))"} stroke={on ? "rgb(var(--warm))" : "rgb(var(--ink-muted) / 0.4)"} strokeWidth="2" style={{ filter: on ? "drop-shadow(0 0 6px rgb(var(--warm)))" : "none", transition: "all 0.2s" }} />
            </g>
          );
        })}
      </svg>
      <div className="flex-1">
        <p className="font-serif text-[18px] text-ink">{selected ?? "Not sure"}</p>
        <p className="font-rounded text-[12px] text-ink-muted mt-1">Tap where it's loudest. Location helps your team more than you'd think.</p>
      </div>
    </div>
  </OrganicCard>
);

function symptomImageName(kind: SymptomKind, _fallback?: string): string {
  return feelingImage(kind.name);
}

// ---------- Step 2b: meal / activity / med ----------
const EntryStep: React.FC<{ kind: EntryKind; linkedMed: Medication | null; onDone: () => void }> = ({ kind, linkedMed, onDone }) => {
  const s = useSano();
  const [text, setText] = useState("");
  const [med, setMed] = useState<Medication | null>(linkedMed ?? (kind === "Meds" ? s.medications[0] ?? null : null));

  const preview = useMemo(() => {
    if (kind === "Meals") return LifeLibrary.matchMeal(text);
    if (kind === "Moves") return LifeLibrary.matchMove(text);
    return { imageName: med ? LifeLibrary.medImage(med.id) : "medicine_bottle_pills", suggestedTitle: med?.name ?? "" };
  }, [kind, text, med]);
  const facts = LifeLibrary.facts(preview.imageName);

  const save = () => {
    if (kind === "Meds") { if (!med) return; s.addEntry("Meds", med.name, undefined, med.id); }
    else { if (!text.trim()) return; s.addEntry(kind, text.trim()); }
    onDone();
  };

  const placeholder = kind === "Meals" ? "What did you eat?" : kind === "Moves" ? "How were you active?" : "";
  const title = kind === "Meals" ? "A meal" : kind === "Moves" ? "Activity" : "A medication";

  return (
    <div className="anim-rise space-y-4">
      <h2 className="font-display text-[30px] text-ink">{title}</h2>

      {/* live preview */}
      <div className="relative rounded-3xl overflow-hidden h-44 ring-1 ring-white/30">
        <img src={img(preview.imageName) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover transition-all duration-500" key={preview.imageName} />
        <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgb(0 0 0 / 0.55), transparent 55%)" }} />
        <div className="absolute bottom-3 left-4 right-4 flex items-end justify-between">
          <div>
            <p className="font-serif text-[18px] text-white leading-tight">{capFirst(text.trim() || preview.suggestedTitle || "…")}</p>
            <p className="font-rounded text-[11px] text-white/80 flex items-center gap-1"><Icon name="sparkles" size={11} />Rumi matched it to a visual</p>
          </div>
          {facts?.calories ? <span className="tnum text-[15px] text-white font-semibold glass-strong rounded-full px-2.5 py-1">{facts.calories} cal</span> : facts?.minutes ? <span className="tnum text-[15px] text-white font-semibold glass-strong rounded-full px-2.5 py-1">{facts.minutes} min</span> : null}
        </div>
      </div>

      {kind === "Meds" ? (
        <div className="space-y-2">
          {s.medications.map((m) => (
            <Press key={m.id} onClick={() => setMed(m)} className={`w-full text-left rounded-2xl p-3 flex items-center gap-3 glass ${med?.id === m.id ? "ring-2 ring-gold" : ""}`}>
              <div className="size-10 rounded-xl overflow-hidden shrink-0 relative"><img src={img(LifeLibrary.medImage(m.id)) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" /></div>
              <div className="flex-1 min-w-0"><p className="font-serif text-[15px] text-ink leading-tight">{m.name}</p><p className="font-rounded text-[11.5px] text-ink-muted">{m.dose}</p></div>
              {med?.id === m.id && <Icon name="check" size={17} className="text-gold" />}
            </Press>
          ))}
        </div>
      ) : (
        <LibraryGrid kind={kind} value={text} onPick={setText} placeholder={placeholder} />
      )}

      <Press onClick={save} className="w-full rounded-full py-3.5 font-rounded font-semibold text-[15px] flex items-center justify-center gap-2" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>
        <Icon name="check" size={17} />Add to my day
      </Press>
    </div>
  );
};

// ---------- Searchable food / activity library ----------
const LibraryGrid: React.FC<{ kind: EntryKind; value: string; onPick: (name: string) => void; placeholder: string }> = ({ kind, value, onPick, placeholder }) => {
  const s = useSano();
  const items = LifeLibrary.library(kind);
  const usage = useMemo(() => {
    const m: Record<string, number> = {};
    s.entries.filter((e) => e.kind === kind).forEach((e) => { const k = e.title.toLowerCase(); m[k] = (m[k] ?? 0) + 1; });
    return m;
  }, [s.entries, kind]);
  const q = value.toLowerCase().trim();
  const exact = items.some((i) => i.name.toLowerCase() === q);
  const filtered = !q || exact ? items : items.filter((i) => i.name.toLowerCase().includes(q) || i.group.toLowerCase().includes(q));
  const usuals = items.filter((i) => (usage[i.name.toLowerCase()] ?? 0) > 0)
    .sort((a, b) => (usage[b.name.toLowerCase()] ?? 0) - (usage[a.name.toLowerCase()] ?? 0)).slice(0, 4);

  const Tile: React.FC<{ name: string; image: string; group: string }> = ({ name, image, group }) => {
    const active = name.toLowerCase() === q;
    return (
      <Press onClick={() => { onPick(name); SoundEngine.tick(); Haptics.tick(); }} className={`text-left rounded-2xl p-2.5 flex items-center gap-2.5 glass ${active ? "ring-2 ring-life" : ""}`}>
        <div className="size-11 rounded-xl overflow-hidden shrink-0 relative ring-1 ring-white/30"><img src={img(image) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" /></div>
        <div className="flex-1 min-w-0"><p className="font-rounded text-[13px] text-ink font-medium leading-tight line-clamp-2">{name}</p><p className="font-rounded text-[10.5px] text-ink-muted">{group}</p></div>
        {active && <Icon name="check" size={14} className="text-life" />}
      </Press>
    );
  };

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2 rounded-full glass px-4 py-2.5">
        <Icon name="search" size={15} className="text-ink-muted" />
        <input value={value} onChange={(e) => onPick(e.target.value)} placeholder={placeholder || "Search, or type your own…"} className="flex-1 bg-transparent outline-none font-rounded text-[14.5px] text-ink placeholder:text-ink-muted/60" />
        {value && <button onClick={() => onPick("")} className="press text-ink-muted/60"><Icon name="x" size={15} /></button>}
      </div>
      {!q && usuals.length > 0 && (
        <div className="space-y-2">
          <Kicker>Your usuals</Kicker>
          <div className="grid grid-cols-2 gap-2">{usuals.map((i) => <Tile key={`u-${i.name}`} {...i} />)}</div>
        </div>
      )}
      <div className="space-y-2">
        <Kicker>{kind === "Meals" ? "The whole menu" : "Everything active"}</Kicker>
        {filtered.length === 0 ? (
          <p className="font-rounded text-[13px] text-ink-muted py-3">No match — keep typing and I'll picture it.</p>
        ) : (
          <div className="grid grid-cols-2 gap-2">{filtered.map((i) => <Tile key={i.name} {...i} />)}</div>
        )}
      </div>
    </div>
  );
};

// ---------- Step 3: the support plan (AI engaged) ----------
const PlanStep: React.FC<{ plan: SupportPlan; kind: string; onClose: () => void }> = ({ plan, kind, onClose }) => {
  const s = useSano();
  const [guideAdded, setGuideAdded] = useState(false);
  const [messaged, setMessaged] = useState(false);
  const date = new Date().toLocaleDateString([], { month: "short", day: "numeric" });

  const addToGuide = () => {
    if (guideAdded) return;
    s.addGuideItem("Question", plan.guideQuestion, `From a ${kind.toLowerCase()} log · ${date}`);
    setGuideAdded(true);
  };
  const message = () => {
    if (messaged) return;
    s.startThread({ practice: s.persona.officeName, member: s.persona.officeName, role: "Care team", mode: "inApp", category: "medical", text: plan.draftMessage, origin: `From a ${kind.toLowerCase()} log · ${date}` });
    setMessaged(true);
    SoundEngine.send();
  };
  const callOffice = () => { window.location.href = `tel:${s.persona.officePhone.replace(/[^0-9]/g, "")}`; };

  return (
    <div className="anim-rise space-y-5">
      {/* the companion speaks */}
      <div className="flex flex-col items-center text-center pt-1">
        <Orb size={84} state="speaking" scheme={s.scheme} />
        <p className="font-serif text-[18px] text-ink leading-relaxed mt-4" style={{ textShadow: "0 0 16px rgb(var(--warm) / 0.35)" }}>{plan.message}</p>
      </div>

      {plan.urgent && (
        <OrganicCard className="p-4" style={{ background: "linear-gradient(150deg, rgb(var(--attention) / 0.2), rgb(var(--surface)))" }}>
          <div className="flex items-center gap-2"><Icon name="thermometer" size={16} className="text-attention" /><p className="font-serif text-[15px] text-ink">This one's worth acting on now.</p></div>
        </OrganicCard>
      )}

      {/* tips */}
      <OrganicCard className="p-4">
        <Kicker className="text-life mb-2">What helps right now</Kicker>
        <div className="space-y-2.5">
          {plan.tips.map((t, i) => (
            <div key={i} className="flex gap-2.5 items-start"><span className="size-5 rounded-full grid place-items-center shrink-0 mt-0.5" style={{ background: "rgb(var(--life) / 0.18)" }}><span className="size-1.5 rounded-full bg-life" /></span><p className="font-rounded text-[13.5px] text-ink/90 leading-snug">{t}</p></div>
          ))}
        </div>
      </OrganicCard>

      {/* actions — the natural flow to the care team */}
      <div className="space-y-2.5">
        <Press onClick={() => { onClose(); s.openConversation(`symptom:${kind}`); }} className="w-full rounded-2xl p-3.5 flex items-center gap-3 text-left" style={{ background: "rgb(var(--ink))" }}>
          <Icon name="message-circle" size={18} className="text-base" />
          <div className="flex-1"><p className="font-rounded text-[14px] font-semibold text-base">Talk it through with Rumi</p><p className="font-rounded text-[11.5px] text-base/70">Sit with it, find the next small step</p></div>
        </Press>

        <ActionRow glyph="book" accent="gold" done={guideAdded} label={guideAdded ? "Added to your visit guide" : "Add to my visit guide"} detail={guideAdded ? "It'll be ready for your next visit" : plan.guideQuestion} onClick={addToGuide} />
        <ActionRow glyph="send" accent="sky" done={messaged} label={messaged ? `Sent to ${s.persona.officeName}` : `Message ${s.persona.officeName}`} detail={messaged ? "They'll see it with your log attached" : "I've drafted it — you send it"} onClick={message} />
        <ActionRow glyph="phone" accent="life" label={`Call ${s.persona.officeName}`} detail={s.persona.officePhone} onClick={callOffice} />
      </div>

      <Press sound={false} onClick={onClose} className="w-full rounded-full py-3 font-rounded text-[14px] text-ink-muted">Done for now</Press>
    </div>
  );
};

const ActionRow: React.FC<{ glyph: string; accent: string; label: string; detail: string; done?: boolean; onClick: () => void }> = ({ glyph, accent, label, detail, done, onClick }) => (
  <Press onClick={onClick} className="w-full rounded-2xl glass p-3.5 flex items-center gap-3 text-left">
    <div className="size-9 rounded-full grid place-items-center shrink-0" style={{ background: `rgb(var(--${accent}) / 0.18)` }}><Icon name={done ? "check" : glyph} size={16} className={accentText[accent]} /></div>
    <div className="flex-1 min-w-0"><p className="font-rounded text-[14px] text-ink font-medium leading-tight">{label}</p><p className="font-rounded text-[11.5px] text-ink-muted mt-0.5 line-clamp-1">{detail}</p></div>
    {!done && <Icon name="chevronRight" size={16} className="text-ink-muted" />}
  </Press>
);

// ---------- Step 4: entry logged ----------
const DoneStep: React.FC<{ onClose: () => void }> = ({ onClose }) => {
  React.useEffect(() => { const t = setTimeout(onClose, 1100); return () => clearTimeout(t); }, [onClose]);
  return (
    <div className="flex flex-col items-center justify-center text-center py-16 anim-rise">
      <div className="size-20 rounded-full grid place-items-center anim-bloom" style={{ background: "radial-gradient(circle, rgb(var(--life)), rgb(var(--life) / 0.6))", boxShadow: "0 0 40px rgb(var(--life) / 0.6)" }}>
        <Icon name="check" size={36} className="text-base" />
      </div>
      <p className="font-serif text-[20px] text-ink mt-5">Logged. It's in your day.</p>
      <p className="font-rounded text-[13px] text-ink-muted mt-1">Find it in Life, catalogued and beautiful.</p>
    </div>
  );
};
