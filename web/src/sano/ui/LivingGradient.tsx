import React, { useEffect, useRef } from "react";
import { gradientPalette, type Scheme } from "../theme";

/** The app-wide living ground — three slow-orbiting radial centers over a base
 *  wash, tuned by scheme + hour. Calm, but visibly alive. */
export const LivingGradient: React.FC<{ scheme: Scheme; hour?: number; conversation?: [string, string, string]; className?: string }> = ({
  scheme, hour = new Date().getHours(), conversation, className,
}) => {
  const [a, b, c] = conversation ?? gradientPalette(scheme, hour);
  const baseWash = scheme === "night" ? "#0D1126" : "#F6EEE3";

  return (
    <div className={className} style={{ position: "absolute", inset: 0, overflow: "hidden", background: baseWash }}>
      <Blob color={a} size="70%" top="-12%" left="-8%" dur={26} delay={0} opacity={scheme === "night" ? 0.85 : 0.95} />
      <Blob color={b} size="64%" top="32%" left="48%" dur={32} delay={-6} opacity={scheme === "night" ? 0.8 : 0.9} />
      <Blob color={c} size="72%" top="58%" left="-6%" dur={38} delay={-14} opacity={scheme === "night" ? 0.78 : 0.88} />
      {/* fine grain so flats never read as plastic */}
      <div style={{
        position: "absolute", inset: 0, opacity: scheme === "night" ? 0.05 : 0.04, mixBlendMode: "overlay",
        backgroundImage:
          "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")",
      }} />
    </div>
  );
};

const Blob: React.FC<{ color: string; size: string; top: string; left: string; dur: number; delay: number; opacity: number }> = ({
  color, size, top, left, dur, delay, opacity,
}) => (
  <div
    className="anim-drift"
    style={{
      position: "absolute", width: size, height: size, top, left, opacity,
      background: `radial-gradient(circle at 50% 50%, ${color}, transparent 66%)`,
      filter: "blur(8px)",
      animation: `drift ${dur}s ease-in-out ${delay}s infinite`,
      willChange: "transform",
    }}
  />
);

/** Janum-Trivedi-style touch ripple — radial wash from the tap point, never
 *  over glass chrome (it lives only on the ground). */
export const RippleLayer: React.FC<{ scheme: Scheme }> = ({ scheme }) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const layer = ref.current;
    if (!layer) return;
    const onTap = (e: PointerEvent) => {
      const target = e.target as HTMLElement;
      // ignore taps on glass chrome / buttons / inputs so ripple stays on the ground
      if (target.closest("button, a, input, textarea, [data-no-ripple]")) return;
      const rect = layer.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const dot = document.createElement("span");
      const tint = scheme === "night" ? "rgba(143,198,255,0.5)" : "rgba(255,201,168,0.65)";
      dot.style.cssText = `position:absolute;left:${x}px;top:${y}px;width:34px;height:34px;margin:-17px 0 0 -17px;border-radius:50%;pointer-events:none;background:radial-gradient(circle, ${tint}, transparent 70%);animation:rippleOut 0.95s ease-out forwards;`;
      layer.appendChild(dot);
      setTimeout(() => dot.remove(), 960);
    };
    window.addEventListener("pointerdown", onTap);
    return () => window.removeEventListener("pointerdown", onTap);
  }, [scheme]);

  return <div ref={ref} style={{ position: "absolute", inset: 0, overflow: "hidden", pointerEvents: "none" }} />;
};
