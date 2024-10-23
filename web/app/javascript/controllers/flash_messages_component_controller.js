import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["flash", "progressBar"];

  connect() {}

  closeFlash() {
    this.flashTarget.classList.add("animate__fadeOutRight");
  }
}
