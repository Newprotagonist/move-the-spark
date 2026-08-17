import { Controller } from "@hotwired/stimulus"

// "Planning mode": tapping a goal's clock icon lets you tap an hour in the
// ribbon to assign it there. Entirely client-side until a slot is actually
// picked — only then does it hit the server (a single reused hidden form,
// since the target action URL depends on which goal is being placed).
export default class extends Controller {
  static targets = [ "placeholder", "cancelBar", "cancelLabel", "form", "hourField" ]
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

    this.formTarget.action = `/goals/${this.activeGoalIdValue}/schedule`
    this.hourFieldTarget.value = event.params.hour
    this.formTarget.requestSubmit()
    this.cancel()
  }
}
