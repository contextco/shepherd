import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    indexPlaceholderString: String,
    maximumSubforms: Number,
    minimumSubforms: Number,
    subformsCount: Number,
  };

  static targets = ["subformTemplate", "subformsWrapper"];

  connect() {
    this.replaceIndexInSubform(this.subformsWrapperTarget);
  }

  replaceIndexInSubform(subform) {
    const newId = Math.floor(Math.random() * 1000000000);
    subform.querySelectorAll("[name]").forEach((element) => {
      this.replaceIndex(element, "name", newId);
    });
    subform.querySelectorAll("[for]").forEach((element) => {
      this.replaceIndex(element, "for", newId);
    });
    subform.querySelectorAll("[id]").forEach((element) => {
      this.replaceIndex(element, "id", newId);
    });
  }

  replaceIndex(element, attribute, newId) {
    element.setAttribute(
      attribute,
      element
        .getAttribute(attribute)
        .replace(this.indexPlaceholderStringValue, newId),
    );
  }

  addSubform(event) {
    event.preventDefault();
    this.addEmptySubform();
  }

  addEmptySubform() {
    if (this.subformsCountValue >= this.maximumSubformsValue) {
      return;
    }

    const newSubform = this.subformTemplateTarget.content.cloneNode(true);
    this.replaceIndexInSubform(newSubform);
    this.subformsWrapperTarget.appendChild(newSubform);

    const elementToFocus =
      this.subformsWrapperTarget.lastElementChild.querySelector(
        "[dynamicNestedFormAutofocus]",
      );
    if (elementToFocus) {
      elementToFocus.focus();
    }
    this.subformsCountValue++;

    this.dispatch("subform-added", {
      prefix: false,
    });

    return this.subformsWrapperTarget.lastElementChild;
  }

  addSubFormWithPresets(presets) {
    const newSubform = this.addEmptySubform();
    Object.entries(presets).forEach(([key, value]) => {
      newSubform.querySelector(`.${key}`).value = value;
    });
  }

  removeSubform(event) {
    event.preventDefault();
    if (this.subformsCountValue <= this.minimumSubformsValue) {
      return;
    }

    event.target.closest(".subform-component").remove();
    this.subformsCountValue--;

    this.dispatch("subform-removed", {
      prefix: false,
    });
  }

  // Needed because morphing doesn't yet work for <template> elements:
  // https://github.com/hotwired/turbo/issues/1087
  handleTemplateMorph(event) {
    const oldElement = event.target;
    const newElement = event.detail.newElement;
    oldElement.content.replaceChildren(...newElement.content.children);
  }

  canAddSubform() {
    return this.subformsCountValue < this.maximumSubformsValue;
  }
}
