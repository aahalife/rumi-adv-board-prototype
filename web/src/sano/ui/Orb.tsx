import React, { useEffect, useRef } from "react";
import { orbHalo, type Scheme } from "../theme";
import type { OrbMode } from "../store";

function orbSrc(state: OrbMode, scheme: Scheme): string {
  switch (state) {
    case "thinking": return "/orb/orb_think.mp4";
    case "speaking":
    case "listening": return "/orb/orb_speak.mp4";
    case "celebrating": return "/orb/orb_bloom.mp4";
    default: return scheme === "night" ? "/orb/orb_night.mp4" : "/orb/orb_day.mp4";
  }
}

/** The companion form — real glass-orb video, feathered to a circle, with a
 *  pastel halo so it never floats on bare ground. */
export const Orb: React.FC<{ size: number; state?: OrbMode; scheme: Scheme; halo?: boolean; className?: string }> = ({
  size, state = "ambient", scheme, halo = true, className,
}) => {
  const ref = useRef<HTMLVideoElement>(null);
  const src = orbSrc(state, scheme);

  useEffect(() => {
    const v = ref.current;
    if (!v) return;
    v.play().catch(() => {});
  }, [src]);

  const mask = "radial-gradient(circle at 50% 50%, #000 56%, rgba(0,0,0,0.7) 66%, transparent 75%)";

  return (
    <div className={className} style={{ width: size, height: size, position: "relative" }}>
      {halo && (
        <div
          className="anim-halo"
          style={{
            position: "absolute", inset: -size * 0.42, borderRadius: "50%",
            background: orbHalo(scheme), filter: "blur(6px)", pointerEvents: "none",
          }}
        />
      )}
      <div className="anim-breathe" style={{ position: "absolute", inset: 0 }}>
        <video
          ref={ref}
          src={src}
          muted
          loop
          autoPlay
          playsInline
          style={{
            width: "100%", height: "100%", objectFit: "cover", borderRadius: "50%",
            WebkitMaskImage: mask, maskImage: mask,
            mixBlendMode: scheme === "night" ? "screen" : "normal",
          }}
        />
        {/* specular rim + glass highlight */}
        <div
          style={{
            position: "absolute", inset: 0, borderRadius: "50%", pointerEvents: "none",
            background:
              "radial-gradient(120% 90% at 32% 26%, rgba(255,255,255,0.55), transparent 42%)",
            boxShadow: "inset 0 1px 6px rgba(255,255,255,0.4), inset 0 -8px 22px rgba(0,0,0,0.12)",
          }}
        />
      </div>
    </div>
  );
};
