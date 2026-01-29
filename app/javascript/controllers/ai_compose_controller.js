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

  useEmail(event) {
    const subject = event.currentTarget.dataset.emailSubject
    const body = event.currentTarget.dataset.emailBody
    const from = event.currentTarget.dataset.emailFrom
    const newsletterId = event.currentTarget.dataset.newsletterId

    // Find the main AI compose form on the page
    const mainComposer = document.querySelector('[data-controller="ai-compose"] textarea[data-ai-compose-target="prompt"]')
    if (mainComposer) {
      const prompt = `Transform this email into newsletter content:\n\nFrom: ${from}\nSubject: ${subject}\n\n${body || '(no body)'}\n\nMake it suitable for a community newsletter - engaging, clear, and well-formatted.`
      mainComposer.value = prompt
      mainComposer.focus()
      mainComposer.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
  }

  setLoading(loading) {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = loading
    }
    if (this.hasStatusTarget) {
      this.statusTarget.classList.toggle("hidden", !loading)
    }
  }
}
