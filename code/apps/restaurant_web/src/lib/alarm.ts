/**
 * Yangi buyurtma ovozli signali — Web Audio (oscillator), asset shart emas.
 * Qabul/rad bosilguncha takrorlanadi.
 */
export class Alarm {
  private ctx: AudioContext | null = null;
  private timer: ReturnType<typeof setInterval> | null = null;
  private playing = false;

  get isPlaying() {
    return this.playing;
  }

  start() {
    if (this.playing) return;
    this.playing = true;
    this.ensureCtx();
    this.ring();
    this.timer = setInterval(() => this.ring(), 1600);
  }

  stop() {
    this.playing = false;
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  private ensureCtx() {
    if (typeof window === 'undefined') return;
    if (!this.ctx) {
      const AC =
        window.AudioContext ||
        (window as unknown as { webkitAudioContext: typeof AudioContext })
          .webkitAudioContext;
      this.ctx = new AC();
    }
    // Avtoplay siyosati: foydalanuvchi imo-ishorasidan keyin tiklanadi.
    if (this.ctx.state === 'suspended') void this.ctx.resume();
  }

  /** Uchta qisqa "beep" (telefon jiringi kabi). */
  private ring() {
    const ctx = this.ctx;
    if (!ctx) return;
    const now = ctx.currentTime;
    for (let i = 0; i < 3; i++) {
      const t = now + i * 0.25;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = 880;
      gain.gain.setValueAtTime(0, t);
      gain.gain.linearRampToValueAtTime(0.25, t + 0.02);
      gain.gain.linearRampToValueAtTime(0, t + 0.18);
      osc.connect(gain).connect(ctx.destination);
      osc.start(t);
      osc.stop(t + 0.2);
    }
  }
}
