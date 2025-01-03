import { Controller } from "@hotwired/stimulus";
import { useDebounce } from "stimulus-use";

// Connects to data-controller="auto-form"
export default class extends Controller {
    static debounces = ["submitForm"];

    connect() {
        useDebounce(this, { wait: 200 });
    }

    submitForm(e) {
        this.element.requestSubmit();
    }
}