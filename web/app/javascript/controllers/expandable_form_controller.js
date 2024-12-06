import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "subForm", "addButton", "formField" ]

  showSubForm(event) {
    event.preventDefault()
    this.subFormTarget.classList.remove('hidden')
    this.addButtonTarget.classList.add('hidden')

    // enable form fields
    this.formFieldTargets.forEach((field) => {
      field.removeAttribute("disabled");
    })
  }

  hideSubForm(event) {
    event.preventDefault()
    this.subFormTarget.classList.add('hidden')
    this.addButtonTarget.classList.remove('hidden')

    this.formFieldTargets.forEach((field) => {
      field.setAttribute("disabled", true);
    })
  }
}
