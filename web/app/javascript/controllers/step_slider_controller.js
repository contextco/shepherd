import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="step-slider"
export default class extends Controller {
  static targets = ["input", "hiddenField"]

  static values = {
    options: Array,
    disabledOptions: Array
  }

  connect() {
    this.setupSlider()
    this.updateOutput()
  }

  setupSlider() {
    const slider = this.inputTarget
    slider.setAttribute("min", 0)
    slider.setAttribute("max", this.optionsValue.length - 1)
    slider.setAttribute("step", 1)
    slider.value = this.optionsValue.findIndex((value) => value == this.hiddenFieldTarget.value)
  }

  updateOutput() {
    this.hiddenFieldTarget.value = this.optionsValue[this.inputTarget.value]
  }

  slide(e) {
    if (this.disabledOptionsValue.includes(this.optionsValue[this.inputTarget.value])) {
      this.inputTarget.value = this.optionsValue.findLastIndex((value) => !this.disabledOptionsValue.includes(value))
      return;
    }

    this.updateOutput()
  }
}
