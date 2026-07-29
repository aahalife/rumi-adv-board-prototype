import React from "react";
import { cn } from "@/lib/utils";
import { Icon } from "./Icon";
import { SoundEngine, Haptics } from "../sound";

/** Liquid-glass chrome surface. */
export const Glass: React.FC<React.HTMLAttributes<HTMLDivElement> & { strong?: boolean; radius?: number }> = ({
  className, strong, radius = 28, style, children, ...rest
}) => (
  <div className={cn(strong ? "glass-strong" : "glass", className)} style={{ borderRadius: radius, ...style }} {...rest}>
    {children}
  </div>
);

/** The default porcelain card. */
export const OrganicCard: React.FC<React.HTMLAttributes<HTMLDivElement> & { radius?: number }> = ({
  className, radius = 28, style, children, ...rest
}) => (
  <div className={cn("organic", className)} style={{ borderRadius: radius, ...style }} {...rest}>
    {children}
  </div>
);

/** A round glass icon button — the chrome control language. */
export const ChromeIcon: React.FC<{ name: string; onClick?: () => void; label?: string; active?: boolean; size?: number }> = ({
  name, onClick, label, active, size = 18,
}) => (
  <button
    aria-label={label}
    onClick={() => { Haptics.glass(); SoundEngine.glass(); onClick?.(); }}
    className={cn(
      "press grid place-items-center rounded-full size-11 glass",
      active ? "text-gold" : "text-ink/80",
    )}
  >
    <Icon name={name} size={size} />
  </button>
);

/** Press-feedback button wrapper. */
export const Press: React.FC<React.ButtonHTMLAttributes<HTMLButtonElement> & { sound?: boolean }> = ({
  className, onClick, sound = true, children, ...rest
}) => (
  <button
    className={cn("press", className)}
    onClick={(e) => { if (sound) { Haptics.tick(); SoundEngine.tick(); } onClick?.(e); }}
    {...rest}
  >
    {children}
  </button>
);

export const Kicker: React.FC<{ children: React.ReactNode; className?: string }> = ({ children, className }) => (
  <div className={cn("kicker text-ink-muted", className)}>{children}</div>
);

export const ProvenanceChip: React.FC<{ text: string; className?: string }> = ({ text, className }) => (
  <div className={cn("inline-flex items-center gap-1.5 text-ink-muted", className)}>
    <Icon name="shield" size={13} className="text-life" />
    <span className="text-[11.5px] font-rounded">{text}</span>
  </div>
);

export const SponsorChip: React.FC<{ sponsor: string; onClick?: () => void }> = ({ sponsor, onClick }) => (
  <Press onClick={onClick} className="inline-flex items-center gap-1.5 text-ink-muted">
    <Icon name="info" size={12} />
    <span className="text-[11px] font-rounded">Supported by {sponsor}</span>
  </Press>
);

export const FreshnessChip: React.FC<{ ts: number }> = ({ ts }) => {
  const mins = Math.max(0, Math.round((Date.now() - ts) / 60000));
  const label = mins < 60 ? `${mins}m ago` : mins < 1440 ? `${Math.round(mins / 60)}h ago` : `${Math.round(mins / 1440)}d ago`;
  return (
    <div className="inline-flex items-center gap-1.5">
      <span className="size-1.5 rounded-full bg-life" />
      <span className="text-[11px] font-rounded text-ink-muted">{label}</span>
    </div>
  );
};

/** Accent token → tailwind class fragments. */
export const accentText: Record<string, string> = {
  warm: "text-warm", life: "text-life", sky: "text-sky", gold: "text-gold", rose: "text-rose", attention: "text-attention",
};
export const accentBg: Record<string, string> = {
  warm: "bg-warm", life: "bg-life", sky: "bg-sky", gold: "bg-gold", rose: "bg-rose", attention: "bg-attention",
};
