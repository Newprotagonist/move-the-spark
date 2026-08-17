import { Controller } from "@hotwired/stimulus"

// Clears and refocuses a field after a successful Turbo Stream submission —
// used on the "add item" form so adding several shopping list items in a
// row doesn't require re-tapping the field each time.
export default class extends Controller {
  static targets = ["field"]

  connect() {
    this.element.addEventListener("turbo:submit-end", this.reset)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.reset)
  }

  reset = (event) => {
    if (!event.detail.success) return

    this.fieldTarget.value = ""
    this.fieldTarget.focus()
  }
}
