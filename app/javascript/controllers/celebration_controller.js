import { Controller } from "@hotwired/stimulus"

// The full-screen "day complete" celebration triggered by completing the
// last remaining daily goal of the day (see
// GoalsController#celebrate_day_complete?). Backdrop click or the button
// dismiss it; a click inside the card must not bubble to the backdrop's
// close action.
export default class extends Controller {
  close() {
    this.element.remove()
  }

  stop(event) {
    event.stopPropagation()
  }
}
