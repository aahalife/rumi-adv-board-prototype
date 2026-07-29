import AVFoundation

/// The score — composed like film music, mixed like a whisper.
///
/// Three layers:
/// 1. **Tap notes** — five recordings of a small girl singing "ta" at different
///    chords. Taps walk a gentle pentatonic-style pattern, so ordinary use of
///    the app composes an endless little melody. Never twice within 90ms.
/// 2. **Music beds** — "Barley Thunder" carries onboarding; "Stone Kintsugi"
///    carries the rest of the world. Beds crossfade into each other, loop
///    seamlessly, and duck out entirely when muted.
/// 3. **Moments** — whoosh and bloom, reserved for meaning.
///
/// The audio session uses the `.playback` category (mixing with others) so
/// the score stays audible even when the device's silent switch is on.
final class SoundEngine {
    static let shared = SoundEngine()

    /// Micro-sound master toggle, mirrored from Settings.
    var enabled = true
    /// Music bed toggle — the one-tap mute the user owns.
    private(set) var musicEnabled = true

    enum Bed: String {
        case onboarding = "music_barley_thunder"
        case ambient = "music_stone_kintsugi"

        var fileExtension: String { "m4a" }
        var volume: Float {
            switch self {
            case .onboarding: return 0.42
            case .ambient: return 0.30
            }
        }
    }

    // MARK: Private state

    /// Pool of players per note so rapid taps overlap instead of cutting.
    private var notePools: [[AVAudioPlayer]] = []
    private var poolCursor: [Int] = []
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private var recapPlayer: AVAudioPlayer?

    private var bedA: AVAudioPlayer?
    private var bedB: AVAudioPlayer?
    private var activeIsA = true
    private(set) var currentBed: Bed?

    private var lastNoteAt: TimeInterval = 0
    /// Walks a gentle musical phrase: up, breathe, resolve.
    private let phrase = [0, 2, 4, 2, 3, 1, 4, 0, 2, 3]
    private var phraseIndex = 0
    private var fadeTimers: [ObjectIdentifier: Timer] = [:]

    private init() {
        // `.playback` so the score is heard even with the silent switch on —
        // `.ambient` muted the entire experience on real devices.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        preloadNotes()
    }

    private func preloadNotes() {
        for index in 1...5 {
            guard let url = Bundle.main.url(forResource: "tap_ta_\(index)", withExtension: "mp3") else {
                notePools.append([])
                poolCursor.append(0)
                continue
            }
            var pool: [AVAudioPlayer] = []
            for _ in 0..<2 {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    pool.append(player)
                }
            }
            notePools.append(pool)
            poolCursor.append(0)
        }
    }

    // MARK: - Tap notes — the app as an instrument

    /// Featherweight acknowledgment — kept intentionally silent. The vocal
    /// "ta" is reserved for meaningful moments (opening the companion, logging,
    /// sending, keeping a habit, approvals) so it never feels random on every
    /// incidental tap. Haptics still fire at these call sites.
    func tick() { }

    /// Soft rounded press — orb touches, opening surfaces. A real moment.
    func glass() { playNote(volume: 0.22) }

    /// Sending a thought into the world — slightly brighter.
    func send() { playNote(volume: 0.3, jumpPhrase: true) }

    private func playNote(volume: Float, jumpPhrase: Bool = false) {
        guard enabled, !notePools.isEmpty else { return }
        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastNoteAt > 0.09 else { return }
        lastNoteAt = now

        if jumpPhrase { phraseIndex = (phraseIndex + 3) % phrase.count }
        let note = phrase[phraseIndex % phrase.count]
        phraseIndex = (phraseIndex + 1) % phrase.count

        let pool = notePools[min(note, notePools.count - 1)]
        guard !pool.isEmpty else { return }
        let cursor = poolCursor[note] % pool.count
        poolCursor[note] += 1
        let player = pool[cursor]
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    // MARK: - Moment sounds

    func whoosh() { playSFX("sfx_whoosh", volume: 0.3) }
    func bloom() { playSFX("sfx_bloom", volume: 0.45) }

    private func playSFX(_ name: String, volume: Float) {
        guard enabled else { return }
        if let player = sfxPlayers[name] {
            player.volume = volume
            player.currentTime = 0
            player.play()
            return
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return }
        player.volume = volume
        player.prepareToPlay()
        sfxPlayers[name] = player
        player.play()
    }

    // MARK: - Music beds with crossfade

    /// Starts (or crossfades to) a bed. Safe to call repeatedly.
    func playBed(_ bed: Bed, fade fadeDuration: TimeInterval = 2.4) {
        guard musicEnabled else { currentBed = bed; return }
        if currentBed == bed, (activePlayer?.isPlaying ?? false) { return }
        currentBed = bed

        guard let url = Bundle.main.url(forResource: bed.rawValue, withExtension: bed.fileExtension),
              let incoming = try? AVAudioPlayer(contentsOf: url)
        else { return }
        incoming.numberOfLoops = -1
        incoming.volume = 0
        incoming.prepareToPlay()
        incoming.play()

        let outgoing = activePlayer
        if activeIsA { bedB = incoming } else { bedA = incoming }
        activeIsA.toggle()

        fade(incoming, to: bed.volume, over: fadeDuration)
        if let outgoing {
            fade(outgoing, to: 0, over: fadeDuration * 0.8) { outgoing.stop() }
        }
    }

    /// Fades the current bed to silence without forgetting which bed it was.
    func pauseBed(fade fadeDuration: TimeInterval = 1.2) {
        guard let player = activePlayer, player.isPlaying else { return }
        fade(player, to: 0, over: fadeDuration) { player.pause() }
    }

    func stopBed(fade fadeDuration: TimeInterval = 1.2) {
        currentBed = nil
        guard let player = activePlayer else { return }
        fade(player, to: 0, over: fadeDuration) { player.stop() }
    }

    /// The one-tap music mute. Remembers the bed and resumes it on unmute.
    func setMusicEnabled(_ on: Bool) {
        musicEnabled = on
        if on {
            if let bed = currentBed { playBed(bed, fade: 1.6) }
        } else if let player = activePlayer, player.isPlaying {
            fade(player, to: 0, over: 0.8) { player.pause() }
        }
    }

    private var activePlayer: AVAudioPlayer? { activeIsA ? bedA : bedB }

    // MARK: - Recap score (the one place the score leads)

    func startRecap() {
        guard enabled else { return }
        pauseBed()
        if recapPlayer == nil {
            guard let url = Bundle.main.url(forResource: "music_recap", withExtension: "mp3"),
                  let player = try? AVAudioPlayer(contentsOf: url)
            else { return }
            recapPlayer = player
        }
        recapPlayer?.volume = 0
        recapPlayer?.currentTime = 0
        recapPlayer?.play()
        fade(recapPlayer, to: 0.6, over: 1.6)
    }

    func stopRecap() {
        if let player = recapPlayer, player.isPlaying {
            fade(player, to: 0, over: 1.0) { player.stop() }
        }
        if musicEnabled, let bed = currentBed {
            playBed(bed, fade: 2.0)
        }
    }

    // MARK: - Equal-power-ish fade

    private func fade(_ player: AVAudioPlayer?, to target: Float, over duration: TimeInterval,
                      completion: (() -> Void)? = nil) {
        guard let player else { return }
        let key = ObjectIdentifier(player)
        fadeTimers[key]?.invalidate()
        let start = player.volume
        let startTime = Date()
        fadeTimers[key] = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { timer in
            let progress = min(Date().timeIntervalSince(startTime) / duration, 1)
            let eased = Float(progress * progress * (3 - 2 * progress))
            Task { @MainActor in
                player.volume = start + (target - start) * eased
                if progress >= 1 {
                    timer.invalidate()
                    completion?()
                }
            }
        }
    }
}
