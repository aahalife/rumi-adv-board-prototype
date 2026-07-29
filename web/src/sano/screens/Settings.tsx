import React from "react";
import { useSano } from "../store";
import { SoundEngine } from "../sound";
import { OrganicCard, Press, Kicker, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import type { Pathway } from "../types";

/** Settings — preferences, personalization, and a way to preview how Rumi
 *  adapts to a different journey (the alpha "try another condition" switch). */
export const Settings: React.FC = () => {
  const s = useSano();
  const phone = s.persona.officePhone;

  return (
    <div className="px-5 pt-2 pb-12">
      <h2 className="font-display text-[34px] text-ink">Settings</h2>
      <p className="font-rounded text-[13.5px] text-ink-muted mt-0.5">Make Rumi feel like yours.</p>

      {/* who */}
      <OrganicCard className="mt-5 p-4 flex items-center gap-3.5">
        <div className="size-12 rounded-full grid place-items-center font-serif text-[18px] text-base shrink-0" style={{ background: "rgb(var(--warm))" }}>
          {(s.displayFirstName[0] ?? "Y").toUpperCase()}
        </div>
        <div className="min-w-0">
          <p className="font-serif text-[18px] text-ink leading-tight">{s.displayFirstName}{s.profile.lastName ? ` ${s.profile.lastName}` : ""}</p>
          <p className="font-rounded text-[12.5px] text-ink-muted">{s.persona.conditionChip} · {s.persona.officeName}</p>
        </div>
      </OrganicCard>

      {/* appearance */}
      <Section title="Appearance">
        <Segmented
          value={s.appearance === "Day" || s.appearance === "Night" ? s.appearance : "Auto"}
          options={[{ id: "Auto", label: "Auto", glyph: "circle" }, { id: "Day", label: "Day", glyph: "sun.haze" }, { id: "Night", label: "Night", glyph: "moon" }]}
          onPick={(v) => s.setAppearance(v)}
        />
        <p className="font-rounded text-[12px] text-ink-muted mt-2.5 px-1">Two worlds — Clay &amp; Dawn by day, Indigo Night after dark. Auto follows your device.</p>
      </Section>

      {/* sound */}
      <Section title="Sound">
        <Toggle label="Music" detail="Stone Kintsugi, woven softly through the day" on={s.musicOn} onToggle={() => s.setMusicOn(!s.musicOn)} glyph="volume" />
        <Toggle label="Touch tones & effects" detail="Every tap, a small note" on={s.soundOn} onToggle={() => s.setSoundOn(!s.soundOn)} glyph="sparkles" />
      </Section>

      {/* companion voice */}
      <Section title="How Rumi talks to you">
        <div className="flex flex-wrap gap-2">
          {["Straight talk", "Warm & gentle", "Cheerful", "Just the facts"].map((t) => {
            const active = s.tonePreference === t;
            return (
              <Press key={t} onClick={() => s.setTonePreference(t)} className={`rounded-full px-3.5 py-2 text-[13px] font-rounded font-medium ${active ? "text-base" : "text-ink glass"}`} style={active ? { background: "rgb(var(--ink))" } : undefined}>{t}</Press>
            );
          })}
        </div>
      </Section>

      {/* personalization */}
      <Section title="Personalization">
        <Toggle label="Let Rumi tune itself to you" detail="Learns the best time to reach you and the words that land. Only ever to help — never to sell." on={s.epsilonConsent} onToggle={() => s.setEpsilonConsent(!s.epsilonConsent)} glyph="heart" />
      </Section>

      {/* notifications */}
      <Section title="What reaches you">
        {Object.keys(s.notificationClasses).map((k) => (
          <Toggle key={k} label={k} on={s.notificationClasses[k]} onToggle={() => s.toggleNotification(k)} />
        ))}
        <div className="flex items-center justify-between mt-1 px-1">
          <div className="flex items-center gap-2"><Icon name="moon" size={15} className="text-sky" /><span className="font-rounded text-[13.5px] text-ink">Quiet hours</span></div>
          <div className="flex items-center gap-2">
            <Stepper value={s.quietStart} onChange={(v) => s.setQuiet(v, s.quietEnd)} />
            <span className="text-ink-muted text-[12px] font-rounded">to</span>
            <Stepper value={s.quietEnd} onChange={(v) => s.setQuiet(s.quietStart, v)} />
          </div>
        </div>
      </Section>

      {/* preview another journey */}
      <Section title="Preview another journey">
        <p className="font-rounded text-[12px] text-ink-muted mb-2.5 px-1">Rumi adapts to the whole person. Switch the demo persona to feel how symptoms, the care hub, and the companion all change.</p>
        <div className="space-y-2">
          {(["metabolic", "oncology", "procedure", "cardiometabolic"] as Pathway[]).map((p) => {
            const meta = pathwayMeta[p];
            const active = s.pathway === p;
            return (
              <Press key={p} onClick={() => { if (!active) { s.switchPathway(p); SoundEngine.bloom(); } }} className={`w-full text-left rounded-2xl p-3 flex items-center gap-3 glass ${active ? "ring-2 ring-warm" : ""}`}>
                <div className="size-9 rounded-full grid place-items-center shrink-0" style={{ background: `rgb(var(--${meta.accent}) / 0.2)` }}><Icon name={meta.glyph} size={17} className={accentText[meta.accent]} /></div>
                <div className="flex-1 min-w-0"><p className="font-serif text-[15px] text-ink leading-tight">{meta.label}</p><p className="font-rounded text-[11.5px] text-ink-muted">{meta.who}</p></div>
                {active && <Icon name="check" size={17} className="text-warm" />}
              </Press>
            );
          })}
        </div>
      </Section>

      {/* care line */}
      <button onClick={() => { window.location.href = `tel:${phone.replace(/[^0-9]/g, "")}`; }} className="press w-full mt-5 rounded-2xl glass p-3.5 flex items-center gap-3 text-left">
        <div className="size-9 rounded-full grid place-items-center shrink-0" style={{ background: "rgb(var(--life) / 0.2)" }}><Icon name="phone" size={16} className="text-life" /></div>
        <div><p className="font-rounded text-[14px] text-ink font-medium">Call {s.persona.officeName}</p><p className="font-rounded text-[11.5px] text-ink-muted">{phone}</p></div>
      </button>

      {/* reset */}
      <Press sound={false} onClick={() => { if (confirm("Start fresh? This clears everything Rumi has learned on this device.")) s.wipe(); }} className="w-full mt-3 rounded-2xl py-3 font-rounded text-[13.5px]" style={{ color: "rgb(var(--destructive))" }}>
        Reset & start fresh
      </Press>

      <p className="text-center font-display text-[20px] text-ink-muted/60 mt-6">Rumi</p>
      <p className="text-center font-rounded text-[11px] text-ink-muted/60 mt-0.5">Alpha · made with care</p>
    </div>
  );
};

const pathwayMeta: Record<Pathway, { label: string; who: string; glyph: string; accent: string }> = {
  metabolic: { label: "Living with diabetes", who: "Marcus · the long game", glyph: "heart", accent: "warm" },
  oncology: { label: "Through chemotherapy", who: "Elena · cycle by cycle", glyph: "sparkles", accent: "rose" },
  procedure: { label: "A procedure ahead", who: "Sam · prep & recovery", glyph: "activity", accent: "sky" },
  cardiometabolic: { label: "Diabetes & a heart condition", who: "Rosa · heart, sugar & kidneys", glyph: "heart", accent: "rose" },
};

const Section: React.FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
  <div className="mt-6">
    <Kicker className="mb-2.5">{title}</Kicker>
    {children}
  </div>
);

const Toggle: React.FC<{ label: string; detail?: string; on: boolean; onToggle: () => void; glyph?: string }> = ({ label, detail, on, onToggle, glyph }) => (
  <button onClick={onToggle} className="press w-full flex items-center justify-between gap-3 py-2.5 text-left">
    <div className="flex items-start gap-2.5 min-w-0">
      {glyph && <Icon name={glyph} size={16} className="text-ink-muted mt-0.5 shrink-0" />}
      <div className="min-w-0">
        <p className="font-rounded text-[14px] text-ink leading-tight">{label}</p>
        {detail && <p className="font-rounded text-[11.5px] text-ink-muted mt-0.5 leading-snug">{detail}</p>}
      </div>
    </div>
    <span className={`rounded-full relative transition-colors shrink-0 ${on ? "bg-life" : "bg-ink-muted/30"}`} style={{ height: 26, width: 44 }}>
      <span className="absolute top-0.5 size-5 rounded-full bg-white shadow transition-all" style={{ left: on ? 21 : 3 }} />
    </span>
  </button>
);

const Segmented: React.FC<{ value: string; options: { id: string; label: string; glyph: string }[]; onPick: (v: string) => void }> = ({ value, options, onPick }) => (
  <div className="flex gap-1.5 p-1 rounded-full glass">
    {options.map((o) => {
      const active = value === o.id;
      return (
        <button key={o.id} onClick={() => onPick(o.id)} className={`press flex-1 flex items-center justify-center gap-1.5 rounded-full py-2 text-[13px] font-rounded font-semibold transition-colors ${active ? "text-base" : "text-ink"}`} style={active ? { background: "rgb(var(--ink))" } : undefined}>
          <Icon name={o.glyph} size={14} />{o.label}
        </button>
      );
    })}
  </div>
);

function fmtHour(h: number): string {
  const hr = h % 12 === 0 ? 12 : h % 12;
  return `${hr} ${h < 12 ? "AM" : "PM"}`;
}
const Stepper: React.FC<{ value: number; onChange: (v: number) => void }> = ({ value, onChange }) => (
  <div className="flex items-center gap-1.5 rounded-full glass px-1.5 py-1">
    <button onClick={() => onChange((value + 23) % 24)} className="press grid place-items-center size-6 rounded-full text-ink-muted"><Icon name="chevronLeft" size={13} /></button>
    <span className="tnum text-[12.5px] text-ink font-medium w-12 text-center">{fmtHour(value)}</span>
    <button onClick={() => onChange((value + 1) % 24)} className="press grid place-items-center size-6 rounded-full text-ink-muted"><Icon name="chevronRight" size={13} /></button>
  </div>
);
