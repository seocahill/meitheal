import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "button", "status", "result", "output"]

  async compose(event) {
    const prompt = this.promptTarget.value.trim()
    if (!prompt) {
      alert("Please enter a prompt")
      return
    }

    const newsletterId = event.target.dataset.newsletterId
    this.setLoading(true)

    try {
      const response = await fetch(`/newsletters/${newsletterId}/compose_with_ai`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ prompt })
      })

      const data = await response.json()

      if (response.ok) {
        this.outputTarget.innerHTML = data.content
        this.resultTarget.classList.remove("hidden")
      } else {
        alert(data.error || "Failed to generate content")
      }
    } catch (error) {
      console.error("AI composition error:", error)
      alert("Failed to connect to AI service")
    } finally {
      this.setLoading(false)
    }
  }

  useSuggestion(event) {
    this.promptTarget.value = event.target.dataset.prompt
    this.promptTarget.focus()
  }

  setLoading(loading) {
    this.buttonTarget.disabled = loading
    this.statusTarget.classList.toggle("hidden", !loading)
  }
}
