import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui--accordion"
export default class extends Controller {

  static targets = ["top", "panel"]

  toggle() {
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden")
    })
  }
}
