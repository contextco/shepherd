import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // controller to add elements dynamically via a template

  static targets = [ "template", "container" ]

  addElement() {
    const content = this.templateTarget.innerHTML;
    this.containerTarget.insertAdjacentHTML('beforeend', content);
  }

  removeElement(event) {
    event.target.closest('.dynamic-element').remove();
  }
}
