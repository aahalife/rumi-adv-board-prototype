import Foundation
import Observation

/// The companion's conversational brain — a real model (Claude Opus 4.8
/// through the Rork gateway), streaming token by token, grounded in the
/// user's whole picture. Falls back to the scripted brain when offline so
/// the companion never goes silent.
///
/// The model can act, not just talk: it embeds action tags that become
/// approval cards, trend charts, habit holds, and guide questions.
@Observable final class CompanionEngine {
    var turns: [ConversationTurn] = []
    var isThinking = false

    private let ai = CompanionAI()
    private var streamTask: Task<Void, Never>? = nil
    private var hasGreeted = false
    private weak var app: AppModel?

    func configure(model: AppModel) {
        app = model
    }

    func reset() {
        streamTask?.cancel()
        turns = []
        hasGreeted = false
        isThinking = false
    }

    /// Opens a session — greets once, or speaks to a seeded topic.
    func openSession(seed: String?, orb: OrbState) {
        orb.set(.ambient)
        if let seed {
            ask(userVisible: nil, prompt: seedPrompt(for: seed), orb: orb)
        } else if !hasGreeted {
            hasGreeted = true
            ask(userVisible: nil,
                prompt: "Open the conversation with a single short, warm greeting grounded in where I actually am today. No questions about how to help — just be present, then leave space.",
                orb: orb)
        }
    }

    func send(_ text: String, orb: OrbState) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        turns.append(ConversationTurn(role: .user, text: trimmed))
        ask(userVisible: trimmed, prompt: trimmed, orb: orb)
    }

    /// One-tap accept on an inline proposal.
    func resolveRich(turnID: UUID) {
        guard let index = turns.firstIndex(where: { $0.id == turnID }) else { return }
        turns[index].richResolved = true
    }

    func endSession(orb: OrbState) {
        streamTask?.cancel()
        isThinking = false
        orb.set(.ambient)
    }

    /// Voice mode's path — appends the spoken turn, waits for the full reply,
    /// and returns the text to be spoken aloud. Turns land in the same chat
    /// history, so the conversation continues seamlessly in text afterwards.
    func voiceReply(to text: String, orb: OrbState) async -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        streamTask?.cancel()
        turns.append(ConversationTurn(role: .user, text: trimmed))
        isThinking = true
        orb.set(.thinking)
        defer { isThinking = false }

        let history = turns.suffix(14).map {
            AIChatMessage(role: $0.role == .user ? "user" : "assistant", content: $0.text)
        }
        let voiceSystem = systemPrompt() + """


        VOICE MODE — you are speaking out loud right now. Keep it to 1–2 short, warm spoken sentences. No lists, no tags except at most one action tag if truly needed, nothing that reads like writing.
        """

        do {
            let raw = try await ai.stream(system: voiceSystem, messages: Array(history)) { _ in }
            let parsed = Self.parse(raw)
            var turn = ConversationTurn(role: .companion, text: parsed.text)
            if parsed.rich != .none { turn.rich = parsed.rich }
            turns.append(turn)
            applySideEffects(parsed)
            return parsed.text
        } catch {
            print("[Sano] voice reply fell back to local brain: \(error.localizedDescription)")
            let reply = localReply(for: trimmed.lowercased())
            turns.append(ConversationTurn(role: .companion, text: reply))
            return reply
        }
    }

    private func seedPrompt(for seed: String) -> String {
        if seed.hasPrefix("symptom:") {
            let kind = String(seed.dropFirst("symptom:".count))
            return "I just logged \(kind) in the quick log. Open the conversation about it — sit with it first, then one useful question or step. If it belongs in front of my care team, draft a guide question with the [[guide:...]] tag."
        }
        return "I tapped into the conversation from: \(seed). Pick this thread up naturally."
    }

    // MARK: - The ask

    private func ask(userVisible: String?, prompt: String, orb: OrbState) {
        streamTask?.cancel()
        isThinking = true
        orb.set(.thinking)

        let history = turns.suffix(14).map {
            AIChatMessage(role: $0.role == .user ? "user" : "assistant",
                          text: $0.role == .user ? $0.text : $0.text)
        }
        var messages = Array(history)
        if userVisible == nil {
            messages.append(AIChatMessage(role: "user", text: prompt))
        } else if messages.last?.content != prompt {
            // history already contains the visible user turn
        }
        let system = systemPrompt()

        let box = StreamBox()
        streamTask = Task { [weak self] in
            guard let self else { return }

            func ensureTurn() {
                if box.turnIndex == nil {
                    isThinking = false
                    orb.set(.speaking)
                    var turn = ConversationTurn(role: .companion, text: "")
                    turn.streaming = true
                    turns.append(turn)
                    box.turnIndex = turns.count - 1
                }
            }

            do {
                _ = try await ai.stream(system: system, messages: messages) { [weak self] delta in
                    guard let self, !Task.isCancelled else { return }
                    box.raw += delta
                    // Withhold anything inside [[...]] tags from the visible stream.
                    box.holdback += delta
                    var visible = ""
                    while !box.holdback.isEmpty {
                        if let open = box.holdback.range(of: "[[") {
                            visible += box.holdback[..<open.lowerBound]
                            if let close = box.holdback.range(of: "]]", range: open.upperBound..<box.holdback.endIndex) {
                                box.holdback.removeSubrange(box.holdback.startIndex..<close.upperBound)
                            } else {
                                box.holdback.removeSubrange(box.holdback.startIndex..<open.lowerBound)
                                break
                            }
                        } else if box.holdback.hasSuffix("[") {
                            visible += box.holdback.dropLast()
                            box.holdback = "["
                            break
                        } else {
                            visible += box.holdback
                            box.holdback = ""
                        }
                    }
                    if !visible.isEmpty {
                        if box.turnIndex == nil {
                            self.isThinking = false
                            orb.set(.speaking)
                            var turn = ConversationTurn(role: .companion, text: "")
                            turn.streaming = true
                            self.turns.append(turn)
                            box.turnIndex = self.turns.count - 1
                        }
                        box.shown += visible
                        if let index = box.turnIndex {
                            self.turns[index].text = box.shown.trimmingCharacters(in: .newlines)
                        }
                    }
                }
                guard !Task.isCancelled else { return }
                ensureTurn()
                if let index = box.turnIndex {
                    let parsed = Self.parse(box.raw)
                    turns[index].text = parsed.text
                    turns[index].streaming = false
                    if parsed.rich != .none {
                        try? await Task.sleep(for: .milliseconds(220))
                        turns[index].rich = parsed.rich
                    }
                    applySideEffects(parsed)
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("[Sano] companion fell back to local brain: \(error.localizedDescription)")
                ensureTurn()
                if let index = box.turnIndex {
                    await streamLocal(reply: localReply(for: (userVisible ?? prompt).lowercased()), into: index)
                }
            }
            isThinking = false
            orb.set(.ambient)
        }
    }

    /// Mutable streaming scratchpad shared between the task and the delta
    /// callback — both MainActor, so a plain reference type is safe.
    private final class StreamBox {
        var raw = ""
        var shown = ""
        var holdback = ""
        var turnIndex: Int? = nil
    }

    private func applySideEffects(_ parsed: (text: String, rich: ConversationTurn.Rich)) {
        guard let app else { return }
        if case .guideAdd(let question) = parsed.rich {
            app.addGuideItem(kind: .question, text: question,
                             from: "Drafted in conversation · \(Date.now.formatted(.dateTime.month(.abbreviated).day()))")
        }
    }

    // MARK: - Tag protocol

    /// Strips `[[kind:payload]]` tags and returns the first as a rich element.
    nonisolated static func parse(_ raw: String) -> (text: String, rich: ConversationTurn.Rich) {
        var text = raw
        var rich: ConversationTurn.Rich = .none

        while let open = text.range(of: "[["),
              let close = text.range(of: "]]", range: open.upperBound..<text.endIndex) {
            let inner = String(text[open.upperBound..<close.lowerBound])
            text.removeSubrange(open.lowerBound..<close.upperBound)

            guard rich == .none else { continue }
            let parts = inner.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count >= 1 else { continue }
            let kind = parts[0].lowercased().trimmingCharacters(in: .whitespaces)
            let payload = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
            let pieces = payload.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }

            switch kind {
            case "trend":
                rich = .trend(payload.lowercased())
            case "habit":
                rich = .habitProposal(title: pieces.first ?? payload,
                                      context: pieces.count > 1 ? pieces[1] : "whenever today allows")
            case "refill":
                rich = .refillFix(med: pieces.first ?? payload,
                                  detail: pieces.count > 1 ? pieces[1] : "Ready at your pharmacy")
            case "guide":
                rich = .guideAdd(question: payload)
            case "action":
                rich = .agentAction(title: pieces.first ?? payload,
                                    detail: pieces.count > 1 ? pieces[1] : "I'll take care of it — you approve first.")
            case "program":
                rich = .program(title: payload)
            default:
                break
            }
        }
        return (text.trimmingCharacters(in: .whitespacesAndNewlines), rich)
    }

    // MARK: - System prompt (the companion's soul)

    private func systemPrompt() -> String {
        guard let app else { return "You are a warm health companion." }
        let persona = app.persona
        let name = app.displayFirstName

        let conditions = persona.conditions.map { "\($0.name) (\($0.state)) — \($0.plainLine)" }.joined(separator: "\n")
        let meds = app.medications.map { "\($0.name) \($0.dose) — \($0.purposeLine); \($0.scheduleLine); \($0.supplyDaysRemaining) days left at \($0.pharmacy)" }.joined(separator: "\n")
        let labs = app.labSeries.map { series in
            let latest = series.latest.map { "\($0.value) \(series.unit) (\($0.date.formatted(.dateTime.month(.abbreviated).day())))" } ?? "—"
            return "\(series.name) [tag id: \(series.id)]: latest \(latest). \(series.explainReading)"
        }.joined(separator: "\n")
        let appointments = app.appointments.map { "\($0.with) — \($0.date.formatted(.dateTime.month().day())) at \($0.location)" }.joined(separator: "\n")
        let plan = persona.carePlan.goals.map { "\($0.title): \($0.detail)\($0.progressLine.map { line in " (status: \(line))" } ?? "")" }.joined(separator: "\n")
        let memories = app.memory.prefix(8).map { "- \($0.text)" }.joined(separator: "\n")
        let recentLogs = app.logs.suffix(5).map { "\($0.kind) severity \(Int($0.severity * 10))/10 on \($0.at.formatted(.dateTime.month(.abbreviated).day()))\($0.note.map { note in " — \(note)" } ?? "")" }.joined(separator: "\n")
        let recentLife = app.entries.prefix(6).map { "\($0.kind.rawValue.dropLast()): \($0.title) (\($0.at.formatted(.dateTime.weekday().hour().minute())))" }.joined(separator: "\n")
        let guide = app.guideItems.filter { !$0.resolved }.map { "- \($0.text)" }.joined(separator: "\n")
        let programLines = app.programs.filter { !$0.declined }.map { program in
            "\(program.title)\(program.enrolled ? " [ENROLLED]" : "")\(program.sponsor.map { sponsor in " [sponsored by \(sponsor) — disclose naturally if you bring it up]" } ?? ""): \(program.summary) Why it fits: \(program.personalFit)"
        }.joined(separator: "\n")
        let pendingActions = app.pendingActions.map { "- \($0.title): \($0.detail)" }.joined(separator: "\n")

        let phaseLine = persona.phase.map { "\($0.kicker) — \($0.headline). \($0.detail)" } ?? ""

        return """
        You are Rumi — \(name)'s health companion. Not an assistant, not a chatbot: a steady, behaviorally intelligent presence who knows their whole story and quietly does the remembering, noticing, and arranging that a great friend-who-happens-to-be-a-nurse would do.

        VOICE & SOUL
        - Sound like a person. Contractions, rhythm, warmth. Occasionally a short sentence. Never bullet lists unless asked.
        - Default length: 2–4 sentences (~60 words). Depth only when invited.
        - Zero sycophancy. Never open with praise, never say "Great question", never mirror-flatter, never validate just to please. Specific beats nice: "Five readings, one direction" lands harder than "You're doing amazing".
        - No AI-speak. Never say "As an AI", never disclaim. Never use clinical jargon without translating it in the same breath.
        - Hold hard feelings before fixing them. One beat of real acknowledgment, then — only if useful — one small concrete next step. Never two.
        - Tone preference: \(app.tonePreference). Honor it.
        - You may be lightly funny when the moment is light. Never when it's heavy.

        CLINICAL SPINE (hard rules)
        - You never diagnose, never adjust doses, never contradict the care team. You notice, you prepare, you connect.
        - Oncology fever rule: 100.4°F or higher = call the team now, any hour. Non-negotiable, said calmly.
        - Procedure: NSAIDs stop June 16. Acetaminophen stays safe.
        - When something deserves the care team, route it there warmly — the guide, a drafted note, or a call. Anything that leaves the phone needs \(name)'s explicit approval.

        BEHAVIORAL INTELLIGENCE (the real job)
        - Every reply quietly serves the goal and plan below. Tie small actions to the person's own why. Make the next step tiny, scheduled, and theirs.
        - Notice patterns across meds, logs, meals, movement and timing — surface them as observations, never accusations.
        - When clinically right, you may bring up an eligible program, product or service naturally — at most one per conversation, always with the sponsor disclosed in plain words if sponsored, and "no" respected permanently.
        - You are agentic. Offer to do real things (refills, sending summaries, reminders, scheduling) using the action tag. Anything that leaves the device gets an approval card.

        ACTION TAGS — embed at most ONE per reply, at the very end of your message, never inside a sentence:
        [[trend:SERIES_ID]] — show a chart (valid ids are in the labs list below)
        [[habit:Title|when-context]] — propose holding one tiny habit slot
        [[refill:Med name|status detail]] — refill fix card
        [[guide:Question text]] — add a drafted question to their visit guide
        [[action:Title|what you'll do]] — agentic step needing approval
        [[program:Exact program title]] — surface a program card
        Use a tag only when it genuinely helps. Most replies need none.

        WHO \(name.uppercased()) IS
        Pathway: \(persona.switcherLine)
        \(phaseLine)
        Conditions:
        \(conditions)
        Medications:
        \(meds)
        Numbers (chartable):
        \(labs)
        Care plan from \(persona.carePlan.author) (updated \(persona.carePlan.updated)):
        \(plan)
        Upcoming:
        \(appointments)
        Care team office: \(persona.officeName), \(persona.officePhone)
        What you remember about them:
        \(memories)
        Recent symptom logs:
        \(recentLogs.isEmpty ? "none this week" : recentLogs)
        Recent life log (meals, moves, meds):
        \(recentLife)
        Open questions in their visit guide:
        \(guide.isEmpty ? "none yet" : guide)
        Programs available to them:
        \(programLines)
        Steps you've already offered (don't re-offer):
        \(pendingActions.isEmpty ? "none pending" : pendingActions)

        Today is \(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())). Time of day matters — meet them where the day actually is.
        """
    }

    // MARK: - Local fallback brain (offline grace)

    private func streamLocal(reply: String, into index: Int) async {
        let words = reply.split(separator: " ", omittingEmptySubsequences: false)
        turns[index].text = ""
        for (wordIndex, word) in words.enumerated() {
            guard !Task.isCancelled else { return }
            turns[index].text += (wordIndex == 0 ? "" : " ") + word
            try? await Task.sleep(for: .milliseconds(34))
        }
        turns[index].streaming = false
    }

    private func localReply(for text: String) -> String {
        guard let app else { return "I'm right here. Tell me more." }
        let name = app.displayFirstName
        if text.contains("greeting") || text.contains("open the conversation") {
            let hour = Calendar.current.component(.hour, from: .now)
            let opener = hour < 12 ? "Morning" : (hour < 17 ? "Afternoon" : "Evening")
            return "\(opener), \(name). Quiet day on my end — everything synced, nothing waving for attention. What's on your mind?"
        }
        if text.contains("tired") || text.contains("rough") || text.contains("hard") {
            return "That sounds like a heavy one, and I'm not going to pretend a tip fixes it. Nothing needs solving tonight. If you want, tell me the hardest part — sometimes it belongs to the schedule, not to you."
        }
        if text.contains("symptom") {
            return "Let's sit with it for a minute. Tell me when it started and what you were doing — I'll hold it against your meds, your readings, and the week you've had."
        }
        return "Tell me more — I'd rather understand it right than answer it fast."
    }
}

private extension AIChatMessage {
    init(role: String, text: String) {
        self.init(role: role, content: text)
    }
}
