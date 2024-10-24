import { Controller } from "@hotwired/stimulus";
import { scrollableParent } from "tools/scrolling";

export default class extends Controller {
  static targets = ["dropdown"];

  static values = {
    align: String,
    expandUp: Boolean,
    matchTriggerWidth: Boolean,
  };

  connect() {
    if (this.hasDropdownTarget) {
      this.dropdown = this.dropdownTarget;
      this.originalParent = this.dropdown.parentElement;
      this.nextSibling = this.dropdown.nextSibling;
    }
    this.parent = scrollableParent(this.element);
    this.dropdown.remove();
    this.parent.appendChild(this.dropdown);
  }

  disconnect() {
    if (this.nextSibling) {
      this.originalParent.insertBefore(this.dropdown, this.nextSibling);
    } else {
      this.originalParent.appendChild(this.dropdown);
    }
  }

  toggle() {
    if (this.dropdown.classList.contains("hidden")) {
      this.show();
    } else {
      this.hide();
    }
  }

  show() {
    this.dropdown.classList.remove("hidden");
    this.reposition();

    if (this.matchTriggerWidthValue) {
      this.dropdown.style.width = `${this.element.clientWidth}px`;
    }
  }

  hide() {
    this.dropdown.classList.add("hidden");
  }

  handleGlobalClick(click) {
    if (
      this.element.contains(click.target) ||
      this.dropdown.contains(click.target)
    ) {
      return;
    }
    this.hide();
  }

  reposition() {
    if (this.dropdown.classList.contains("hidden")) return;

    const controlBox = this.element.getBoundingClientRect();
    const parentBox = this.parent.getBoundingClientRect();

    if (this.expandUpValue) {
      this.dropdown.style.bottom = parentBox.bottom - controlBox.top + "px";
    } else {
      this.dropdown.style.top = controlBox.bottom - parentBox.top + "px";
    }

    if (this.alignValue === "left") {
      this.dropdown.style.left = `${controlBox.x - parentBox.x}px`;
    } else if (this.alignValue === "right") {
      let left = controlBox.left - parentBox.left;
      left = left + controlBox.width - this.dropdown.clientWidth;
      this.dropdown.style.left = left + "px";
    }
  }
}
