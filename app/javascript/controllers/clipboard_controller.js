import { Controller } from "@hotwired/stimulus"

// Copies the text of the source target. Falls back to selecting it when the
// browser refuses clipboard access, so the link can still be copied by hand.
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    this.sourceTarget.select()
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.flash("Copied")
    } catch {
      this.flash("Press Ctrl+C")
    }
  }

  flash(text) {
    const original = this.buttonTarget.dataset.label || this.buttonTarget.textContent
    this.buttonTarget.dataset.label = original
    this.buttonTarget.textContent = text
    clearTimeout(this.timer)
    this.timer = setTimeout(() => { this.buttonTarget.textContent = original }, 1500)
  }
}
