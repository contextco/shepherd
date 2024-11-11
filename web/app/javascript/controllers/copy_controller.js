import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="copy"
export default class extends Controller {
  static values = {
    text: String
  }

  static targets = ['doneIcon', 'pendingIcon']

  connect() {
    if (navigator.clipboard) {
      this.element.classList.remove('hidden');
    }
  }

  copy() {
    navigator.clipboard.writeText(this.content());
    this.doneIconTarget.classList.remove('hidden');
    this.pendingIconTarget.classList.add('hidden');

    setTimeout(() => {
      this.doneIconTarget.classList.add('hidden');
      this.pendingIconTarget.classList.remove('hidden');
    }, 1000);
  }

  content() {
    if (this.hasTextValue) {
      return this.textValue;
    }

    return this.element.textContent;
  }
}
