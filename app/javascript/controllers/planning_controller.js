import { Controller } from "@hotwired/stimulus"

// "Planning mode": tapping a goal's clock icon lets you tap an hour in the
// ribbon to assign it there. Entirely client-side until a slot is actually
// picked — only then does it hit the server (a single reused hidden form,
// since the target action URL depends on which goal is being placed).
//
// Dragging an already-placed ribbon card to a different half-hour slot is a
// second, independent way to reach the same server action — for adjusting
// an existing time rather than placing a brand new one.
export default class extends Controller {
  static targets = [ "placeholder", "cancelBar", "cancelLabel", "form", "hourField", "minuteField", "slot" ]
  static values = { activeGoalId: Number }

  start(event) {
    this.activeGoalIdValue = event.params.goalId
    this.cancelLabelTarget.textContent = `Touche un créneau pour « ${event.params.goalTitle} »`
    this.cancelBarTarget.classList.remove("hidden")
    this.placeholderTargets.forEach((el) => el.classList.remove("hidden"))
  }

  cancel() {
    this.activeGoalIdValue = 0
    this.cancelBarTarget.classList.add("hidden")
    this.placeholderTargets.forEach((el) => el.classList.add("hidden"))
  }

  pickHour(event) {
    if (!this.activeGoalIdValue) return

    this.place(this.activeGoalIdValue, event.params.hour, event.params.minute)
    this.cancel()
  }

  // The card itself is moved directly (not a clone), translated to follow
  // the finger; the target slot is found by hit-testing slotTargets'
  // bounding rects against the pointer's Y position rather than a fixed
  // row height, since slot heights vary with how many goals/appointments
  // they already hold.
  //
  // This relies on pointer events, not touchstart/move/end, so it doesn't
  // need to coordinate with swipe-nav's touch listeners on an ancestor
  // element: swipe-nav only ever acts once a gesture's first ~10px resolve
  // to the horizontal axis, so a vertical drag here is already a no-op for
  // it by construction.
  dragStart(event) {
    event.preventDefault()

    this.draggingGoalId = event.params.goalId
    this.draggingCard = event.target.closest("[data-ribbon-goal-card]")
    this.dragStartY = event.clientY
    this.hoveredSlot = null

    this.draggingCard.style.position = "relative"
    this.draggingCard.style.zIndex = "10"
    this.draggingCard.classList.add("shadow-lg")

    this.boundDragMove = this.dragMove.bind(this)
    this.boundDragEnd = this.dragEnd.bind(this)
    window.addEventListener("pointermove", this.boundDragMove)
    window.addEventListener("pointerup", this.boundDragEnd)
  }

  dragMove(event) {
    const dy = event.clientY - this.dragStartY
    this.draggingCard.style.transform = `translateY(${dy}px)`

    const slot = this.slotTargets.find((el) => {
      const rect = el.getBoundingClientRect()
      return event.clientY >= rect.top && event.clientY < rect.bottom
    })

    if (slot !== this.hoveredSlot) {
      if (this.hoveredSlot) this.hoveredSlot.classList.remove("bg-accent-soft")
      if (slot) slot.classList.add("bg-accent-soft")
      this.hoveredSlot = slot
    }
  }

  dragEnd() {
    window.removeEventListener("pointermove", this.boundDragMove)
    window.removeEventListener("pointerup", this.boundDragEnd)

    this.draggingCard.style.transform = ""
    this.draggingCard.style.position = ""
    this.draggingCard.style.zIndex = ""
    this.draggingCard.classList.remove("shadow-lg")

    if (this.hoveredSlot) {
      this.hoveredSlot.classList.remove("bg-accent-soft")
      this.place(this.draggingGoalId, this.hoveredSlot.dataset.planningHourParam, this.hoveredSlot.dataset.planningMinuteParam)
    }

    this.draggingCard = null
    this.hoveredSlot = null
  }

  place(goalId, hour, minute) {
    this.formTarget.action = `/goals/${goalId}/schedule`
    this.hourFieldTarget.value = hour
    this.minuteFieldTarget.value = minute
    this.formTarget.requestSubmit()
  }
}
