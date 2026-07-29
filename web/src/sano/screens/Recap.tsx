import React, { useEffect, useMemo, useRef, useState } from "react";
import { useSano } from "../store";
import { SoundEngine } from "../sound";
import { Orb } from "../ui/Orb";
import { Icon } from "../ui/Icon";
import { SceneVisual } from "../ui/DataViz";
import { LivingGradient } from "../ui/LivingGradient";
import { img } from "../lifeLibrary";

interface Slide {
  kicker: string;
  title: string;
  detail?: string;
  image?: string | null;
  seed: number;
  orb?: boolean;
  stat?: { value: string; label: string } | null;
}

const SLIDE_MS = 4200;

/** The cinematic recap — a 30-second, scored chapter assembled from the week's
 *  real moments. Story-style segments, auto-advancing, tap to move, scored by
 *  the ambient bed. */
export const Recap: React.FC = () => {
  const s = useSano();
  const [idx, setIdx] = useState(0);
  const [progress, setProgress] = useState(0);
  const [paused, setPaused] = useState(false);
  const raf = useRef<number | null>(null);
  const startRef = useRef<number>(0);

  const slides = useMemo<Slide[]>(() => {
    const name = s.displayFirstName;
    const gardenCount = s.journeys.reduce((a, j) => a + j.habits.reduce((x, h) => x + h.keptDates.length, 0), 0);
    const milestones = s.storyEvents.filter((e) => e.kind === "milestone" || e.kind === "companion" || e.kind === "result").slice(0, 3);
    const lab = s.labSeries[0];
    const built: Slide[] = [
      { kicker: "Your chapter", title: `This stretch, ${name}.`, detail: "A quiet look back at what you carried — and what carried forward.", seed: 3, orb: true, stat: null },
    ];
    milestones.forEach((m, i) => built.push({ kicker: ["A moment that mattered", "Worth remembering", "The pattern we caught"][i % 3], title: m.title, detail: m.detail, image: i === 0 ? "recap_path" : i === 1 ? "recap_garden" : null, seed: 9 + i * 6, stat: null }));
    if (lab) {
      const first = lab.points[0]?.value;
      const last = lab.points[lab.points.length - 1]?.value;
      built.push({ kicker: lab.name, title: `${last}${lab.unit}`, detail: first != null && last != null ? (last <= first ? `Down from ${first}. Direction beats any single day.` : `Holding steady through it all.`) : lab.explainReading, seed: 5, stat: { value: `${last}${lab.unit}`, label: lab.name } });
    }
    built.push({ kicker: "Small things, kept", title: `${gardenCount || "Every"} lights in your garden`, detail: "Each one a habit you chose, on a day that wasn't always easy.", image: "recap_garden", seed: 14, stat: null });
    built.push({ kicker: "Still here", title: "Still going.", detail: "I'll keep the small stuff. You keep living. See you tomorrow.", seed: 21, orb: true, stat: null });
    return built;
  }, [s.displayFirstName, s.journeys, s.storyEvents, s.labSeries]);

  const slide = slides[idx];
  const close = () => { s.setShowRecap(false); s.setTab("you"); };

  // ensure music is up for the moment
  useEffect(() => { if (s.musicOn) SoundEngine.playBed("ambient", 1.2); SoundEngine.bloom(); /* eslint-disable-next-line */ }, []);

  // autoplay timeline
  useEffect(() => {
    if (paused) return;
    startRef.current = performance.now() - progress * SLIDE_MS;
    const tick = () => {
      const p = (performance.now() - startRef.current) / SLIDE_MS;
      if (p >= 1) {
        if (idx >= slides.length - 1) { setProgress(1); close(); return; }
        SoundEngine.whoosh();
        setIdx((i) => i + 1); setProgress(0); return;
      }
      setProgress(p);
      raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => { if (raf.current) cancelAnimationFrame(raf.current); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [idx, paused]);

  const go = (dir: 1 | -1) => {
    SoundEngine.whoosh();
    setProgress(0);
    setIdx((i) => Math.max(0, Math.min(slides.length - 1, i + dir)));
  };

  return (
    <div className="absolute inset-0 z-[70] overflow-hidden" style={{ background: "rgb(var(--base))" }}>
      <LivingGradient scheme={s.scheme} />
      <div className="absolute inset-0" style={{ background: s.scheme === "night" ? "rgb(0 0 0 / 0.3)" : "rgb(0 0 0 / 0.08)" }} />

      {/* segmented progress */}
      <div className="absolute top-0 inset-x-0 z-30 px-4 pt-3 flex gap-1.5">
        {slides.map((_, i) => (
          <div key={i} className="flex-1 h-1 rounded-full overflow-hidden" style={{ background: "rgb(var(--ink-muted) / 0.25)" }}>
            <div className="h-full rounded-full bg-white" style={{ width: `${i < idx ? 100 : i === idx ? progress * 100 : 0}%`, background: "rgb(var(--ink))", transition: i === idx ? "none" : "width 0.2s" }} />
          </div>
        ))}
      </div>
      <button onClick={close} className="press absolute top-7 right-4 z-40 grid place-items-center size-9 rounded-full glass text-ink"><Icon name="x" size={16} /></button>

      {/* tap zones */}
      <button aria-label="Previous" onClick={() => go(-1)} className="absolute left-0 top-12 bottom-0 w-1/3 z-20" />
      <button aria-label="Next" onClick={() => go(1)} className="absolute right-0 top-12 bottom-0 w-1/3 z-20" />
      <button aria-label="Hold" onPointerDown={() => setPaused(true)} onPointerUp={() => setPaused(false)} onPointerLeave={() => setPaused(false)} className="absolute left-1/3 right-1/3 top-12 bottom-0 z-20" />

      {/* slide */}
      <div key={idx} className="absolute inset-0 z-10 flex flex-col items-center justify-center px-9 text-center anim-fade pointer-events-none">
        {slide.image && img(slide.image) ? (
          <div className="relative size-56 rounded-full overflow-hidden mb-8 anim-bloom" style={{ boxShadow: "0 30px 80px -20px rgba(0,0,0,0.5), inset 0 2px 14px rgba(255,255,255,0.4)" }}>
            <img src={img(slide.image)!} alt="" className="absolute inset-0 w-full h-full object-cover" />
            <div className="absolute inset-0" style={{ background: "radial-gradient(120% 90% at 32% 22%, rgba(255,255,255,0.45), transparent 50%)" }} />
          </div>
        ) : slide.orb ? (
          <div className="mb-8 anim-bloom"><Orb size={150} state={idx === 0 ? "ambient" : "celebrating"} scheme={s.scheme} /></div>
        ) : (
          <div className="relative mb-8"><SceneVisual seed={slide.seed} height={150} className="w-56 anim-bloom" /></div>
        )}

        <p className="kicker text-ink-muted anim-rise" style={{ animationDelay: "0.1s" }}>{slide.kicker}</p>
        <h1 className={`font-serif text-ink leading-tight mt-3 anim-rise ${slide.stat ? "text-[64px]" : "text-[34px]"}`} style={{ animationDelay: "0.18s" }}>{slide.title}</h1>
        {slide.detail && <p className="font-serif text-[17px] text-ink/85 leading-relaxed mt-4 max-w-[300px] anim-rise" style={{ animationDelay: "0.3s" }}>{slide.detail}</p>}
      </div>
    </div>
  );
};
