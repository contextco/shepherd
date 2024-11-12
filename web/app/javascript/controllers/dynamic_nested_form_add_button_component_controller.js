import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["dynamic-nested-form-form-component"];

  addSubform(event) {
    this.dynamicNestedFormFormComponentOutlet.addSubform(event);
  }
}
