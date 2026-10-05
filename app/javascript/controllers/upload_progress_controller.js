import { Controller } from "@hotwired/stimulus"

// Shows how far a direct-to-storage upload has got, using the events Active
// Storage fires on the form while it uploads each file.
export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.progress = {}
  }

  start({ detail: { id, file } }) {
    this.progress[id] = { name: file.name, percent: 0 }
    this.render()
  }

  update({ detail: { id, progress } }) {
    this.progress[id].percent = Math.round(progress)
    this.render()
  }

  finish({ detail: { id } }) {
    this.progress[id].percent = 100
    this.render()
  }

  fail(event) {
    event.preventDefault() // replaces Active Storage's default alert
    const { error } = event.detail
    this.statusTarget.hidden = false
    this.statusTarget.textContent = `Upload failed: ${error}. Try again.`
  }

  render() {
    const files = Object.values(this.progress)
    const done = files.every((file) => file.percent === 100)
    this.statusTarget.hidden = false
    this.statusTarget.textContent = done
      ? "Upload finished. Saving…"
      : files.map((file) => `${file.name}: ${file.percent}%`).join(" · ")
  }
}
