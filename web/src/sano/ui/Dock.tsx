import React from "react";
import { cn } from "@/lib/utils";
import { Icon } from "./Icon";
import { useSano, type Tab } from "../store";
import { SoundEngine, Haptics } from "../sound";

const tabs: { id: Tab; label: string; glyph: string }[] = [
  { id: "today", label: "Today", glyph: "sun.haze" },
  { id: "care", label: "Care", glyph: "cross.case" },
  { id: "you", label: "You", glyph: "book.closed" },
  { id: "journeys", label: "Journeys", glyph: "leaf" },
  { id: "currents", label: "Currents", glyph: "water.waves" },
];

export const Dock: React.FC = () => {
  const { tab, setTab, careUnreadCount } = useSano();
  return (
    <div className="absolute inset-x-0 bottom-0 pb-3 flex justify-center pointer-events-none z-40">
      {/* A cool/bright tint + crisper edge lifts the glass off the warm ground
          so its refraction reads instead of blending in. */}
      <div
        className="glass-strong pointer-events-auto flex items-center gap-1 px-2 py-2"
        style={{
          borderRadius: 30,
          background: "rgb(var(--surface) / 0.34)",
          boxShadow: "inset 0 1px 0 0 rgb(255 255 255 / 0.4), 0 22px 50px -20px rgb(var(--shadow) / 0.6)",
          border: "1px solid rgb(255 255 255 / 0.22)",
        }}
      >
        {tabs.map((t) => {
          const active = tab === t.id;
          const badge = t.id === "care" ? careUnreadCount : 0;
          return (
            <button
              key={t.id}
              onClick={() => { Haptics.tick(); setTab(t.id); }}
              className="press relative grid place-items-center rounded-full"
              style={{ width: 58, height: 50 }}
            >
              {active && (
                <span
                  className="absolute inset-x-1.5 inset-y-1 rounded-full"
                  style={{ background: "rgb(var(--warm) / 0.18)", boxShadow: "inset 0 0 0 1px rgb(var(--warm) / 0.28)" }}
                />
              )}
              <span className={cn("relative flex flex-col items-center gap-0.5", active ? "text-warm" : "text-ink-muted")}>
                <span className="relative">
                  <Icon name={t.glyph} size={20} strokeWidth={active ? 2.3 : 1.9} />
                  {badge > 0 && (
                    <span
                      className="absolute -top-0.5 -right-1 size-2 rounded-full"
                      style={{ background: "rgb(var(--warm))", boxShadow: "0 0 0 1.5px rgb(var(--surface))" }}
                    />
                  )}
                </span>
                <span className="text-[9.5px] font-rounded font-semibold tracking-tight">{t.label}</span>
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
