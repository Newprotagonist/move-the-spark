import { Controller } from "@hotwired/stimulus"

// Shows only the fields relevant to the selected goal type (one-off vs
// recurring) instead of always showing all four date/frequency fields.
export default class extends Controller {
  static targets = ["oneOffFields", "recurringFields", "recurringRadio"]

  connect() {
    this.toggle()
  }

  toggle() {
    const recurring = this.recurringRadioTarget.checked
    this.oneOffFieldsTarget.classList.toggle("hidden", recurring)
    this.recurringFieldsTarget.classList.toggle("hidden", !recurring)
  }
}
