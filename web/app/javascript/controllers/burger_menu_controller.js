import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "menu", "button" ]

  toggleMenu(event) {
    event.preventDefault()
    if (this.menuTarget.classList.contains('hidden')) {
      this.menuTarget.classList.remove('hidden')

      setTimeout(() => {
        this.menuTarget.classList.remove('opacity-0')
      }, 1)
    }
    else {
      this.closeMenu()
    }
  }

  clickOutside(event) {
    if (!this.hasButtonTarget) return;

    if (!this.menuTarget.contains(event.target) && !this.buttonTarget.contains(event.target)) {
      this.closeMenu()
    }
  }

  closeMenu() {
    this.menuTarget.classList.add('opacity-0')
    setTimeout(() => {
      this.menuTarget.classList.add('hidden')
    }, 300)
  }
}
