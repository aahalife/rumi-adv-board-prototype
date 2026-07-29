import React, { useMemo, useState } from "react";
import type { LabSeries } from "../types";
import type { Scheme } from "../theme";

/** Catmull-Rom → bezier smoothing for a luminous line. */
function smoothPath(pts: { x: number; y: number }[]): string {
  if (pts.length < 2) return "";
  let d = `M ${pts[0].x} ${pts[0].y}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i];
    const p1 = pts[i];
    const p2 = pts[i + 1];
    const p3 = pts[i + 2] ?? p2;
    const c1x = p1.x + (p2.x - p0.x) / 6;
    const c1y = p1.y + (p2.y - p0.y) / 6;
    const c2x = p2.x - (p3.x - p1.x) / 6;
    const c2y = p2.y - (p3.y - p1.y) / 6;
    d += ` C ${c1x} ${c1y}, ${c2x} ${c2y}, ${p2.x} ${p2.y}`;
  }
  return d;
}

export const GlowChart: React.FC<{ series: LabSeries; scheme: Scheme; height?: number; accent?: string }> = ({
  series, height = 200, accent = "var(--warm)",
}) => {
  const [scrub, setScrub] = useState<number | null>(null);
  const W = 320;
  const H = height;
  const padX = 14;
  const padY = 22;
  const vals = series.points.map((p) => p.value);
  const lo = Math.min(...vals, series.band?.[0] ?? Infinity);
  const hi = Math.max(...vals, series.band?.[1] ?? -Infinity);
  const span = hi - lo || 1;
  const pad = span * 0.18;
  const yMin = lo - pad;
  const yMax = hi + pad;

  const pts = useMemo(
    () => series.points.map((p, i) => ({
      x: padX + (i / Math.max(1, series.points.length - 1)) * (W - padX * 2),
      y: padY + (1 - (p.value - yMin) / (yMax - yMin)) * (H - padY * 2),
      v: p.value, date: p.date,
    })),
    [series, yMin, yMax, H],
  );
  const line = smoothPath(pts);
  const area = `${line} L ${pts[pts.length - 1].x} ${H - padY} L ${pts[0].x} ${H - padY} Z`;

  const bandTop = series.band ? padY + (1 - (series.band[1] - yMin) / (yMax - yMin)) * (H - padY * 2) : 0;
  const bandBot = series.band ? padY + (1 - (series.band[0] - yMin) / (yMax - yMin)) * (H - padY * 2) : 0;

  const active = scrub != null ? pts[scrub] : pts[pts.length - 1];
  const accentColor = `rgb(${accent.startsWith("var") ? `var(--${accent.includes("warm") ? "warm" : "gold"})` : accent})`;
  const stroke = "rgb(var(--warm))";

  return (
    <div style={{ position: "relative" }}>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        width="100%"
        height={H}
        onPointerMove={(e) => {
          const rect = (e.currentTarget as SVGElement).getBoundingClientRect();
          const x = ((e.clientX - rect.left) / rect.width) * W;
          let nearest = 0; let dist = Infinity;
          pts.forEach((p, i) => { const dd = Math.abs(p.x - x); if (dd < dist) { dist = dd; nearest = i; } });
          setScrub(nearest);
        }}
        onPointerLeave={() => setScrub(null)}
      >
        <defs>
          <linearGradient id={`fill-${series.id}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={stroke} stopOpacity="0.28" />
            <stop offset="100%" stopColor={stroke} stopOpacity="0" />
          </linearGradient>
          <filter id={`glow-${series.id}`} x="-20%" y="-40%" width="140%" height="180%">
            <feGaussianBlur stdDeviation="5" result="b" />
            <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
        </defs>
        {series.band && (
          <rect x={padX} y={bandTop} width={W - padX * 2} height={Math.max(0, bandBot - bandTop)} rx="10"
            fill="rgb(var(--life) / 0.13)" />
        )}
        <path d={area} fill={`url(#fill-${series.id})`} />
        <path d={line} fill="none" stroke={stroke} strokeWidth="2.6" strokeLinecap="round"
          opacity="0.45" filter={`url(#glow-${series.id})`} />
        <path d={line} fill="none" stroke={stroke} strokeWidth="2.4" strokeLinecap="round" />
        {series.annotation && (() => {
          const idx = series.points.findIndex((p) => p.date === series.annotation!.date);
          if (idx < 0) return null;
          const p = pts[idx];
          return <line x1={p.x} y1={padY} x2={p.x} y2={H - padY} stroke="rgb(var(--ink-muted) / 0.3)" strokeDasharray="3 4" />;
        })()}
        <circle cx={active.x} cy={active.y} r="5.5" fill="rgb(var(--surface))" stroke={stroke} strokeWidth="2.5" />
      </svg>
      <div className="absolute top-1 left-3 text-[11px] font-rounded text-ink-muted">
        {series.bandLabel}
      </div>
      <div
        className="absolute -translate-x-1/2 tnum text-[12px] font-semibold px-2 py-1 rounded-full glass"
        style={{ left: `${(active.x / W) * 100}%`, top: Math.max(2, active.y - 34), color: accentColor }}
      >
        {active.v}
        <span className="text-ink-muted ml-1 text-[10px]">{series.unit}</span>
      </div>
    </div>
  );
};

/** Adherence as a soft wave — fullness = level, no percentages on the surface. */
export const TideView: React.FC<{ level: number; height?: number }> = ({ level, height = 64 }) => {
  const fill = Math.max(0.06, Math.min(1, level));
  return (
    <div className="relative w-full overflow-hidden rounded-2xl" style={{ height, background: "rgb(var(--sky) / 0.1)" }}>
      {[0, 1, 2].map((i) => (
        <div
          key={i}
          className="absolute inset-x-0 anim-bob"
          style={{
            bottom: `calc(${fill * 100}% - 60px)`,
            height: 120,
            opacity: 0.4 - i * 0.1,
            background: ["rgb(var(--life))", "rgb(var(--sky))", "rgb(var(--gold))"][i],
            borderRadius: "44% 56% 50% 50% / 60% 58% 42% 40%",
            animationDuration: `${5 + i * 1.3}s`,
            animationDelay: `${i * -0.7}s`,
            filter: "blur(2px)",
          }}
        />
      ))}
      <div className="absolute inset-x-0" style={{ bottom: 0, height: `${fill * 100}%`, background: "linear-gradient(to top, rgb(var(--sky) / 0.18), transparent)" }} />
    </div>
  );
};

/** Small seeded generative glow scene for insights / empty states. */
export const SceneVisual: React.FC<{ seed: number; height?: number; className?: string }> = ({ seed, height = 120, className }) => {
  const blobs = useMemo(() => {
    let s = seed * 9301 + 49297;
    const rnd = () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
    const colors = ["var(--warm)", "var(--life)", "var(--sky)", "var(--gold)", "var(--rose)"];
    return Array.from({ length: 5 }, () => ({
      x: rnd() * 100, y: rnd() * 100, r: 26 + rnd() * 40, c: colors[Math.floor(rnd() * colors.length)], o: 0.3 + rnd() * 0.4,
    }));
  }, [seed]);
  return (
    <div className={className} style={{ position: "relative", height, overflow: "hidden", borderRadius: 18 }}>
      {blobs.map((b, i) => (
        <div key={i} style={{
          position: "absolute", left: `${b.x}%`, top: `${b.y}%`, width: `${b.r}%`, height: `${b.r}%`,
          transform: "translate(-50%,-50%)", borderRadius: "50%", opacity: b.o, filter: "blur(14px)",
          background: `radial-gradient(circle, rgb(${b.c}), transparent 70%)`,
        }} />
      ))}
    </div>
  );
};
