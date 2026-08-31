import { Controller } from "@hotwired/stimulus"

// One-time "ignite" intro animation on cold app launch. Turbo Drive means
// most in-app navigations replace <body> without a real page load, so
// without a guard this would replay on every link click — sessionStorage
// (cleared when the tab/PWA session ends, untouched across Turbo visits
// within it) is exactly the "once per real launch, not once ever" scope
// this needs. The fade-in/ignite/fade-out itself is pure CSS (see the
// splash-* keyframes) — this controller's only job is the once-per-session
// gate and cleanup after, mirroring toast_controller's split of concerns.
export default class extends Controller {
  static values = { key: { type: String, default: "spark:splash-shown" } }

  connect() {
    if (sessionStorage.getItem(this.keyValue)) {
      this.element.remove()
      return
    }
    sessionStorage.setItem(this.keyValue, "1")
    this.timeout = setTimeout(() => this.element.remove(), 2700)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
