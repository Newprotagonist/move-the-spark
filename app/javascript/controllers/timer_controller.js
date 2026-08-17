import { Controller } from "@hotwired/stimulus"

// Live mm:ss elapsed-time display for a running goal timer. The server is
// the source of truth for the actual duration (computed on stop); this is
// purely a visual ticker so the "started" state doesn't look frozen.
export default class extends Controller {
  static targets = ["display"]
  static values = { startedAt: String }

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
  }
}
