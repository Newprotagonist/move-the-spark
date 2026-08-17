import { Controller } from "@hotwired/stimulus"

// Live mm:ss elapsed-time display for a running goal timer. The server is
// the source of truth for the actual duration (computed on stop); this is
// purely a visual ticker so the "started" state doesn't look frozen. The
// optional arc target (used only on the full-screen focus view) gets a
// conic-gradient progress ring against totalSecondsValue (the goal's
// average duration, or a default) — a no-op elsewhere since the compact
// row view never declares that target.
export default class extends Controller {
  static targets = [ "display", "arc" ]
  static values = { startedAt: String, totalSeconds: Number }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  tick() {
    const startedAt = new Date(this.startedAtValue).getTime()
    const elapsedSeconds = Math.max(0, Math.floor((Date.now() - startedAt) / 1000))
    const minutes = String(Math.floor(elapsedSeconds / 60)).padStart(2, "0")
    const seconds = String(elapsedSeconds % 60).padStart(2, "0")
    this.displayTarget.textContent = `${minutes}:${seconds}`

    if (this.hasArcTarget && this.totalSecondsValue > 0) {
      const pct = Math.min(100, Math.round((elapsedSeconds / this.totalSecondsValue) * 100))
      this.arcTarget.style.background = `conic-gradient(var(--color-accent) ${pct}%, rgba(255,255,255,.14) 0)`
    }
  }
}
