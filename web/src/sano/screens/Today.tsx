import React, { useState } from "react";
import { useSano } from "../store";
import { SoundEngine } from "../sound";
import { Orb } from "../ui/Orb";
import { OrganicCard, Press, Kicker, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { SceneVisual } from "../ui/DataViz";
import { img, fmtTime } from "../lifeLibrary";
import { AgentPulseCard } from "./AgentNetwork";
import type { Moment, AgentAction } from "../types";

export const Today: React.FC = () => {
  const s = useSano();
  const hour = new Date().getHours();
  const greeting = hour < 12 ? "Morning" : hour < 17 ? "Afternoon" : "Evening";
  const action = s.pendingActions[0];
  const todayEntries = s.entries.filter((e) => { const d = new Date(e.at); const n = new Date(); return d.toDateString() === n.toDateString(); }).slice(0, 6);
  const careAlertTitle = s.threads.some((t) => t.unread)
    ? (s.careUnreadCount > 1 ? `${s.careUnreadCount} updates from your care team` : "A new message from your care team")
    : "A new result is ready";

  return (
    <div className="absolute inset-0 overflow-y-auto" data-scroll>
      <div className="px-5 pt-3 pb-40">
        {/* header */}
        <div className="flex items-center gap-2.5">
          <button onClick={() => s.setShowSettings(true)} className="press grid place-items-center size-10 rounded-full glass text-ink/80"><Icon name="sliders" size={17} /></button>
          <Press onClick={() => s.setTab("you")} className="flex items-center gap-1.5 rounded-full glass px-3 py-2">
            <span className="size-2 rounded-full bg-life" />
            <span className="font-rounded text-[12px] text-ink font-medium">{s.persona.conditionChip}</span>
          </Press>
          <div className="flex-1" />
          <button onClick={() => s.setMusicOn(!s.musicOn)} className={`press grid place-items-center size-10 rounded-full glass ${s.musicOn ? "text-gold" : "text-ink-muted"}`}><Icon name={s.musicOn ? "volume" : "mute"} size={17} /></button>
        </div>

        {/* orb */}
        <div className="flex flex-col items-center mt-6">
          <button onClick={() => { SoundEngine.whoosh(); s.openConversation(); }} className="press">
            <Orb size={150} state={s.orbState} scheme={s.scheme} />
          </button>
          <h1 className="font-serif text-[27px] text-ink mt-5 text-center">{greeting}, {s.displayFirstName}.</h1>
          <p className="font-rounded text-[14px] text-ink-muted mt-1 text-center">{s.pendingActions.length || s.moments.length ? s.persona.statusBusy : s.persona.statusQuiet}</p>
          <button onClick={() => { SoundEngine.whoosh(); s.openConversation(); }} className="press mt-3 flex items-center gap-1.5 text-ink-muted">
            <Icon name="chevronDown" size={13} /><span className="font-rounded text-[12px]">tap the orb to talk</span>
          </button>
        </div>

        {/* care-team alert — a calm nudge toward the Care hub */}
        {s.careUnreadCount > 0 && (
          <Press onClick={() => s.setTab("care")} className="mt-7 w-full text-left block">
            <OrganicCard className="p-4 flex items-center gap-3">
              <div className="relative size-10 rounded-full grid place-items-center shrink-0" style={{ background: "rgb(var(--sky) / 0.16)" }}>
                <Icon name="cross.case" size={18} className="text-sky" />
                <span className="absolute -top-0.5 -right-0.5 size-2.5 rounded-full" style={{ background: "rgb(var(--warm))", boxShadow: "0 0 0 2px rgb(var(--surface))" }} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-serif text-[15.5px] text-ink leading-tight">{careAlertTitle}</p>
                <p className="font-rounded text-[12px] text-ink-muted">Tap to open your Care hub</p>
              </div>
              <Icon name="chevronRight" size={16} className="text-ink-muted" />
            </OrganicCard>
          </Press>
        )}

        {/* agent action */}
        {action && <div className="mt-7"><AgentActionCard action={action} /></div>}

        {/* the agent network, surfaced — calm by default, capable when you look */}
        {(s.agentTasksInMotion.length > 0 || s.agentTasksWaiting.length > 0) && <div className="mt-5"><AgentPulseCard /></div>}

        {/* the thread */}
        <div className="mt-6 space-y-3">
          {s.moments.length > 0 ? (
            s.moments.slice(0, 3).map((m) => <MomentCard key={m.id} moment={m} />)
          ) : (
            <OrganicCard className="p-5 flex items-center gap-4">
              <SceneVisual seed={4} height={56} className="w-16 shrink-0" />
              <p className="font-serif text-[16px] text-ink">You're set for now — I'll keep watch.</p>
            </OrganicCard>
          )}
        </div>

        {/* life strip */}
        <div className="mt-7">
          <div className="flex items-center justify-between mb-3">
            <Kicker>Today at your table</Kicker>
            <Press onClick={() => { s.setTab("you"); s.setPendingCareDest(null); window.dispatchEvent(new CustomEvent("sano.openLife")); }} className="text-[12px] font-rounded text-warm font-medium">See it all</Press>
          </div>
          {todayEntries.length > 0 ? (
            <div className="flex gap-3 overflow-x-auto -mx-5 px-5 pb-1">
              {todayEntries.map((e) => (
                <div key={e.id} className="shrink-0 w-[92px]">
                  <div className="size-[92px] rounded-2xl overflow-hidden relative ring-1 ring-white/40 shadow-lg">
                    <img src={img(e.imageName) ?? ""} alt="" className="absolute inset-0 w-full h-full object-cover" />
                  </div>
                  <p className="font-rounded text-[11.5px] text-ink mt-1.5 leading-tight line-clamp-1">{e.title}</p>
                  <p className="tnum text-[10px] text-ink-muted">{fmtTime(e.at)}</p>
                </div>
              ))}
            </div>
          ) : (
            <p className="font-rounded text-[13px] text-ink-muted">Nothing logged yet — the '+' is right there, glowing.</p>
          )}
        </div>
      </div>

      {/* floating + */}
      <div className="absolute bottom-24 right-5 z-30">
        <button onClick={() => s.setShowQuickLog(true)} className="press relative grid place-items-center size-14 rounded-full glass-strong" aria-label="Log something">
          <span className="absolute -inset-1 rounded-full anim-halo" style={{ background: "conic-gradient(from 0deg, rgb(var(--warm)), rgb(var(--rose)), rgb(var(--gold)), rgb(var(--warm)))", filter: "blur(8px)", opacity: 0.6 }} />
          <Icon name="plus" size={24} className="relative text-ink" />
        </button>
      </div>
    </div>
  );
};

const accentByKind: Record<string, string> = { insight: "sky", habit: "life", task: "gold", checkIn: "warm" };
const glyphByKind: Record<string, string> = { insight: "sparkles", habit: "leaf", task: "pill", checkIn: "heart" };

const MomentCard: React.FC<{ moment: Moment }> = ({ moment }) => {
  const s = useSano();
  const [gone, setGone] = useState(false);
  const accent = accentByKind[moment.kind] ?? "warm";
  const thumb = moment.kind === "task" ? img("medicine_bottle_pills") : moment.kind === "habit" ? img("terracotta_cream_sneakers") : null;

  const act = () => {
    SoundEngine.tick();
    if (moment.kind === "insight") { s.setTab("you"); if (moment.insightID) s.markInsightSeen(moment.insightID); }
    else if (moment.kind === "task") s.openConversation("refill");
    else s.openConversation(moment.kind === "checkIn" ? "check-in" : "habit");
  };

  return (
    <OrganicCard className={`p-4 flex items-start gap-3.5 transition-all duration-500 ${gone ? "opacity-0 translate-x-12" : "anim-rise"}`}>
      <div className="size-14 rounded-2xl overflow-hidden relative shrink-0">
        {thumb ? <img src={thumb} alt="" className="absolute inset-0 w-full h-full object-cover" /> : (
          <div className="absolute inset-0 grid place-items-center" style={{ background: `linear-gradient(140deg, rgb(var(--${accent}) / 0.3), rgb(var(--${accent}) / 0.12))` }}>
            <Icon name={glyphByKind[moment.kind] ?? "sparkles"} size={22} className={accentText[accent]} />
          </div>
        )}
      </div>
      <div className="min-w-0 flex-1">
        <h3 className="font-serif text-[17px] text-ink leading-tight">{moment.title}</h3>
        <p className="font-rounded text-[13px] text-ink-muted mt-1 leading-snug">{moment.body}</p>
        <div className="flex items-center gap-2 mt-2.5">
          <Press onClick={act} className="rounded-full px-3.5 py-1.5 text-[12.5px] font-rounded font-semibold glass text-ink">{moment.actionLabel}</Press>
          <Press sound={false} onClick={() => { setGone(true); setTimeout(() => s.dismissMoment(moment.id), 480); }} className="text-ink-muted/60 text-[12px] font-rounded px-1">dismiss</Press>
        </div>
      </div>
    </OrganicCard>
  );
};

export const AgentActionCard: React.FC<{ action: AgentAction }> = ({ action }) => {
  const s = useSano();
  return (
    <OrganicCard className="relative overflow-hidden p-4 anim-sweep">
      <div className="flex items-start gap-3">
        <div className="size-10 rounded-full grid place-items-center shrink-0" style={{ background: "rgb(var(--gold) / 0.2)" }}><Icon name={action.glyph} size={18} className="text-gold" /></div>
        <div className="min-w-0">
          <Kicker className="text-gold">I can take this one</Kicker>
          <h3 className="font-serif text-[17px] text-ink mt-0.5 leading-tight">{action.title}</h3>
          <p className="font-rounded text-[13px] text-ink-muted mt-1 leading-snug">{action.detail}</p>
        </div>
      </div>
      <div className="flex items-center gap-2 mt-3">
        <Press onClick={() => s.approveAction(action.id)} className="rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>{action.leavesDevice ? "Approve & go" : "Yes, do it"}</Press>
        <Press onClick={() => s.declineAction(action.id)} className="rounded-full px-4 py-2 text-[13px] font-rounded glass text-ink">Not now</Press>
      </div>
      {action.leavesDevice && <p className="mt-2.5 flex items-center gap-1.5 text-[11.5px] font-rounded text-ink-muted"><Icon name="hand" size={12} />Nothing sends without you.</p>}
    </OrganicCard>
  );
};
