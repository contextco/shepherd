import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "spinner", "result"]
  static values = {
    loading: Boolean
  }

  connect() {
    this.spinnerTarget.classList.add("hidden")
  }

  startLoading() {
    this.resultTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("hidden")
  }

  stopLoading() {
    this.spinnerTarget.classList.add("hidden")
  }
}
