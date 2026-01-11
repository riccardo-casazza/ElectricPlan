import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Load Tom Select from CDN
    if (typeof TomSelect !== 'undefined') {
      new TomSelect(this.element, {
        create: false,
        sortField: {
          field: "text",
          direction: "asc"
        }
      })
    }
  }
}
