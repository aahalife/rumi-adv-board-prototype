import React, { useEffect, useRef, useState } from "react";
import { useSano } from "../store";
import { SoundEngine } from "../sound";
import { OrganicCard, Press, Kicker, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { Sheet } from "../ui/Sheet";
import { SceneVisual } from "../ui/DataViz";
import { HubHeader } from "./nav";
import { img } from "../lifeLibrary";
import type { CurrentsPiece, CurrentFormat } from "../types";

const formatGlyph: Record<CurrentFormat, string> = { Glance: "sparkles", Read: "book", Watch: "play", Listen: "volume" };
const formatAccent: Record<CurrentFormat, string> = { Glance: "warm", Read: "sky", Watch: "rose", Listen: "gold" };

/** Currents — a calm, magazine-style feed of things worth your attention, each
 *  chosen for where you actually are. Read, Watch, and Listen all play. */
export const Currents: React.FC = () => {
  const s = useSano();
  const [filter, setFilter] = useState<"All" | CurrentFormat>("All");
  const [open, setOpen] = useState<CurrentsPiece | null>(null);
  const list = filter === "All" ? s.currents : s.currents.filter((c) => c.format === filter);
  const [hero, ...rest] = list;

  return (
    <div className="absolute inset-0 overflow-y-auto px-5 pb-32">
      <HubHeader title="Currents" subtitle="Chosen for where you are — never a feed to fall into." />

      <div className="flex gap-2 overflow-x-auto -mx-5 px-5 mt-4 pb-1">
        {(["All", "Glance", "Read", "Watch", "Listen"] as const).map((f) => (
          <Press key={f} onClick={() => setFilter(f)} className={`shrink-0 rounded-full px-3.5 py-1.5 text-[12.5px] font-rounded font-medium ${filter === f ? "text-base" : "text-ink glass"}`} style={filter === f ? { background: "rgb(var(--ink))" } : undefined}>{f}</Press>
        ))}
      </div>

      {hero && <HeroCard piece={hero} onOpen={() => setOpen(hero)} />}

      <div className="mt-4 space-y-3.5">
        {rest.map((c) => <FeedCard key={c.id} piece={c} onOpen={() => setOpen(c)} />)}
      </div>
      {list.length === 0 && <OrganicCard className="p-6 text-center mt-4"><p className="font-serif text-[16px] text-ink">Nothing in this format right now.</p></OrganicCard>}

      <Sheet open={open != null} onClose={() => setOpen(null)} full bg="rgb(var(--base))">
        {open && <Reader piece={open} onClose={() => setOpen(null)} />}
      </Sheet>
    </div>
  );
};

const FormatBadge: React.FC<{ format: CurrentFormat; onLight?: boolean }> = ({ format, onLight }) => (
  <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[10.5px] font-rounded font-semibold ${onLight ? "glass text-ink" : ""}`} style={onLight ? undefined : { background: `rgb(var(--${formatAccent[format]}) / 0.18)`, color: `rgb(var(--${formatAccent[format]}))` }}>
    <Icon name={formatGlyph[format]} size={12} />{format}
  </span>
);

const HeroCard: React.FC<{ piece: CurrentsPiece; onOpen: () => void }> = ({ piece, onOpen }) => (
  <Press onClick={onOpen} className="w-full text-left mt-5">
    <div className="relative rounded-3xl overflow-hidden h-60 ring-1 ring-white/30 shadow-xl">
      {img(piece.imageName) ? <img src={img(piece.imageName)!} alt="" className="absolute inset-0 w-full h-full object-cover" /> : <SceneVisual seed={piece.sceneSeed} height={240} />}
      <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgb(0 0 0 / 0.72), transparent 58%)" }} />
      {(piece.format === "Watch" || piece.format === "Listen") && (
        <div className="absolute inset-0 grid place-items-center"><div className="size-16 rounded-full grid place-items-center glass-strong"><Icon name="play" size={26} className="text-white" /></div></div>
      )}
      <div className="absolute bottom-4 left-4 right-4">
        <FormatBadge format={piece.format} />
        <h2 className="font-serif text-[22px] text-white leading-tight mt-2">{piece.headline}</h2>
        <p className="font-rounded text-[12.5px] text-white/80 mt-1">{piece.kicker}</p>
      </div>
    </div>
  </Press>
);

const FeedCard: React.FC<{ piece: CurrentsPiece; onOpen: () => void }> = ({ piece, onOpen }) => {
  const s = useSano();
  return (
    <OrganicCard className="overflow-hidden anim-rise">
      <Press onClick={onOpen} className="w-full text-left flex items-stretch gap-0">
        <div className="relative w-28 shrink-0">
          {img(piece.imageName) ? <img src={img(piece.imageName)!} alt="" className="absolute inset-0 w-full h-full object-cover" /> : <SceneVisual seed={piece.sceneSeed} height={140} />}
          {(piece.format === "Watch" || piece.format === "Listen") && <div className="absolute inset-0 grid place-items-center"><div className="size-9 rounded-full grid place-items-center glass-strong"><Icon name="play" size={15} className="text-white" /></div></div>}
        </div>
        <div className="flex-1 min-w-0 p-3.5">
          <FormatBadge format={piece.format} />
          <h3 className="font-serif text-[16px] text-ink leading-tight mt-1.5">{piece.headline}</h3>
          <p className="font-rounded text-[12px] text-ink-muted mt-1 leading-snug line-clamp-2">{piece.body.split("\n")[0]}</p>
        </div>
      </Press>
      <div className="flex items-center gap-1 px-3 pb-2.5 -mt-1">
        <TasteButton active={piece.taste === 1} glyph="thumbsUp" onClick={() => s.setTaste(piece.id, 1)} />
        <TasteButton active={piece.taste === -1} glyph="thumbsDown" onClick={() => s.setTaste(piece.id, -1)} />
        <div className="flex-1" />
        <button onClick={() => s.toggleCurrentSaved(piece.id)} className="press grid place-items-center size-8 rounded-full text-ink-muted"><Icon name="bookmark" size={15} className={piece.saved ? "text-gold" : ""} /></button>
      </div>
    </OrganicCard>
  );
};

const TasteButton: React.FC<{ active: boolean; glyph: string; onClick: () => void }> = ({ active, glyph, onClick }) => (
  <button onClick={onClick} className={`press grid place-items-center size-8 rounded-full ${active ? "text-life" : "text-ink-muted/70"}`}><Icon name={glyph} size={15} /></button>
);

/** Full reader — articles scroll, Watch/Listen get a real (simulated) player
 *  with a progress bar, the body as transcript/captions. */
const Reader: React.FC<{ piece: CurrentsPiece; onClose: () => void }> = ({ piece, onClose }) => {
  const s = useSano();
  const isMedia = piece.format === "Watch" || piece.format === "Listen";
  const paras = piece.body.split("\n").filter((p) => p.trim().length > 0);

  return (
    <div className="absolute inset-0 overflow-y-auto">
      {/* hero */}
      <div className="relative h-64">
        {img(piece.imageName) ? <img src={img(piece.imageName)!} alt="" className="absolute inset-0 w-full h-full object-cover" /> : <SceneVisual seed={piece.sceneSeed} height={256} />}
        <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgb(var(--base)), rgb(var(--base) / 0.1) 55%, transparent)" }} />
        <button onClick={onClose} className="press absolute top-3 left-4 grid place-items-center size-10 rounded-full glass-strong text-ink"><Icon name="chevronDown" size={18} /></button>
        <button onClick={() => s.toggleCurrentSaved(piece.id)} className="press absolute top-3 right-4 grid place-items-center size-10 rounded-full glass-strong"><Icon name="bookmark" size={16} className={piece.saved ? "text-gold" : "text-ink"} /></button>
      </div>

      <div className="px-6 -mt-12 relative pb-16">
        <FormatBadge format={piece.format} />
        <h1 className="font-serif text-[28px] text-ink leading-tight mt-2.5">{piece.headline}</h1>
        <div className="flex items-center gap-2 mt-2">
          <span className="font-rounded text-[12px] text-ink-muted">{piece.kicker}</span>
          {piece.aiGenerated && <span className="inline-flex items-center gap-1 text-[10.5px] font-rounded text-ink-muted/80"><Icon name="sparkles" size={10} />Made for you</span>}
        </div>

        {isMedia && <MediaPlayer piece={piece} />}

        <div className={`mt-5 space-y-4 ${isMedia ? "" : ""}`}>
          {isMedia && <Kicker className={accentText[formatAccent[piece.format]]}>Transcript</Kicker>}
          {paras.map((p, i) => (
            <p key={i} className="font-serif text-[16.5px] text-ink/90 leading-relaxed">{p}</p>
          ))}
        </div>

        <OrganicCard className="p-4 mt-7 flex items-center gap-3">
          <div className="flex gap-1">
            <TasteButton active={piece.taste === 1} glyph="thumbsUp" onClick={() => s.setTaste(piece.id, 1)} />
            <TasteButton active={piece.taste === -1} glyph="thumbsDown" onClick={() => s.setTaste(piece.id, -1)} />
          </div>
          <p className="font-rounded text-[12.5px] text-ink-muted flex-1">More like this, or less? It tunes what I bring you.</p>
        </OrganicCard>

        <Press onClick={() => { onClose(); s.openConversation("currents"); }} className="w-full mt-3 rounded-full py-3.5 font-rounded font-semibold text-[14px] flex items-center justify-center gap-2" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>
          <Icon name="message-circle" size={16} />Talk this through with Rumi
        </Press>
      </div>
    </div>
  );
};

/** A felt-real player: tap play, the bar fills over a friendly duration, the orb
 *  state lifts. Listen rides the ambient bed; Watch shows captioned scene. */
const MediaPlayer: React.FC<{ piece: CurrentsPiece }> = ({ piece }) => {
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const raf = useRef<number | null>(null);
  const startRef = useRef<number>(0);
  const duration = piece.format === "Watch" ? 90 : 120; // seconds, matches the copy

  useEffect(() => () => { if (raf.current) cancelAnimationFrame(raf.current); }, []);

  const toggle = () => {
    if (playing) {
      setPlaying(false);
      if (raf.current) cancelAnimationFrame(raf.current);
      return;
    }
    SoundEngine.glass();
    setPlaying(true);
    startRef.current = performance.now() - progress * duration * 1000;
    const tick = () => {
      const elapsed = (performance.now() - startRef.current) / 1000;
      const p = Math.min(1, elapsed / duration);
      setProgress(p);
      if (p >= 1) { setPlaying(false); return; }
      raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
  };

  const fmt = (sec: number) => `${Math.floor(sec / 60)}:${String(Math.floor(sec % 60)).padStart(2, "0")}`;
  const cur = progress * duration;

  return (
    <OrganicCard className="p-4 mt-5">
      <div className="flex items-center gap-3.5">
        <button onClick={toggle} className="press grid place-items-center size-14 rounded-full shrink-0" style={{ background: "rgb(var(--ink))" }}>
          <Icon name={playing ? "pause" : "play"} size={22} className="text-base" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between mb-1.5">
            <span className="font-rounded text-[12.5px] text-ink font-medium">{piece.format === "Watch" ? "Now watching" : "Now listening"}</span>
            <span className="tnum text-[11px] text-ink-muted">{fmt(cur)} / {fmt(duration)}</span>
          </div>
          <div className="h-2 rounded-full overflow-hidden" style={{ background: "rgb(var(--ink-muted) / 0.18)" }}>
            <div className="h-full rounded-full transition-[width] duration-150" style={{ width: `${progress * 100}%`, background: `linear-gradient(90deg, rgb(var(--${formatAccent[piece.format]})), rgb(var(--gold)))` }} />
          </div>
          {/* sound wave shimmer when playing */}
          <div className="flex items-end gap-0.5 h-4 mt-2" style={{ opacity: playing ? 1 : 0.3 }}>
            {Array.from({ length: 28 }).map((_, i) => (
              <span key={i} className="flex-1 rounded-full" style={{ background: `rgb(var(--${formatAccent[piece.format]}) / 0.6)`, height: playing ? `${30 + ((i * 37) % 70)}%` : "20%", transformOrigin: "bottom", animation: playing ? `wave ${0.7 + (i % 5) * 0.12}s ease-in-out ${-i * 0.05}s infinite` : "none" }} />
            ))}
          </div>
        </div>
      </div>
    </OrganicCard>
  );
};
