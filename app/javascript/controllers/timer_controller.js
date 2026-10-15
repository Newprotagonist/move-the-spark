import { Controller } from "@hotwired/stimulus"

// Live mm:ss elapsed-time display for a running goal timer. The server is
// the source of truth for the actual duration (computed on stop); this is
// purely a visual ticker so the "started" state doesn't look frozen. The
// optional arc target (used only on the old compact display) and the
// optional hearthScene/fireStage/fireHint/tick targets (used on the
// full-screen Focus view) are all no-ops when their targets aren't
// declared, so the compact row usage (display only) is unaffected by them.
const FOCUS_STAGES = [
  { t: 0, name: "Braise", hint: "la chaleur monte doucement" },
  { t: 0.14, name: "Étincelle", hint: "ça prend" },
  { t: 0.34, name: "Flammèche", hint: "le feu tient tout seul" },
  { t: 0.62, name: "Ardeur", hint: "plein régime, ne lâche pas" },
  { t: 0.88, name: "Brasier", hint: "tu peux t'arrêter quand tu veux" },
]

export default class extends Controller {
  static targets = [ "display", "arc", "hearthScene", "fireStage", "fireHint", "tick" ]
  static values = { startedAt: String, totalSeconds: Number, paused: Boolean, pausedAt: String }

  connect() {
    this.tick()
    if (!this.pausedValue) this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  tick() {
    const startedAt = new Date(this.startedAtValue).getTime()
    const now = this.pausedValue ? new Date(this.pausedAtValue).getTime() : Date.now()
    const elapsedSeconds = Math.max(0, Math.floor((now - startedAt) / 1000))
    const minutes = String(Math.floor(elapsedSeconds / 60)).padStart(2, "0")
    const seconds = String(elapsedSeconds % 60).padStart(2, "0")
    this.displayTarget.textContent = `${minutes}:${seconds}`

    if (this.hasArcTarget && this.totalSecondsValue > 0) {
      const pct = Math.min(100, Math.round((elapsedSeconds / this.totalSecondsValue) * 100))
      this.arcTarget.style.background = `conic-gradient(var(--color-accent) ${pct}%, rgba(255,255,255,.14) 0)`
    }

    if (this.hasHearthSceneTarget && this.totalSecondsValue > 0) this.updateFire(elapsedSeconds)
  }

  updateFire(elapsedSeconds) {
    const g = Math.min(1, elapsedSeconds / this.totalSecondsValue)
    const stage = FOCUS_STAGES.filter((s) => g >= s.t).pop() || FOCUS_STAGES[0]
    const stageIndex = FOCUS_STAGES.indexOf(stage)

    this.hearthSceneTargets.forEach((el, i) => { el.style.opacity = i === stageIndex ? "1" : "0" })
    if (this.hasFireStageTarget) this.fireStageTarget.textContent = stage.name
    if (this.hasFireHintTarget) this.fireHintTarget.textContent = stage.hint
    if (this.hasTickTarget) {
      this.tickTargets.forEach((el, i) => el.classList.toggle("bg-accent", i <= stageIndex))
    }
  }
}
