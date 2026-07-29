import React, { useCallback, useState } from "react";
import { Icon } from "../ui/Icon";
import { SoundEngine } from "../sound";

export interface Route { name: string; params?: Record<string, unknown> }

export function useStack(initial: Route) {
  const [stack, setStack] = useState<Route[]>([initial]);
  const push = useCallback((r: Route) => { SoundEngine.glass(); setStack((s) => [...s, r]); }, []);
  const pop = useCallback(() => { SoundEngine.glass(); setStack((s) => (s.length > 1 ? s.slice(0, -1) : s)); }, []);
  const reset = useCallback((r: Route) => setStack([r]), []);
  const top = stack[stack.length - 1];
  return { stack, top, push, pop, reset, canPop: stack.length > 1 };
}

/** A pushed sub-screen with a back affordance, sliding in from the right. */
export const SubScreen: React.FC<{ onBack: () => void; children: React.ReactNode; back?: string }> = ({ onBack, children, back }) => (
  <div className="absolute inset-0 anim-push overflow-y-auto">
    <div className="sticky top-0 z-20 px-4 pt-3 pb-2">
      <button onClick={onBack} className="press inline-flex items-center gap-1 rounded-full glass pl-2 pr-3.5 py-2 text-ink/85">
        <Icon name="chevronLeft" size={17} /><span className="font-rounded text-[13px] font-medium">{back ?? "Back"}</span>
      </button>
    </div>
    <div className="px-5 pb-32 -mt-1">{children}</div>
  </div>
);

export const HubHeader: React.FC<{ title: string; subtitle?: string; rightPad?: boolean }> = ({ title, subtitle, rightPad }) => (
  <div className={`pt-4 ${rightPad ? "pr-14" : ""}`}>
    <h1 className="font-serif text-[32px] text-ink leading-tight">{title}</h1>
    {subtitle && <p className="font-rounded text-[14px] text-ink-muted mt-1.5">{subtitle}</p>}
  </div>
);

export const SectionTitle: React.FC<{ children: React.ReactNode; className?: string }> = ({ children, className }) => (
  <h2 className={`font-serif text-[20px] text-ink ${className ?? ""}`}>{children}</h2>
);
