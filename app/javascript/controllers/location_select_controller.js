import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="location-select"
export default class extends Controller {
  static targets = ["country", "region", "department"]

  countryChanged() {
    const countryCode = this.countryTarget.value

    // Clear region and department
    this.regionTarget.innerHTML = '<option value="">Select a region</option>'
    this.departmentTarget.innerHTML = '<option value="">Select a department</option>'

    if (!countryCode) return

    // Fetch regions for the selected country
    fetch(`/locations/regions?country_code=${countryCode}`)
      .then(response => response.json())
      .then(regions => {
        regions.forEach(region => {
          const option = document.createElement('option')
          option.value = region.code
          option.textContent = region.name
          this.regionTarget.appendChild(option)
        })
      })
  }

  regionChanged() {
    const countryCode = this.countryTarget.value
    const regionCode = this.regionTarget.value

    // Clear department
    this.departmentTarget.innerHTML = '<option value="">Select a department</option>'

    if (!countryCode || !regionCode) return

    // Fetch departments for the selected region
    fetch(`/locations/departments?country_code=${countryCode}&region_code=${regionCode}`)
      .then(response => response.json())
      .then(departments => {
        departments.forEach(dept => {
          const option = document.createElement('option')
          option.value = dept.code
          option.textContent = dept.name
          this.departmentTarget.appendChild(option)
        })
      })
  }
}
