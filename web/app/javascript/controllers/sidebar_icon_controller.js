import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar-icon"
export default class extends Controller {
  static targets = [ 'tooltip']
  connect() {
    console.log('Connected to sidebar icon controller')
  }

  showTooltip() {
    this.tooltipTarget.classList.remove('hidden')
    this.tooltipTarget.style.opacity = 100;
  }

  hideTooltip() {
    this.tooltipTarget.style.opacity = 0;
    this.tooltipTarget.addEventListener('transitionend', () => {
      this.tooltipTarget.classList.add('hidden')
    });
  }
}
