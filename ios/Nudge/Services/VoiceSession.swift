import AVFoundation
import Observation

nonisolated private struct VoiceScribeResponse: Codable {
    let text: String?
}

/// The hands-free voice conversation loop: the mic opens, silence detection
/// commits the turn, ElevenLabs Scribe transcribes through the private backend,
/// Claude answers, and the backend speaks with the project's custom voice.
@Observable final class VoiceSession {
    enum Phase: Equatable {
        case idle
        case listening
        case transcribing
        case thinking
        case speaking
        case unavailable(String)
    }

    var phase: Phase = .idle
    /// Mic/playback energy 0…1 — drives the listening and speaking glow.
    var level: Double = 0
    var heardText = ""
    var replyText = ""

    private var recorder: AVAudioRecorder?
    private var meterTask: Task<Void, Never>?
    private var processTask: Task<Void, Never>?
    private var player: AVAudioPlayer?
    private var shouldContinue = false
    /// Consecutive empty transcriptions — only after a couple do we surface a
    /// gentle hint, so a moment of quiet never trips a jarring "didn't get it".
    private var consecutiveMisses = 0

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("rumi_voice.m4a")
    }

    /// Starts the hands-free call. Once started, turns auto-commit on silence.
    func start(model: AppModel) {
        guard phase == .idle || isUnavailable else { return }
        shouldContinue = true
        startListening(model: model)
    }

    /// Stops the call from any phase and restores the ambient world.
    func stop(model: AppModel) {
        shouldContinue = false
        meterTask?.cancel()
        processTask?.cancel()
        recorder?.stop()
        recorder = nil
        player?.stop()
        player = nil
        level = 0
        restorePlaybackSession()
        model.orb.set(.ambient)
        phase = .idle
        if SoundEngine.shared.currentBed != nil {
            SoundEngine.shared.playBed(.ambient, fade: 1.4)
        }
    }

    /// Tap is now only start / interrupt / end — never required each turn.
    func toggle(model: AppModel) {
        switch phase {
        case .idle, .unavailable:
            start(model: model)
        case .listening, .transcribing, .thinking, .speaking:
            stop(model: model)
        }
    }

    func teardown(orb: OrbState) {
        shouldContinue = false
        meterTask?.cancel()
        processTask?.cancel()
        recorder?.stop()
        recorder = nil
        player?.stop()
        player = nil
        restorePlaybackSession()
        orb.set(.ambient)
        phase = .idle
    }

    private var isUnavailable: Bool {
        if case .unavailable = phase { return true }
        return false
    }

    // MARK: - Listening

    private func startListening(model: AppModel) {
        heardText = ""
        replyText = ""
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else {
                phase = .unavailable("I'd love to hear you — allow the microphone in Settings and we'll talk.")
                return
            }
            beginRecording(model: model)
        }
    }

    private func beginRecording(model: AppModel) {
        player?.stop()
        player = nil
        SoundEngine.shared.pauseBed(fade: 0.2)

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            ]
            let recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                phase = .unavailable("Voice needs a real microphone — install Rumi on your iPhone via the Rork app to talk out loud.")
                return
            }
            self.recorder = recorder
            phase = .listening
            model.orb.set(.listening)
            Haptics.glass()
            SoundEngine.shared.glass()
            startListeningMeter(model: model)
        } catch {
            print("[Rumi] voice recording unavailable: \(error.localizedDescription)")
            phase = .unavailable("Voice needs a real microphone — install Rumi on your iPhone via the Rork app to talk out loud.")
        }
    }

    /// Lightweight client-side VAD: once speech is detected, a steady quiet
    /// window commits the turn. That gives the hands-free turn-taking behavior
    /// without asking the user to tap at the end of every sentence. Tuned so a
    /// natural mid-sentence pause doesn't cut you off, and a held silence with
    /// no speech at all recycles the mic instead of transcribing noise.
    private func startListeningMeter(model: AppModel) {
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            var heardSpeech = false
            var quietFrames = 0
            let startedAt = Date()
            let earliestCommit = startedAt.addingTimeInterval(1.0)

            while let self, !Task.isCancelled, self.phase == .listening {
                self.recorder?.updateMeters()
                let power = self.recorder?.averagePower(forChannel: 0) ?? -60
                let normalized = pow(10, Double(power) / 20)
                let currentLevel = min(max(normalized * 2.8, 0), 1)
                self.level = currentLevel

                if currentLevel > 0.06 { heardSpeech = true }
                // ~1.1s of quiet after real speech commits the turn.
                if heardSpeech && Date() > earliestCommit && currentLevel < 0.04 {
                    quietFrames += 1
                } else {
                    quietFrames = 0
                }

                if heardSpeech && quietFrames >= 26 {
                    self.finishListening(model: model, heardSpeech: true)
                    return
                }

                // Nobody spoke for ~8s — recycle the mic quietly rather than
                // sending silence to the transcriber.
                if !heardSpeech && Date().timeIntervalSince(startedAt) > 8 {
                    self.finishListening(model: model, heardSpeech: false)
                    return
                }
                try? await Task.sleep(for: .milliseconds(42))
            }
        }
    }

    private func finishListening(model: AppModel, heardSpeech: Bool) {
        guard phase == .listening else { return }
        meterTask?.cancel()
        level = 0
        recorder?.stop()
        recorder = nil

        // Nothing was said — silently re-open the mic, no error, no fuss.
        guard heardSpeech else {
            phase = .idle
            model.orb.set(.ambient)
            if shouldContinue {
                Task { [weak self] in
                    try? await Task.sleep(for: .milliseconds(250))
                    if self?.shouldContinue == true { self?.startListening(model: model) }
                }
            }
            return
        }

        Haptics.pull()
        phase = .transcribing
        model.orb.set(.thinking)

        processTask = Task { [weak self] in
            guard let self else { return }
            let transcript = await self.transcribe()
            guard !Task.isCancelled else { return }

            guard let transcript, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.consecutiveMisses += 1
                self.heardText = ""
                // Only nudge after a couple of genuine misses — otherwise just
                // keep listening so it feels continuous, not broken.
                self.replyText = self.consecutiveMisses >= 2 ? "Still here — take your time, I'm listening." : ""
                model.orb.set(.ambient)
                self.phase = .idle
                if self.shouldContinue {
                    try? await Task.sleep(for: .milliseconds(500))
                    if self.shouldContinue { self.startListening(model: model) }
                }
                return
            }

            self.consecutiveMisses = 0
            self.heardText = transcript
            self.phase = .thinking
            let reply = await model.companion.voiceReply(to: transcript, orb: model.orb)
            guard !Task.isCancelled else { return }
            self.replyText = reply

            await self.speak(reply, model: model)
        }
    }

    // MARK: - ElevenLabs Scribe through backend

    private func transcribe() async -> String? {
        guard let audioData = try? Data(contentsOf: recordingURL), audioData.count > 2_000 else { return nil }
        guard let url = URL(string: "\(AppConfig.functionsURL)/voice/stt") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45

        let boundary = "rumi-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".utf8))
        }
        field("model_id", "scribe_v2")
        field("diarize", "false")
        field("tag_audio_events", "false")
        field("no_verbatim", "true")
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"voice.m4a\"\r\nContent-Type: audio/mp4\r\n\r\n".utf8))
        body.append(audioData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("[Rumi] scribe returned \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            return try JSONDecoder().decode(VoiceScribeResponse.self, from: data).text
        } catch {
            print("[Rumi] scribe failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - ElevenLabs voice through backend

    private func speak(_ text: String, model: AppModel) async {
        guard !text.isEmpty else {
            finishSpeaking(model: model)
            return
        }
        guard let url = URL(string: "\(AppConfig.functionsURL)\(AppConfig.voicePath)") else {
            finishSpeaking(model: model)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "text": text,
            // Turbo v2.5 keeps spoken turns snappy (~250ms) while holding the
            // custom voice — eleven_v3 was richer but too slow for live talk.
            "model_id": "eleven_turbo_v2_5",
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count > 800 else {
                print("[Rumi] tts returned \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                finishSpeaking(model: model)
                return
            }
            let player = try AVAudioPlayer(data: data)
            player.isMeteringEnabled = true
            self.player = player
            SoundEngine.shared.pauseBed(fade: 0.25)
            player.volume = 1
            player.play()
            phase = .speaking
            model.orb.set(.speaking)
            startSpeakingMeter()

            let duration = player.duration
            try? await Task.sleep(for: .seconds(duration + 0.15))
            if phase == .speaking {
                finishSpeaking(model: model)
            }
        } catch {
            print("[Rumi] tts playback failed: \(error.localizedDescription)")
            finishSpeaking(model: model)
        }
    }

    private func startSpeakingMeter() {
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.phase == .speaking {
                self.player?.updateMeters()
                let power = self.player?.averagePower(forChannel: 0) ?? -60
                let normalized = pow(10, Double(power) / 20)
                self.level = min(max(normalized * 2.2, 0), 1)
                try? await Task.sleep(for: .milliseconds(33))
            }
            self?.level = 0
        }
    }

    private func finishSpeaking(model: AppModel) {
        meterTask?.cancel()
        level = 0
        player?.stop()
        player = nil
        phase = .idle
        model.orb.set(.ambient)

        if shouldContinue {
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                if shouldContinue { startListening(model: model) }
            }
        } else if SoundEngine.shared.currentBed != nil {
            restorePlaybackSession()
            SoundEngine.shared.playBed(.ambient, fade: 1.6)
        }
    }

    private func restorePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
