import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "form"]

  edit(event) {
    event.preventDefault()
    const row = event.target.closest("tr")
    row.classList.add("editing")
  }

  cancel(event) {
    event.preventDefault()
    const row = event.target.closest("tr")
    row.classList.remove("editing")
  }
}
