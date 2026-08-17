import { Controller } from "@hotwired/stimulus"

// A toast self-removes shortly after appearing (the fade/rise is pure CSS —
// see the rise-fade keyframe — this just cleans up the DOM node after).
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.element.remove(), 1600)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
