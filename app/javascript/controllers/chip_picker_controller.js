import { Controller } from "@hotwired/stimulus"

// Generic quick-pick chip row: tapping a chip sets a target input's value
// and highlights that chip among its siblings. The underlying input stays
// fully present and editable — chips are a fast shortcut, not the only way
// to set the value (e.g. an appointment can still be any date, not just
// "today/tomorrow").
export default class extends Controller {
  static targets = ["input", "chip"]

  pick(event) {
    this.inputTarget.value = event.currentTarget.dataset.chipValue
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.refresh()
  }

  refresh() {
    this.chipTargets.forEach((chip) => {
      const active = chip.dataset.chipValue === this.inputTarget.value
      chip.classList.toggle("bg-ink", active)
      chip.classList.toggle("text-paper", active)
      chip.classList.toggle("bg-paper", !active)
      chip.classList.toggle("text-ink", !active)
      chip.classList.toggle("border-line", !active)
    })
  }

  connect() {
    this.refresh()
  }
}
