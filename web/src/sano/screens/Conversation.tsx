import React, { useEffect, useRef, useState } from "react";
import { useSano } from "../store";
import { SoundEngine } from "../sound";
import { FUNCTIONS_URL } from "../ai";
import { Orb } from "../ui/Orb";
import { Glass, Press, OrganicCard, Kicker, ProvenanceChip } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { GlowChart } from "../ui/DataViz";
import { conversationPalette } from "../theme";
import { LivingGradient } from "../ui/LivingGradient";
import type { ConversationTurn, RichElement, Pathway } from "../types";

const suggestionsByPath: Record<Pathway, string[]> = {
  metabolic: ["How's my blood pressure looking?", "Help me with Thursday's refill", "I keep getting leg cramps"],
  oncology: ["What should I expect this week?", "I'm feeling really tired", "Plan cycle 4's anti-nausea"],
  procedure: ["What do I do before surgery?", "My knee hurts tonight", "When do I stop the ibuprofen?"],
  cardiometabolic: ["How's today's weigh-in?", "My kidney risk, explained", "A little short of breath", "Help me with my refill"],
};

export const Conversation: React.FC = () => {
  const s = useSano();
  const [draft, setDraft] = useState("");
  const [showVoice, setShowVoice] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const palette = conversationPalette(s.scheme);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [s.turns]);

  const send = (text: string) => { const t = text.trim(); if (!t) return; s.sendMessage(t); setDraft(""); };

  return (
    <div className="absolute inset-0 z-40 overflow-hidden anim-fade">
      <LivingGradient scheme={s.scheme} conversation={palette} />
      {/* drifting motes */}
      <Motes scheme={s.scheme} />

      {/* header */}
      <div className="absolute top-0 inset-x-0 z-20 px-5 pt-3 pb-2">
        <div className="flex justify-center"><div className="h-1.5 w-10 rounded-full" style={{ background: "rgb(var(--ink-muted) / 0.35)" }} /></div>
        <div className="flex items-center justify-between mt-2">
          <button onClick={s.closeConversation} className="press grid place-items-center size-10 rounded-full glass text-ink/80"><Icon name="chevronDown" size={18} /></button>
          <h2 className="font-display text-[24px] text-ink">Rumi</h2>
          <div className="flex items-center gap-2">
            <button onClick={() => s.setAppearance(s.scheme === "night" ? "Day" : "Night")} className="press grid place-items-center size-10 rounded-full glass text-ink/80"><Icon name={s.scheme === "night" ? "sun.haze" : "moon"} size={16} /></button>
            <button onClick={() => s.setMusicOn(!s.musicOn)} className={`press grid place-items-center size-10 rounded-full glass ${s.musicOn ? "text-gold" : "text-ink-muted"}`}><Icon name={s.musicOn ? "volume" : "mute"} size={16} /></button>
          </div>
        </div>
      </div>

      {/* stream */}
      <div ref={scrollRef} className="absolute inset-0 overflow-y-auto px-5 pt-24 pb-44">
        <div className="flex justify-center mb-6">
          <Orb size={108} state={s.orbState} scheme={s.scheme} />
        </div>
        <div className="space-y-5 max-w-[400px] mx-auto">
          {s.turns.map((t) => <TurnView key={t.id} turn={t} />)}
          {s.isThinking && <ThinkingDots />}
        </div>
      </div>

      {/* suggestions + input */}
      <div className="absolute bottom-0 inset-x-0 z-20 px-4 pb-4 pt-2" style={{ background: `linear-gradient(to top, rgb(var(--base) / 0.6), transparent)` }}>
        {s.turns.length <= 1 && (
          <div className="flex gap-2 overflow-x-auto pb-2.5 -mx-4 px-4">
            {suggestionsByPath[s.pathway].map((q) => (
              <Press key={q} onClick={() => send(q)} className="shrink-0 rounded-full glass px-3.5 py-2 text-[12.5px] font-rounded text-ink whitespace-nowrap">{q}</Press>
            ))}
          </div>
        )}
        <Glass radius={26} className="flex items-center gap-2 pl-4 pr-2 py-2">
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter") send(draft); }}
            placeholder="Say anything…"
            className="flex-1 bg-transparent outline-none font-rounded text-[15px] text-ink placeholder:text-ink-muted/60"
          />
          <button
            onClick={() => { if (draft.trim()) send(draft); else setShowVoice(true); }}
            className="press grid place-items-center size-9 rounded-full"
            style={{ background: draft.trim() ? "rgb(var(--ink))" : "rgb(var(--ink-muted) / 0.25)" }}
          >
            <Icon name={draft.trim() ? "send" : "mic"} size={16} className={draft.trim() ? "text-base" : "text-ink/70"} />
          </button>
        </Glass>
      </div>

      {showVoice && <VoiceOverlay onClose={() => setShowVoice(false)} />}
    </div>
  );
};

const VoiceOverlay: React.FC<{ onClose: () => void }> = ({ onClose }) => {
  const s = useSano();
  const [status, setStatus] = useState("Opening mic…");
  const [level, setLevel] = useState(0);
  const [heard, setHeard] = useState("");
  const [reply, setReply] = useState("");
  const runningRef = useRef(true);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    runningRef.current = true;
    void startListening();
    return () => cleanup();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const cleanup = () => {
    runningRef.current = false;
    recorderRef.current?.stop();
    recorderRef.current = null;
    streamRef.current?.getTracks().forEach((track) => track.stop());
    streamRef.current = null;
    audioRef.current?.pause();
    audioRef.current = null;
    SoundEngine.playBed("ambient", 1.2);
  };

  const startListening = async (): Promise<void> => {
    try {
      SoundEngine.pauseBed(0.25);
      audioRef.current?.pause();
      setReply("");
      setHeard("");
      setStatus("Listening — I’ll pause when you’re done");
      const stream = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true } });
      streamRef.current = stream;
      const chunks: Blob[] = [];
      const recorder = new MediaRecorder(stream, { mimeType: MediaRecorder.isTypeSupported("audio/webm") ? "audio/webm" : undefined });
      recorderRef.current = recorder;
      recorder.ondataavailable = (event: BlobEvent) => { if (event.data.size > 0) chunks.push(event.data); };
      recorder.onstop = () => {
        stream.getTracks().forEach((track) => track.stop());
        if (!runningRef.current || chunks.length === 0) return;
        void handleTurn(new Blob(chunks, { type: recorder.mimeType || "audio/webm" }));
      };
      recorder.start();
      monitorSilence(stream, () => recorder.state === "recording" && recorder.stop());
    } catch {
      setStatus("Voice needs microphone access in this browser.");
    }
  };

  const monitorSilence = (stream: MediaStream, commit: () => void): void => {
    const audioContext = new AudioContext();
    const source = audioContext.createMediaStreamSource(stream);
    const analyser = audioContext.createAnalyser();
    analyser.fftSize = 1024;
    source.connect(analyser);
    const data = new Uint8Array(analyser.fftSize);
    let heardSpeech = false;
    let quietFrames = 0;
    let frames = 0;
    const tick = () => {
      if (!runningRef.current || recorderRef.current?.state !== "recording") {
        void audioContext.close();
        return;
      }
      analyser.getByteTimeDomainData(data);
      let sum = 0;
      for (const v of data) {
        const centered = (v - 128) / 128;
        sum += centered * centered;
      }
      const rms = Math.sqrt(sum / data.length);
      const energy = Math.min(rms * 8, 1);
      setLevel(energy);
      frames += 1;
      if (energy > 0.07) heardSpeech = true;
      // ~0.75s of quiet after real speech commits the turn — long enough that
      // a natural mid-sentence pause doesn't cut you off.
      if (heardSpeech && frames > 40 && energy < 0.03) quietFrames += 1;
      else quietFrames = 0;
      if (heardSpeech && quietFrames > 44) {
        commit();
        void audioContext.close();
        return;
      }
      requestAnimationFrame(tick);
    };
    tick();
  };

  const handleTurn = async (blob: Blob): Promise<void> => {
    setLevel(0);
    setStatus("Got it…");
    const text = await transcribe(blob);
    if (!runningRef.current) return;
    if (!text) {
      // Heard nothing usable — keep listening quietly instead of scolding.
      setStatus("Still here — take your time…");
      setTimeout(() => { if (runningRef.current) void startListening(); }, 500);
      return;
    }
    setHeard(text);
    setStatus("Thinking…");
    const answer = await s.sendVoiceMessage(text);
    if (!runningRef.current) return;
    setReply(answer);
    setStatus("Rumi is speaking");
    await speak(answer);
    if (runningRef.current) void startListening();
  };

  const transcribe = async (blob: Blob): Promise<string> => {
    const form = new FormData();
    form.append("model_id", "scribe_v2");
    form.append("diarize", "false");
    form.append("tag_audio_events", "false");
    form.append("no_verbatim", "true");
    form.append("file", blob, "voice.webm");
    const response = await fetch(`${FUNCTIONS_URL}/voice/stt`, { method: "POST", body: form });
    if (!response.ok) return "";
    const json = (await response.json()) as { text?: string };
    return json.text?.trim() ?? "";
  };

  const speak = async (text: string): Promise<void> => {
    const response = await fetch(`${FUNCTIONS_URL}/voice/tts`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text, model_id: "eleven_turbo_v2_5" }),
    });
    if (!response.ok) return;
    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    const audio = new Audio(url);
    audioRef.current = audio;
    await audio.play().catch(() => undefined);
    await new Promise<void>((resolve) => {
      audio.onended = () => { URL.revokeObjectURL(url); resolve(); };
      audio.onerror = () => { URL.revokeObjectURL(url); resolve(); };
    });
  };

  const close = () => {
    cleanup();
    onClose();
  };

  const glow = 0.5 + level * 0.5;
  return (
    <div className="absolute inset-0 z-50 overflow-hidden anim-fade" style={{ background: "rgb(var(--base) / 0.72)", backdropFilter: "blur(18px)" }}>
      <div className="absolute inset-x-0 bottom-0 h-[60%] pointer-events-none" style={{
        opacity: 0.95,
        background: `radial-gradient(circle at 50% 100%, rgba(255,255,255,${0.72 * glow}), transparent 36%), radial-gradient(circle at 12% 100%, rgb(var(--sky) / ${0.5 * glow}), transparent 44%), radial-gradient(circle at 88% 100%, rgb(var(--rose) / ${0.44 * glow}), transparent 44%), linear-gradient(to top, rgba(255,255,255,${0.3 * glow}), transparent)`,
        filter: "blur(14px)",
      }} />
      <div className="absolute inset-0 pointer-events-none">
        {Array.from({ length: 24 }).map((_, i) => <span key={i} className="voice-particle" style={{ left: `${(i * 41) % 100}%`, width: 4, height: 4, animationDuration: "9s", animationDelay: `${-i * 0.36}s`, opacity: 0.18 + level * 0.4 }} />)}
      </div>
      <div className="relative z-10 h-full flex flex-col items-center px-8 pt-5 pb-10 text-center">
        <div className="w-full flex items-center justify-between">
          <button onClick={close} className="press grid place-items-center size-11 rounded-full glass text-ink"><Icon name="chevronDown" size={18} /></button>
          <h2 className="font-display text-[24px] text-ink">Out loud</h2>
          <button onClick={() => s.setMusicOn(!s.musicOn)} className="press grid place-items-center size-11 rounded-full glass text-ink"><Icon name={s.musicOn ? "volume" : "mute"} size={16} /></button>
        </div>
        <div className="flex-1 grid place-items-center">
          <button onClick={close} className="press relative rounded-full" aria-label="End voice mode">
            <span className="absolute -inset-9 rounded-full" style={{ background: `conic-gradient(from 40deg, rgb(var(--sky)), white, rgb(var(--rose)), rgb(var(--life)), rgb(var(--gold)), white, rgb(var(--sky)))`, filter: "blur(20px)", opacity: 0.26 + level * 0.45 }} />
            <Orb size={190} state={s.orbState === "ambient" ? "listening" : s.orbState} scheme={s.scheme} />
          </button>
        </div>
        <div className="min-h-44 space-y-3">
          <p className="kicker text-ink-muted">{status}</p>
          {heard && <p className="font-serif italic text-[16px] text-ink-muted line-clamp-2">“{heard}”</p>}
          {reply && <p className="font-serif text-[20px] text-ink leading-relaxed" style={{ textShadow: "0 0 18px rgb(var(--sky) / 0.35)" }}>{reply}</p>}
          <p className="font-rounded text-[12px] text-ink-muted/80">Hands-free — pause and I’ll answer.</p>
        </div>
      </div>
    </div>
  );
};

const Motes: React.FC<{ scheme: string }> = ({ scheme }) => (
  <div className="absolute inset-0 pointer-events-none overflow-hidden">
    {Array.from({ length: 18 }).map((_, i) => (
      <span key={i} className="absolute rounded-full anim-bob" style={{
        left: `${(i * 37) % 100}%`, top: `${(i * 53) % 100}%`, width: 3 + (i % 3), height: 3 + (i % 3),
        background: scheme === "night" ? "rgba(180,200,255,0.5)" : "rgba(255,210,180,0.6)",
        filter: "blur(0.5px)", animationDuration: `${5 + (i % 5)}s`, animationDelay: `${-i * 0.4}s`, opacity: 0.5,
      }} />
    ))}
  </div>
);

const TurnView: React.FC<{ turn: ConversationTurn }> = ({ turn }) => {
  if (turn.role === "user") {
    return (
      <div className="flex justify-end anim-rise">
        <Glass radius={22} className="max-w-[80%] px-4 py-2.5">
          <p className="font-rounded text-[15px] text-ink leading-snug">{turn.text}</p>
        </Glass>
      </div>
    );
  }
  return (
    <div className="anim-rise space-y-3">
      <p
        className="font-serif text-[18px] leading-relaxed text-ink"
        style={{ textShadow: turn.streaming ? "0 0 22px rgb(var(--warm) / 0.6)" : "0 0 14px rgb(var(--warm) / 0.35)" }}
      >
        {turn.text}
        {turn.streaming && <span className="inline-block w-1.5 h-4 ml-0.5 align-middle rounded-full bg-warm/70 animate-pulse" />}
      </p>
      {turn.rich.t !== "none" && <RichView turn={turn} />}
    </div>
  );
};

const RichView: React.FC<{ turn: ConversationTurn }> = ({ turn }) => {
  const s = useSano();
  const r = turn.rich;
  if (r.t === "trend") {
    const series = s.series(r.id);
    if (!series) return null;
    return (
      <OrganicCard className="p-3 anim-rise">
        <GlowChart series={series} scheme={s.scheme} height={150} />
        <ProvenanceChip text={series.provenance} className="mt-2 px-1" />
      </OrganicCard>
    );
  }
  if (r.t === "habitProposal") return <ProposalCard accent="life" kicker="Habit proposal" title={r.title} detail={r.context} resolved={turn.richResolved} cta="Hold that spot" doneLabel="Held — I'll be quiet about it" onAccept={() => s.resolveRich(turn.id)} />;
  if (r.t === "refillFix") return <ProposalCard accent="gold" kicker="Refill" title={r.med} detail={r.detail} resolved={turn.richResolved} cta="Switch to delivery" doneLabel="Done — it's handled" onAccept={() => s.resolveRich(turn.id)} />;
  if (r.t === "guideAdd") return (
    <OrganicCard className="p-3.5 flex items-center gap-3 anim-rise"><Icon name="check" size={16} className="text-life" /><p className="font-rounded text-[13.5px] text-ink">Added to your visit guide.</p></OrganicCard>
  );
  if (r.t === "agentAction") return <ProposalCard accent="gold" kicker="I can take this one" title={r.title} detail={r.detail} resolved={turn.richResolved} cta="Approve & go" doneLabel="On it." onAccept={() => s.resolveRich(turn.id)} />;
  if (r.t === "program") {
    const program = s.programs.find((p) => p.title.toLowerCase() === r.title.toLowerCase()) ?? s.programs[0];
    return (
      <OrganicCard className="p-4 anim-rise">
        <Kicker className="text-rose">A door, if you want it</Kicker>
        <h4 className="font-serif text-[16px] text-ink mt-1">{program.title}</h4>
        <p className="font-rounded text-[13px] text-ink-muted mt-1">{program.personalFit}</p>
        <div className="flex gap-2 mt-3">
          <Press onClick={() => { s.enroll(program.id); s.resolveRich(turn.id); }} className="rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Count me in</Press>
          <Press onClick={() => s.resolveRich(turn.id)} className="rounded-full px-4 py-2 text-[13px] font-rounded glass text-ink">Not for me</Press>
        </div>
        {program.sponsor && <p className="text-[11px] font-rounded text-ink-muted mt-2.5">Supported by {program.sponsor} — never changes what I recommend.</p>}
      </OrganicCard>
    );
  }
  return null;
};

const ProposalCard: React.FC<{ accent: string; kicker: string; title: string; detail: string; resolved: boolean; cta: string; doneLabel: string; onAccept: () => void }> = ({ accent, kicker, title, detail, resolved, cta, doneLabel, onAccept }) => (
  <OrganicCard className="p-4 anim-rise">
    <Kicker className={`text-${accent}`}>{kicker}</Kicker>
    <h4 className="font-serif text-[16px] text-ink mt-1">{title}</h4>
    <p className="font-rounded text-[13px] text-ink-muted mt-1">{detail}</p>
    {resolved ? (
      <p className="mt-3 flex items-center gap-1.5 text-[13px] font-rounded text-life"><Icon name="check" size={15} />{doneLabel}</p>
    ) : (
      <Press onClick={onAccept} className="mt-3 rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>{cta}</Press>
    )}
  </OrganicCard>
);

const ThinkingDots: React.FC = () => (
  <div className="flex gap-1.5 px-1">
    {[0, 1, 2].map((i) => <span key={i} className="size-2 rounded-full bg-warm/70" style={{ animation: `shimmerDots 1.2s ease-in-out ${i * 0.18}s infinite` }} />)}
  </div>
);
