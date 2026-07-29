import React, { useEffect } from "react";
import { useSano } from "./store";
import { SoundEngine } from "./sound";
import { LivingGradient, RippleLayer } from "./ui/LivingGradient";
import { Orb } from "./ui/Orb";
import { Dock } from "./ui/Dock";
import { Glass } from "./ui/Glass";
import { conversationPalette } from "./theme";
import { Onboarding } from "./screens/Onboarding";
import { Today } from "./screens/Today";
import { CareHub } from "./screens/Care";
import { YouHub } from "./screens/You";
import { Journeys } from "./screens/Journeys";
import { Currents } from "./screens/Currents";
import { Conversation } from "./screens/Conversation";
import { QuickLog } from "./screens/QuickLog";
import { Settings } from "./screens/Settings";
import { Recap } from "./screens/Recap";
import { AgentNetworkSheet } from "./screens/AgentNetwork";
import { Sheet } from "./ui/Sheet";

/** Outer page — ambient wash behind a centered device column on desktop. */
export const SanoApp: React.FC = () => {
  const s = useSano();

  useEffect(() => {
    const unlock = () => SoundEngine.unlock();
    window.addEventListener("pointerdown", unlock, { once: true });
    return () => window.removeEventListener("pointerdown", unlock);
  }, []);

  return (
    <div className="min-h-[100dvh] w-full grid place-items-center" style={{ background: s.scheme === "night" ? "#070A18" : "#EDE2D2" }}>
      <div
        className="relative overflow-hidden w-full"
        style={{ maxWidth: 440, height: "100dvh", boxShadow: "0 40px 120px -30px rgba(0,0,0,0.5)" }}
      >
        <LivingGradient scheme={s.scheme} />
        <RippleLayer scheme={s.scheme} />

        {s.hasOnboarded ? <RootShell /> : <Onboarding />}
      </div>
    </div>
  );
};

const RootShell: React.FC = () => {
  const s = useSano();
  return (
    <div className="absolute inset-0">
      <div className={s.showConversation ? "opacity-0 pointer-events-none transition-opacity" : "absolute inset-0 anim-fade transition-opacity"}>
        {s.tab === "today" && <Today />}
        {s.tab === "care" && <CareHub />}
        {s.tab === "you" && <YouHub />}
        {s.tab === "journeys" && <Journeys />}
        {s.tab === "currents" && <Currents />}
      </div>

      {/* The companion is everywhere — except on Today (which has the big orb). */}
      {!s.showConversation && s.tab !== "today" && (
        <div className="absolute top-3 right-4 z-30">
          <button
            onClick={() => { SoundEngine.glass(); s.openConversation(); }}
            className="press grid place-items-center rounded-full glass p-1"
            aria-label="Talk with Rumi"
          >
            <Orb size={36} state={s.orbState} scheme={s.scheme} halo={false} />
          </button>
        </div>
      )}

      {!s.showConversation && <Dock />}

      {s.showConversation && <Conversation />}

      {s.quickLogAck && <AckToast text={s.quickLogAck} />}

      <Sheet open={s.showQuickLog} onClose={() => { s.setShowQuickLog(false); s.setQuickLogMedID(null); }}>
        <QuickLog />
      </Sheet>
      <Sheet open={s.showSettings} onClose={() => s.setShowSettings(false)}>
        <Settings />
      </Sheet>
      <Sheet open={s.showAgentNetwork} full onClose={() => s.setShowAgentNetwork(false)}>
        <AgentNetworkSheet />
      </Sheet>
      {s.showRecap && <Recap />}
    </div>
  );
};

const AckToast: React.FC<{ text: string }> = ({ text }) => {
  const s = useSano();
  return (
    <div className="absolute inset-x-0 z-40 flex justify-center px-6 pointer-events-none" style={{ bottom: 112 }}>
      <Glass
        radius={28}
        className="pointer-events-auto anim-rise max-w-[92%] p-4 flex items-start gap-3 cursor-pointer"
        onClick={() => { s.setQuickLogAck(null); s.openConversation("pattern"); }}
      >
        <Orb size={34} state={s.orbState} scheme={s.scheme} halo={false} />
        <p className="font-rounded text-[14px] text-ink leading-snug pt-1">{text}</p>
      </Glass>
    </div>
  );
};
