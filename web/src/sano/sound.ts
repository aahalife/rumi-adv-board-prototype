/** Sano sound — Stone Kintsugi carries the world, Barley Thunder owns onboarding.
 *  Tap tones ("ta" at various chords) make every touch a small note. */

type Bed = "ambient" | "onboarding";

class SoundEngineImpl {
  enabled = true;
  musicEnabled = true;
  currentBed: Bed | null = null;
  private bedEl: HTMLAudioElement | null = null;
  private sfxCache = new Map<string, HTMLAudioElement>();
  private taps: HTMLAudioElement[] = [];
  private tapIndex = 0;
  private unlocked = false;

  private bedSrc(bed: Bed): string {
    return bed === "onboarding" ? "/audio/music_barley_thunder.m4a" : "/audio/music_stone_kintsugi.m4a";
  }

  /** Browsers block autoplay until a gesture — call on first interaction. */
  unlock() {
    if (this.unlocked) return;
    this.unlocked = true;
    if (this.currentBed && this.musicEnabled) this.playBed(this.currentBed, 2.4);
  }

  playBed(bed: Bed, fade = 1.6) {
    this.currentBed = bed;
    if (!this.musicEnabled) return;
    if (!this.bedEl) {
      this.bedEl = new Audio();
      this.bedEl.loop = true;
      this.bedEl.volume = 0;
    }
    const src = this.bedSrc(bed);
    if (!this.bedEl.src.endsWith(src)) this.bedEl.src = src;
    const target = bed === "onboarding" ? 0.5 : 0.34;
    this.bedEl.play().then(() => this.fadeTo(target, fade)).catch(() => {});
  }

  pauseBed(fade = 0.6) {
    if (!this.bedEl) return;
    this.fadeTo(0, fade, () => this.bedEl?.pause());
  }

  setMusicEnabled(on: boolean) {
    this.musicEnabled = on;
    if (!on) this.pauseBed(0.5);
    else if (this.currentBed) this.playBed(this.currentBed, 1.5);
  }

  private fadeTo(target: number, seconds: number, done?: () => void) {
    const el = this.bedEl;
    if (!el) return;
    const start = el.volume;
    const steps = Math.max(1, Math.floor(seconds * 30));
    let i = 0;
    const tick = () => {
      i++;
      const p = i / steps;
      el.volume = Math.max(0, Math.min(1, start + (target - start) * p));
      if (i < steps) requestAnimationFrame(tick);
      else done?.();
    };
    tick();
  }

  private sfx(name: string, volume = 0.6) {
    if (!this.enabled) return;
    let el = this.sfxCache.get(name);
    if (!el) {
      el = new Audio(`/audio/${name}.mp3`);
      this.sfxCache.set(name, el);
    }
    el.volume = volume;
    el.currentTime = 0;
    el.play().catch(() => {});
  }

  /** Endless-music tap tone — cycles through the five "ta" chords. */
  tone() {
    if (!this.enabled) return;
    if (this.taps.length === 0) {
      for (let n = 1; n <= 5; n++) this.taps.push(new Audio(`/audio/tap_ta_${n}.mp3`));
    }
    const el = this.taps[this.tapIndex % this.taps.length];
    this.tapIndex++;
    el.volume = 0.5;
    el.currentTime = 0;
    el.play().catch(() => {});
  }

  glass() { this.sfx("sfx_glass", 0.5); }
  /** Reserved silent — the vocal "ta" is kept for meaningful moments only
   *  (opening the companion, logging, sending, keeping a habit, approvals). */
  tick() { /* intentionally quiet */ }
  bloom() { this.sfx("sfx_bloom", 0.6); }
  whoosh() { this.sfx("sfx_whoosh", 0.5); }
  send() { this.tone(); }
}

export const SoundEngine = new SoundEngineImpl();

/** Light haptic on supported devices (web fallback for the iOS Haptics). */
export const Haptics = {
  tick: () => navigator.vibrate?.(6),
  glass: () => navigator.vibrate?.(8),
  pull: () => navigator.vibrate?.([4, 30, 8]),
  success: () => navigator.vibrate?.(14),
  bloom: () => navigator.vibrate?.([10, 24, 16]),
};
