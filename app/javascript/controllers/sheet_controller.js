import { Controller } from "@hotwired/stimulus"

// The persistent bottom-sheet frame (goal/appointment/settings forms). The
// slide-up entrance is pure CSS (plays automatically whenever the card
// renders, whether via a direct page visit or a Turbo Frame swap). This
// controller's only job is closing without a server round-trip: tapping the
// backdrop or "FERMER" just empties the frame client-side.
export default class extends Controller {
  close() {
    this.element.innerHTML = ""
    this.element.removeAttribute("src")
  }
}
