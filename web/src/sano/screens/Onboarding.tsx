import React, { useEffect, useRef, useState } from "react";
import { useSano } from "../store";
import { SoundEngine } from "../sound";
import { Orb } from "../ui/Orb";
import { Glass, Press, ChromeIcon } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import type { Pathway } from "../types";
import { img } from "../lifeLibrary";

type Stage = "welcome" | "aboutYou" | "path" | "shaping" | "connect" | "health" | "talk" | "epsilon";
const pathChoices: { id: Pathway; label: string; detail: string; glyph: string; image: string }[] = [
  { id: "metabolic", label: "Diabetes, blood pressure & friends", detail: "The long game — numbers, meds, and real life", glyph: "heart", image: "condition_diabetes" },
  { id: "oncology", label: "Cancer treatment", detail: "Chemo, appointments, and the in-between days", glyph: "sparkles", image: "condition_chemo" },
  { id: "procedure", label: "A procedure coming up", detail: "Getting ready, and the recovery after", glyph: "activity", image: "condition_procedure" },
  { id: "cardiometabolic", label: "Diabetes & a heart condition", detail: "Heart, sugar and kidneys — protected together", glyph: "heart", image: "condition_diabetes" },
];

export const Onboarding: React.FC = () => {
  const s = useSano();
  const [stage, setStage] = useState<Stage>("welcome");
  const [first, setFirst] = useState("");
  const [last, setLast] = useState("");
  const [path, setPath] = useState<Pathway>("metabolic");
  const [connected, setConnected] = useState<string[]>([]);
  const [values, setValues] = useState("");
  const [barrier, setBarrier] = useState("");

  useEffect(() => { SoundEngine.playBed("onboarding", 2.6); }, []);

  const advance = (next: Stage) => { SoundEngine.whoosh(); setStage(next); };
  const finish = (tone: string) => {
    SoundEngine.pauseBed(1.2);
    s.completeOnboarding({ firstName: first.trim(), lastName: last.trim(), birthDate: null, pathway: path, connectedSystems: connected, healthConnected: connected.length > 0, values, barrier, tone });
    setTimeout(() => SoundEngine.playBed("ambient", 2.4), 600);
  };

  const orbSize = stage === "welcome" ? 168 : 92;

  return (
    <div className="absolute inset-0 overflow-hidden">
      <img src={img("pastel_gradient_glow_bg") ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover opacity-90" />
      <OnboardingAura />
      <div className="absolute top-3 right-4 z-20">
        <ChromeIcon name={s.musicOn ? "volume" : "mute"} active={s.musicOn} onClick={() => s.setMusicOn(!s.musicOn)} label="Music" />
      </div>

      <div className="absolute inset-0 flex flex-col items-center px-7 pt-14 pb-8 overflow-y-auto">
        <div className="transition-all duration-700" style={{ marginTop: stage === "welcome" ? 24 : 8 }}>
          <Orb size={orbSize} state={stage === "shaping" ? "thinking" : stage === "talk" ? "speaking" : "ambient"} scheme={s.scheme} />
        </div>

        <div key={stage} className="w-full max-w-[360px] anim-rise mt-6">
          {stage === "welcome" && <Welcome onNext={() => advance("aboutYou")} />}
          {stage === "aboutYou" && <AboutYou first={first} last={last} setFirst={setFirst} setLast={setLast} onNext={() => advance("path")} />}
          {stage === "path" && <PathChoice value={path} onPick={(p) => { setPath(p); s.switchPathway(p); }} onNext={() => advance("shaping")} />}
          {stage === "shaping" && <Shaping pathway={path} onNext={() => advance("connect")} />}
          {stage === "connect" && <Connect onConnect={(sys) => { setConnected(sys); advance("health"); }} onSkip={() => advance("health")} />}
          {stage === "health" && <HealthAsk onNext={(sys) => { setConnected((c) => [...c, ...sys]); advance("talk"); }} />}
          {stage === "talk" && <TalkStage values={values} barrier={barrier} setValues={setValues} setBarrier={setBarrier} onNext={() => advance("epsilon")} />}
          {stage === "epsilon" && <Epsilon onDone={(tune) => { s.setEpsilonConsent(tune); finish(s.tonePreference); }} />}
        </div>
      </div>
    </div>
  );
};

const OnboardingAura: React.FC = () => (
  <div className="absolute inset-0 pointer-events-none overflow-hidden">
    {[["var(--warm)", "12%", "18%", 30], ["var(--rose)", "62%", "70%", 36], ["var(--gold)", "78%", "20%", 42]].map(([c, t, l, dur], i) => (
      <div key={i} className="absolute anim-drift" style={{ width: "60%", height: "60%", top: t as string, left: l as string, borderRadius: "50%", opacity: 0.4, filter: "blur(20px)", background: `radial-gradient(circle, rgb(${c}), transparent 65%)`, animationDuration: `${dur}s` }} />
    ))}
  </div>
);

const Title: React.FC<{ children: React.ReactNode; className?: string }> = ({ children, className }) => (
  <h1 className={`font-serif text-[26px] leading-tight text-ink ${className ?? ""}`}>{children}</h1>
);
const PrimaryBtn: React.FC<{ children: React.ReactNode; onClick: () => void; icon?: string }> = ({ children, onClick, icon }) => (
  <Press onClick={onClick} className="w-full rounded-full py-3.5 px-5 text-[15px] font-rounded font-semibold flex items-center justify-center gap-2"
    style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>
    {icon && <Icon name={icon} size={17} />}{children}
  </Press>
);
const GhostBtn: React.FC<{ children: React.ReactNode; onClick: () => void }> = ({ children, onClick }) => (
  <Press onClick={onClick} className="w-full text-center py-2.5 text-[13.5px] font-rounded text-ink-muted">{children}</Press>
);

const Welcome: React.FC<{ onNext: () => void }> = ({ onNext }) => (
  <div className="text-center space-y-5">
    <h1 className="font-display text-[64px] leading-none text-ink">Rumi</h1>
    <p className="font-serif text-[18px] leading-relaxed text-ink/90">Hi. I'm the one who'll remember the small stuff, so you can carry less of it.</p>
    <div className="space-y-2 pt-2">
      <PrimaryBtn onClick={onNext} icon="apple">Continue with Apple</PrimaryBtn>
      <GhostBtn onClick={onNext}>Use a phone number instead</GhostBtn>
    </div>
  </div>
);

const Field: React.FC<{ label: string; value: string; onChange: (v: string) => void; placeholder?: string }> = ({ label, value, onChange, placeholder }) => (
  <label className="block">
    <span className="kicker text-ink-muted">{label}</span>
    <input value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder}
      className="mt-1.5 w-full rounded-2xl px-4 py-3 font-rounded text-[15px] text-ink outline-none glass placeholder:text-ink-muted/60" />
  </label>
);

const AboutYou: React.FC<{ first: string; last: string; setFirst: (v: string) => void; setLast: (v: string) => void; onNext: () => void }> = ({ first, last, setFirst, setLast, onNext }) => (
  <div className="space-y-4">
    <Title>First things first — you.</Title>
    <div className="space-y-3">
      <Field label="First name" value={first} onChange={setFirst} placeholder="What should I call you?" />
      <Field label="Last name" value={last} onChange={setLast} placeholder="So your records line up" />
    </div>
    <p className="text-[12px] font-rounded text-ink-muted flex items-center gap-1.5"><Icon name="lock" size={12} />This stays yours. It only helps me match your hospital's records.</p>
    <PrimaryBtn onClick={onNext}>{first.trim() ? "Nice to meet you — onward" : "I'll stay mysterious for now"}</PrimaryBtn>
  </div>
);

const PathChoice: React.FC<{ value: Pathway; onPick: (p: Pathway) => void; onNext: () => void }> = ({ value, onPick, onNext }) => (
  <div className="space-y-4">
    <Title>What's on your plate right now?</Title>
    <div className="space-y-2.5">
      {pathChoices.map((c) => (
        <Press key={c.id} onClick={() => onPick(c.id)}
          className={`w-full text-left rounded-3xl p-3 flex items-center gap-3 glass ${value === c.id ? "ring-2 ring-warm" : ""}`}>
          <div className="size-14 rounded-2xl overflow-hidden shrink-0 relative">
            <img src={img(c.image) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" />
          </div>
          <div className="min-w-0">
            <p className="font-serif text-[16px] text-ink leading-tight">{c.label}</p>
            <p className="text-[12px] font-rounded text-ink-muted mt-0.5">{c.detail}</p>
          </div>
        </Press>
      ))}
    </div>
    <p className="text-[12px] font-rounded text-ink-muted">Carrying more than one thing? Pick the loudest — we'll get to the rest.</p>
    <PrimaryBtn onClick={onNext}>This one</PrimaryBtn>
  </div>
);

const Shaping: React.FC<{ pathway: Pathway; onNext: () => void }> = ({ pathway, onNext }) => {
  const lines: Record<Pathway, string[]> = {
    metabolic: ["Reading up on the long game — diabetes, blood pressure, kidneys.", "Numbers move slowly here, and direction beats any single day.", "I'll keep the boring, winning stuff easy and the wins visible."],
    oncology: ["Getting the rhythm of your cycles — the queasy days and the good window.", "Protection first: nausea ahead of time, the fever rule always close.", "And I'll guard your good days fiercely, so you can spend them living."],
    procedure: ["Lining up the countdown to your procedure — short list, all of it matters.", "Prehab now, the NSAID stop, the home that's ready for after.", "I'll walk every step with you, before and after the day itself."],
    cardiometabolic: ["Reading across all three — your heart, your sugar, and your kidneys.", "In this body they pull on the same strings, so I'll treat them as one story.", "The daily weigh-in, the low-sodium wins, three doctors kept on one page."],
  };
  const [shown, setShown] = useState(0);
  useEffect(() => { const t = setInterval(() => setShown((n) => Math.min(lines[pathway].length, n + 1)), 900); return () => clearInterval(t); }, [pathway]);
  return (
    <div className="space-y-4">
      <Title>Let me get my bearings…</Title>
      <div className="space-y-2.5">
        {lines[pathway].slice(0, shown).map((l, i) => (
          <div key={i} className="anim-rise flex items-start gap-2.5">
            <span className="size-1.5 rounded-full bg-warm mt-2" />
            <p className="font-rounded text-[14px] text-ink/90 leading-snug">{l}</p>
          </div>
        ))}
      </div>
      {shown >= lines[pathway].length && <PrimaryBtn onClick={onNext}>That's exactly it — keep going</PrimaryBtn>}
    </div>
  );
};

const providers = ["Piedmont Healthcare", "Emory Healthcare", "Northside Hospital", "Midtown Orthopedics", "CVS Pharmacy", "Walgreens", "Anthem Blue Cross"];
const Connect: React.FC<{ onConnect: (sys: string[]) => void; onSkip: () => void }> = ({ onConnect, onSkip }) => {
  const [phase, setPhase] = useState<"pick" | "signin" | "match" | "found">("pick");
  const [picked, setPicked] = useState("");
  const [q, setQ] = useState("");
  const s = useSano();
  if (phase === "pick") return (
    <div className="space-y-3.5">
      <Title>Shall I read up on you?</Title>
      <p className="font-rounded text-[13.5px] text-ink-muted">Connect a provider and I'll quietly gather your story — labs, meds, visits. Read-only, always.</p>
      <div className="rounded-2xl glass px-3.5 py-2.5 flex items-center gap-2"><Icon name="search" size={15} className="text-ink-muted" /><input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Find your hospital or pharmacy" className="bg-transparent outline-none flex-1 font-rounded text-[14px] text-ink placeholder:text-ink-muted/60" /></div>
      <div className="space-y-1.5 max-h-[180px] overflow-y-auto">
        {providers.filter((p) => p.toLowerCase().includes(q.toLowerCase())).map((p) => (
          <Press key={p} onClick={() => { setPicked(p); setPhase("signin"); }} className="w-full text-left rounded-2xl glass px-4 py-3 flex items-center justify-between">
            <span className="font-rounded text-[14px] text-ink">{p}</span><Icon name="chevronRight" size={16} className="text-ink-muted" />
          </Press>
        ))}
      </div>
      <GhostBtn onClick={onSkip}>I'll do this later</GhostBtn>
    </div>
  );
  if (phase === "signin") return (
    <div className="space-y-3.5">
      <div className="kicker text-ink-muted">Secure portal sign-in</div>
      <Title>{picked}</Title>
      <Field label="Username" value="" onChange={() => {}} placeholder="Your portal login" />
      <Field label="Password" value="" onChange={() => {}} placeholder="••••••••" />
      <p className="text-[12px] font-rounded text-ink-muted flex items-center gap-1.5"><Icon name="lock" size={12} />Read-only access. I can never change anything in your chart.</p>
      <PrimaryBtn onClick={() => setPhase("match")}>Sign in securely</PrimaryBtn>
    </div>
  );
  if (phase === "match") return (
    <div className="space-y-3.5">
      <Title>Is this you?</Title>
      <Glass radius={22} className="p-4 space-y-2.5">
        {[["Name", `${s.profile.firstName || s.persona.firstName} ${s.profile.lastName || ""}`.trim() || "Marcus Whitfield"], ["System", picked], ["Record since", "2017"]].map(([k, v]) => (
          <div key={k} className="flex justify-between"><span className="font-rounded text-[13px] text-ink-muted">{k}</span><span className="font-rounded text-[13px] text-ink font-semibold">{v}</span></div>
        ))}
      </Glass>
      <PrimaryBtn onClick={() => { onConnect([picked]); }}>Yes — that's me</PrimaryBtn>
      <GhostBtn onClick={() => setPhase("pick")}>That's not me</GhostBtn>
    </div>
  );
  return null;
};

const healthItems = ["Steps & workouts", "Sleep", "Heart rate & blood pressure", "Blood glucose", "Weight"];
const HealthAsk: React.FC<{ onNext: (sys: string[]) => void }> = ({ onNext }) => {
  const [on, setOn] = useState<Record<string, boolean>>(Object.fromEntries(healthItems.map((i) => [i, true])));
  const [loading, setLoading] = useState(false);
  return (
    <div className="space-y-3.5">
      <Title>Your body already keeps notes.</Title>
      <p className="font-rounded text-[13.5px] text-ink-muted">Apple Health has been quietly logging. Let me read what helps — nothing more.</p>
      <div className="space-y-1.5">
        {healthItems.map((i) => (
          <button key={i} onClick={() => setOn((m) => ({ ...m, [i]: !m[i] }))} className="press w-full flex items-center justify-between rounded-2xl glass px-4 py-3">
            <span className="font-rounded text-[14px] text-ink">{i}</span>
            <span className={`w-10 h-6 rounded-full relative transition-colors ${on[i] ? "bg-life" : "bg-ink-muted/30"}`}><span className={`absolute top-0.5 size-5 rounded-full bg-white transition-all ${on[i] ? "left-[18px]" : "left-0.5"}`} /></span>
          </button>
        ))}
      </div>
      <PrimaryBtn onClick={() => { setLoading(true); setTimeout(() => onNext(["Apple Health"]), 900); }}>{loading ? "Connecting…" : "Connect Apple Health"}</PrimaryBtn>
      <GhostBtn onClick={() => onNext([])}>Not now</GhostBtn>
    </div>
  );
};

const TalkStage: React.FC<{ values: string; barrier: string; setValues: (v: string) => void; setBarrier: (v: string) => void; onNext: () => void }> = ({ values, barrier, setValues, setBarrier, onNext }) => {
  const [q, setQ] = useState(0);
  const questions = ["What matters most to you right now — the real reason behind the numbers?", "And what's the hardest part of keeping up with all this?"];
  return (
    <div className="space-y-4">
      <p className="font-serif text-[20px] text-ink leading-snug">{questions[q]}</p>
      <textarea value={q === 0 ? values : barrier} onChange={(e) => (q === 0 ? setValues : setBarrier)(e.target.value)} rows={3}
        placeholder="Say it however it comes…" className="w-full rounded-2xl glass px-4 py-3 font-rounded text-[14px] text-ink outline-none resize-none placeholder:text-ink-muted/60" />
      <PrimaryBtn onClick={() => (q === 0 ? setQ(1) : onNext())}>{q === 0 ? "Next" : "Almost there"}</PrimaryBtn>
    </div>
  );
};

const Epsilon: React.FC<{ onDone: (tune: boolean) => void }> = ({ onDone }) => (
  <div className="space-y-4">
    <Title>One more thing — want me to really get you?</Title>
    <p className="font-rounded text-[13.5px] text-ink-muted leading-relaxed">If you let me, I'll learn the little things — the best time to reach you, the words that land, the rhythm of your week. Only ever to help. Never to sell.</p>
    <div className="grid grid-cols-2 gap-2.5">
      <Press onClick={() => onDone(true)} className="rounded-2xl py-3.5 text-[14px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Yes, tune it to me</Press>
      <Press onClick={() => onDone(false)} className="rounded-2xl py-3.5 text-[14px] font-rounded font-semibold glass text-ink">No thanks</Press>
    </div>
  </div>
);
