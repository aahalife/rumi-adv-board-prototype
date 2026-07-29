import type { RichElement, ConversationTurn } from "./types";

const TOOLKIT_URL = (import.meta.env.EXPO_PUBLIC_TOOLKIT_URL as string) || "https://toolkit.rork.com";
const TOOLKIT_KEY = (import.meta.env.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY as string) || "";
const MODEL = "anthropic/claude-sonnet-4.6";
const FUNCTIONS_URL = (import.meta.env.EXPO_PUBLIC_RORK_FUNCTIONS_URL as string) || "https://nudge-plus-d9rx5y5-backend.rork.app";

export interface ChatMessage { role: "user" | "assistant"; content: string }

/** Stream a completion token-by-token. Calls onDelta with visible chunks and
 *  resolves with the full raw text (tags included). Throws on network failure
 *  so the caller can fall back to the scripted brain. */
export async function streamChat(
  system: string,
  messages: ChatMessage[],
  onDelta: (delta: string) => void,
  signal?: AbortSignal,
): Promise<string> {
  const res = await fetch(`${TOOLKIT_URL}/v2/vercel/v1/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${TOOLKIT_KEY}`,
    },
    body: JSON.stringify({
      model: MODEL,
      stream: true,
      messages: [{ role: "system", content: system }, ...messages],
    }),
    signal,
  });
  if (!res.ok || !res.body) throw new Error(`chat ${res.status}`);

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let raw = "";
  let buffer = "";
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";
    for (const line of lines) {
      const t = line.trim();
      if (!t.startsWith("data:")) continue;
      const payload = t.slice(5).trim();
      if (payload === "[DONE]") continue;
      try {
        const json = JSON.parse(payload);
        const delta: string = json?.choices?.[0]?.delta?.content ?? "";
        if (delta) { raw += delta; onDelta(delta); }
      } catch {
        /* keep partial line in buffer next round */
      }
    }
  }
  return raw;
}

/** Strip `[[kind:payload]]` tags; returns clean text + the first rich element. */
export function parseTags(input: string): { text: string; rich: RichElement } {
  let text = input;
  let rich: RichElement = { t: "none" };
  for (;;) {
    const open = text.indexOf("[[");
    if (open < 0) break;
    const close = text.indexOf("]]", open + 2);
    if (close < 0) break;
    const inner = text.slice(open + 2, close);
    text = text.slice(0, open) + text.slice(close + 2);
    if (rich.t !== "none") continue;
    const ci = inner.indexOf(":");
    const kind = (ci < 0 ? inner : inner.slice(0, ci)).trim().toLowerCase();
    const payload = ci < 0 ? "" : inner.slice(ci + 1).trim();
    const parts = payload.split("|").map((p) => p.trim());
    switch (kind) {
      case "trend": rich = { t: "trend", id: payload.toLowerCase() }; break;
      case "habit": rich = { t: "habitProposal", title: parts[0] || payload, context: parts[1] || "whenever today allows" }; break;
      case "refill": rich = { t: "refillFix", med: parts[0] || payload, detail: parts[1] || "Ready at your pharmacy" }; break;
      case "guide": rich = { t: "guideAdd", question: payload }; break;
      case "action": rich = { t: "agentAction", title: parts[0] || payload, detail: parts[1] || "I'll take care of it — you approve first." }; break;
      case "program": rich = { t: "program", title: payload }; break;
    }
  }
  return { text: text.trim(), rich };
}

/** As tokens arrive we withhold anything inside [[...]] from the visible stream. */
export function makeHoldbackFilter() {
  let holdback = "";
  return (delta: string): string => {
    holdback += delta;
    let visible = "";
    for (;;) {
      const open = holdback.indexOf("[[");
      if (open >= 0) {
        visible += holdback.slice(0, open);
        const close = holdback.indexOf("]]", open + 2);
        if (close >= 0) {
          holdback = holdback.slice(close + 2);
        } else {
          holdback = holdback.slice(open);
          return visible;
        }
      } else if (holdback.endsWith("[")) {
        visible += holdback.slice(0, -1);
        holdback = "[";
        return visible;
      } else {
        visible += holdback;
        holdback = "";
        return visible;
      }
    }
  };
}

export const newTurn = (role: "user" | "companion", text: string, streaming = false): ConversationTurn => ({
  id: `turn_${Math.random().toString(36).slice(2)}`,
  role, text, rich: { t: "none" }, richResolved: false, streaming,
});

/** Offline grace — the companion never goes silent. */
export function localReply(name: string, text: string): string {
  const t = text.toLowerCase();
  if (t.includes("greeting") || t.includes("open the conversation")) {
    const h = new Date().getHours();
    const opener = h < 12 ? "Morning" : h < 17 ? "Afternoon" : "Evening";
    return `${opener}, ${name}. Quiet day on my end — everything synced, nothing waving for attention. What's on your mind?`;
  }
  if (t.includes("tired") || t.includes("rough") || t.includes("hard")) {
    return "That sounds like a heavy one, and I'm not going to pretend a tip fixes it. Nothing needs solving tonight. If you want, tell me the hardest part — sometimes it belongs to the schedule, not to you.";
  }
  if (t.includes("symptom") || t.includes("logged")) {
    return "Let's sit with it for a minute. Tell me when it started and what you were doing — I'll hold it against your meds, your readings, and the week you've had.";
  }
  if (t.includes("refill")) {
    return "I can take that off your plate. Want me to set the atorvastatin refill to free delivery so it just arrives?";
  }
  return "Tell me more — I'd rather understand it right than answer it fast.";
}

export const HAS_KEY = TOOLKIT_KEY.length > 0;
export { TOOLKIT_URL, TOOLKIT_KEY, MODEL, FUNCTIONS_URL };
