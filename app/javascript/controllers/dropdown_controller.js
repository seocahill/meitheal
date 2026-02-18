import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
  }

  toggle() {
    this.menuTarget.classList.toggle("open")
    if (this.menuTarget.classList.contains("open")) {
      document.addEventListener("click", this.closeOnClickOutside)
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.remove("open")
      document.removeEventListener("click", this.closeOnClickOutside)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }
}
