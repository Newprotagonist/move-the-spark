import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Swipe left/right on the day or week view to move to the next/previous
// one — the same navigation the arrow buttons already offer, just
// reachable by gesture too. The element itself is what gets dragged (no
// separate target): translated 1:1 with the finger while dragging, then
// either eased the rest of the way off-screen before navigating (past the
// distance threshold) or snapped back (not past it).
//
// Axis is decided from the first ~10px of movement, not from the very
// first touch event, so an ordinary vertical scroll never gets hijacked —
// only once a gesture is already clearly horizontal do we preventDefault
// and take over from the browser's own scrolling.
export default class extends Controller {
  static values = { previousUrl: String, nextUrl: String }

  static THRESHOLD = 80

  connect() {
    this.axis = null
    this.startX = 0
    this.startY = 0
    this.deltaX = 0
  }

  start(event) {
    this.axis = null
    this.startX = event.touches[0].clientX
    this.startY = event.touches[0].clientY
    this.deltaX = 0
  }

  move(event) {
    if (!this.startX && this.startX !== 0) return

    const x = event.touches[0].clientX
    const y = event.touches[0].clientY
    const dx = x - this.startX
    const dy = y - this.startY

    if (this.axis === null && (Math.abs(dx) > 10 || Math.abs(dy) > 10)) {
      this.axis = Math.abs(dx) > Math.abs(dy) ? "x" : "y"
    }
    if (this.axis !== "x") return

    event.preventDefault()
    this.deltaX = dx
    this.element.style.transform = `translateX(${dx}px)`
  }

  end() {
    if (this.axis !== "x") return

    const goingNext = this.deltaX < 0
    const url = goingNext ? this.nextUrlValue : this.previousUrlValue

    this.element.style.transition = "transform .2s ease-out"
    if (Math.abs(this.deltaX) > this.constructor.THRESHOLD && url) {
      this.element.style.transform = `translateX(${goingNext ? "-120%" : "120%"})`
      setTimeout(() => Turbo.visit(url), 180)
    } else {
      this.element.style.transform = "translateX(0)"
      this.element.addEventListener("transitionend", () => { this.element.style.transition = "" }, { once: true })
    }
  }
}
