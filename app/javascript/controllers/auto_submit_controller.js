import { Controller } from "@hotwired/stimulus"

// Generic helper: submit the enclosing form as soon as one of its fields
// changes (used for the shopping list item checkbox, so ticking it off
// doesn't require a separate save click).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
