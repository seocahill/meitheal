import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actions", "count", "checkbox", "selectAll"]

  connect() {
    this.updateUI()
  }

  toggle() {
    this.updateUI()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateUI()
  }

  updateUI() {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (this.hasActionsTarget) {
      this.actionsTarget.style.display = checkedCount > 0 ? "flex" : "none"
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = `${checkedCount} selected`
    }

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = checkedCount === this.checkboxTargets.length && checkedCount > 0
      this.selectAllTarget.indeterminate = checkedCount > 0 && checkedCount < this.checkboxTargets.length
    }
  }
}
