import React, { useEffect, useState } from "react";
import { useSano } from "../store";
import { OrganicCard, Press, Kicker, ProvenanceChip, accentText } from "../ui/Glass";
import { Icon } from "../ui/Icon";
import { agentModeLabel, type AgentTask, type AgentSource } from "../agentNetwork";

/** The agent network, made visible — the full modal mounted from the shell. */
export const AgentNetworkSheet: React.FC = () => {
  const s = useSano();
  const [agentID, setAgentID] = useState<string | null>(s.agentNetworkFocus);

  useEffect(() => {
    if (s.showAgentNetwork) setAgentID(s.agentNetworkFocus);
  }, [s.showAgentNetwork, s.agentNetworkFocus]);

  const service = s.agentServices.find((a) => a.id === agentID) ?? null;

  return (
    <div className="min-h-full">
      <div className="sticky top-0 z-10 flex items-center gap-2 px-5 py-3" style={{ background: "rgb(var(--base) / 0.85)", backdropFilter: "blur(10px)" }}>
        {agentID && (
          <Press onClick={() => setAgentID(null)} className="grid place-items-center size-9 rounded-full glass text-ink/80">
            <Icon name="chevronLeft" size={16} />
          </Press>
        )}
        <h2 className="font-serif text-[19px] text-ink flex-1 truncate">{service ? service.name : "Your Rumi network"}</h2>
        <Press onClick={() => s.setShowAgentNetwork(false)} className="rounded-full px-3.5 py-1.5 text-[13px] font-rounded font-semibold glass text-ink">Done</Press>
      </div>
      <div className="px-5 pb-12">
        {service ? <AgentDetail agentID={service.id} /> : <NetworkList onOpen={setAgentID} />}
      </div>
    </div>
  );
};

const NetworkList: React.FC<{ onOpen: (id: string) => void }> = ({ onOpen }) => {
  const s = useSano();
  const live = ["Your record", "Apple Health", "Your pharmacy", ...s.connections.filter((c) => c.connected).map((c) => c.name)];
  const unconnected = s.connections.filter((c) => !c.connected);
  return (
    <div className="space-y-5 pt-1">
      <div>
        <h1 className="font-serif text-[26px] text-ink leading-tight">One companion, many hands</h1>
        <p className="font-rounded text-[14px] text-ink-muted mt-1.5">A family of specialized agents works quietly behind Rumi — noticing, arranging, and protecting your time. Here's what each is doing right now.</p>
      </div>

      <OrganicCard className="p-4">
        <div className="flex items-center gap-2.5">
          <div className="size-8 rounded-full grid place-items-center shrink-0" style={{ background: "rgb(var(--sky) / 0.16)" }}><Icon name="link" size={15} className="text-sky" /></div>
          <p className="font-serif text-[16px] text-ink">Reading across your world</p>
        </div>
        <p className="font-rounded text-[13px] text-ink-muted mt-2">Rumi connects the dots between everything you've shared — proactively, and the moment something new lands.</p>
        <div className="flex flex-wrap gap-1.5 mt-3">
          {live.map((label) => <SourceTag key={label} label={label} active />)}
        </div>
        {unconnected.length > 0 && (
          <p className="font-rounded text-[12px] text-ink-muted mt-2.5">Connect {unconnected.map((c) => c.name).join(", ")} to widen what your agents can see and do.</p>
        )}
      </OrganicCard>

      {s.agentTasksWaiting.length > 0 && (
        <div>
          <Kicker className="text-warm mb-2">Waiting for your ok</Kicker>
          <div className="space-y-2.5">
            {s.agentTasksWaiting.map((t) => <AgentTaskCard key={t.id} task={t} showAgent />)}
          </div>
        </div>
      )}

      <div>
        <Kicker className="text-sky mb-2">The family</Kicker>
        <div className="space-y-2.5">
          {s.agentServices.map((service) => {
            const waiting = s.waitingCount(service.id);
            const active = s.activeTaskCount(service.id);
            const status = !service.active ? "Paused — tap to see its work" : waiting > 0 ? `${waiting} waiting · ${active} in motion` : active > 0 ? `${active} in motion` : service.role;
            return (
              <Press key={service.id} onClick={() => onOpen(service.id)} className="w-full text-left">
                <OrganicCard className="p-3.5 flex items-center gap-3">
                  <div className="size-11 rounded-full grid place-items-center shrink-0" style={{ background: `rgb(var(--${service.accent}) / ${service.active ? 0.16 : 0.08})` }}>
                    <Icon name={service.glyph} size={17} className={service.active ? accentText[service.accent] : "text-ink-muted"} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-serif text-[15.5px] text-ink leading-tight">{service.name}</p>
                    <p className={`font-rounded text-[12px] ${waiting > 0 ? "text-warm" : "text-ink-muted"} truncate`}>{status}</p>
                  </div>
                  {waiting > 0 && <span className="min-w-5 h-5 px-1.5 rounded-full grid place-items-center text-[11px] font-rounded font-bold text-base shrink-0" style={{ background: "rgb(var(--warm))" }}>{waiting}</span>}
                  <Icon name="chevronRight" size={16} className="text-ink-muted shrink-0" />
                </OrganicCard>
              </Press>
            );
          })}
        </div>
      </div>

      <ProvenanceChip text="Your agents only read what you've connected — and ask before anything leaves your phone." className="px-1" />
    </div>
  );
};

const AgentDetail: React.FC<{ agentID: string }> = ({ agentID }) => {
  const s = useSano();
  const service = s.agentServices.find((a) => a.id === agentID);
  if (!service) return null;
  const tasks = s.tasksForAgent(agentID);
  const groups: { title: string; items: AgentTask[] }[] = [
    { title: "Waiting for your ok", items: tasks.filter((t) => t.status === "waiting") },
    { title: "Working now", items: tasks.filter((t) => t.status === "working") },
    { title: "Queued up", items: tasks.filter((t) => t.status === "scheduled") },
    { title: "Recently done", items: tasks.filter((t) => t.status === "done") },
  ].filter((g) => g.items.length > 0);

  return (
    <div className="space-y-5 pt-1">
      <div className="flex items-start gap-3">
        <div className="size-14 rounded-full grid place-items-center shrink-0" style={{ background: `rgb(var(--${service.accent}) / 0.16)` }}>
          <Icon name={service.glyph} size={24} className={accentText[service.accent]} />
        </div>
        <div className="min-w-0">
          <h1 className="font-serif text-[23px] text-ink leading-tight">{service.name}</h1>
          <p className="font-rounded text-[13px] text-ink-muted mt-1">{service.role}</p>
        </div>
      </div>

      <Press onClick={() => s.toggleAgentService(service.id)} className="w-full text-left rounded-2xl glass p-3.5 flex items-center gap-2.5">
        <span className="size-2 rounded-full" style={{ background: service.active ? "rgb(var(--life))" : "rgb(var(--ink-muted) / 0.5)" }} />
        <span className={`font-rounded text-[13px] font-semibold flex-1 ${service.active ? "text-life" : "text-ink-muted"}`}>{service.active ? "Active — working for you" : "Paused"}</span>
        <span className="rounded-full px-3 py-1.5 text-[12.5px] font-rounded font-semibold glass text-ink">{service.active ? "Pause" : "Resume"}</span>
      </Press>

      {groups.length === 0 ? (
        <OrganicCard className="p-6 grid place-items-center text-center">
          <Icon name="check" size={24} className="text-life" />
          <p className="font-rounded text-[13.5px] text-ink-muted mt-2">All quiet here — nothing needs you.</p>
        </OrganicCard>
      ) : (
        groups.map((g) => (
          <div key={g.title}>
            <Kicker className={`mb-2 ${g.title.includes("ok") ? "text-warm" : "text-sky"}`}>{g.title}</Kicker>
            <div className="space-y-2.5">{g.items.map((t) => <AgentTaskCard key={t.id} task={t} />)}</div>
          </div>
        ))
      )}

      <ProvenanceChip text="Pausing an agent stops its work without losing anything it's already done." className="px-1" />
    </div>
  );
};

const AgentTaskCard: React.FC<{ task: AgentTask; showAgent?: boolean }> = ({ task, showAgent }) => {
  const s = useSano();
  const agentName = s.agentServices.find((a) => a.id === task.agentID)?.name;
  const isAuto = task.mode === "automatic";
  const tint = isAuto ? "sky" : "warm";
  return (
    <OrganicCard className="p-4">
      <div className="flex items-center gap-2">
        <span className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-rounded font-semibold" style={{ color: `rgb(var(--${tint}))`, background: `rgb(var(--${tint}) / 0.13)` }}>
          <Icon name={isAuto ? "sparkles" : "hand"} size={9} />{agentModeLabel(task.mode)}
        </span>
        <div className="flex-1" />
        {showAgent && agentName && <span className="font-rounded text-[11px] text-ink-muted">{agentName}</span>}
        {task.status === "done" && <Icon name="check" size={14} className="text-life" />}
      </div>
      <h3 className="font-serif text-[16px] text-ink mt-2 leading-tight">{task.title}</h3>
      <p className="font-rounded text-[13px] text-ink-muted mt-1 leading-snug">{task.status === "done" ? task.outcomeLine : task.detail}</p>
      {task.sources.length > 0 && (
        <div className="flex flex-wrap gap-1.5 mt-2.5">
          {task.sources.map((src) => <SourceChip key={src.label} source={src} />)}
        </div>
      )}
      <div className="flex items-center gap-1.5 mt-2.5 text-ink-muted/85">
        <Icon name="calendar-check" size={11} /><span className="font-rounded text-[11.5px] font-medium">{task.cadence}</span>
      </div>
      {task.status === "waiting" && (
        <div className="flex items-center gap-2 mt-3">
          <Press onClick={() => s.approveAgentTask(task.id)} className="rounded-full px-4 py-2 text-[13px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Approve & go</Press>
          <Press onClick={() => s.declineAgentTask(task.id)} className="rounded-full px-4 py-2 text-[13px] font-rounded glass text-ink">Not now</Press>
        </div>
      )}
    </OrganicCard>
  );
};

const SourceChip: React.FC<{ source: AgentSource }> = ({ source }) => {
  const s = useSano();
  const connection = source.connectionID ? s.connections.find((c) => c.id === source.connectionID) : null;
  const needsConnect = connection != null && !connection.connected;
  if (needsConnect && connection) {
    return (
      <Press onClick={() => s.toggleConnection(connection.id)} className="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[10.5px] font-rounded font-medium glass text-ink-muted">
        <Icon name="plus" size={9} />Connect {source.label}
      </Press>
    );
  }
  return <SourceTag label={source.label} active />;
};

const SourceTag: React.FC<{ label: string; active?: boolean }> = ({ label, active }) => (
  <span className="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[10.5px] font-rounded font-medium" style={{ color: "rgb(var(--ink) / 0.75)", background: active ? "rgb(var(--life) / 0.1)" : "rgb(var(--ink-muted) / 0.1)" }}>
    <span className="size-1.5 rounded-full" style={{ background: active ? "rgb(var(--life))" : "rgb(var(--ink-muted))" }} />{label}
  </span>
);

/** Compact Today presence — calm by default, capable when you look. */
export const AgentPulseCard: React.FC = () => {
  const s = useSano();
  const inMotion = s.agentTasksInMotion.length;
  const waiting = s.agentTasksWaiting;
  const first = waiting[0];
  const summary = waiting.length > 0 ? `${inMotion} in motion · ${waiting.length} waiting for your ok` : `${inMotion} things in motion across your agents`;
  const dots = s.agentServices.filter((a) => a.active && s.activeTaskCount(a.id) > 0).slice(0, 4);

  return (
    <OrganicCard className="p-4">
      <Press onClick={() => s.openAgentNetwork()} className="w-full text-left flex items-center gap-3">
        <div className="relative shrink-0" style={{ width: 28 + 17 * Math.max(0, dots.length - 1), height: 28 }}>
          {dots.map((a, i) => (
            <span key={a.id} className="absolute top-0 grid place-items-center size-7 rounded-full" style={{ left: i * 17, background: "rgb(var(--surface))", boxShadow: "0 0 0 1.5px rgb(var(--base))" }}>
              <Icon name={a.glyph} size={11} className={accentText[a.accent]} />
            </span>
          ))}
        </div>
        <div className="flex-1 min-w-0">
          <div className="kicker text-sky">Your network is on it</div>
          <p className="font-rounded text-[12.5px] text-ink-muted mt-0.5">{summary}</p>
        </div>
        <Icon name="chevronRight" size={15} className="text-ink-muted" />
      </Press>

      {first && (
        <div className="mt-3 pt-3" style={{ borderTop: "1px solid rgb(var(--edge))" }}>
          <div className="flex items-center gap-1.5">
            <Icon name="hand" size={11} className="text-warm" />
            <p className="font-serif text-[15px] text-ink leading-tight">{first.title}</p>
          </div>
          <p className="font-rounded text-[12.5px] text-ink-muted mt-1 leading-snug line-clamp-2">{first.detail}</p>
          <div className="flex items-center gap-2 mt-2.5">
            <Press onClick={() => s.approveAgentTask(first.id)} className="rounded-full px-4 py-1.5 text-[12.5px] font-rounded font-semibold" style={{ background: "rgb(var(--ink))", color: "rgb(var(--base))" }}>Approve & go</Press>
            <Press onClick={() => s.declineAgentTask(first.id)} className="rounded-full px-4 py-1.5 text-[12.5px] font-rounded glass text-ink">Not now</Press>
            {waiting.length > 1 && <span className="font-rounded text-[11.5px] text-ink-muted">+{waiting.length - 1} more</span>}
          </div>
        </div>
      )}
    </OrganicCard>
  );
};
