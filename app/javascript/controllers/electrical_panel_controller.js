import { Controller } from "@hotwired/stimulus"

// Auto-fills the floor when a room is selected
export default class extends Controller {
  static targets = ["roomSelect", "floorDisplay"]

  updateFloor(event) {
    const selectedOption = this.roomSelectTarget.options[this.roomSelectTarget.selectedIndex]
    const floorName = selectedOption.dataset.floor

    if (floorName) {
      this.floorDisplayTarget.textContent = floorName
    } else {
      this.floorDisplayTarget.textContent = "N/A"
    }
  }
}
