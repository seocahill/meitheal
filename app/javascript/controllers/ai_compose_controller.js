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

  async importEmail(event) {
    const button = event.currentTarget
    const newsletterId = button.dataset.newsletterId
    const messageId = button.dataset.messageId
    const folderId = button.dataset.folderId

    // Disable button and show loading state
    const originalText = button.innerHTML
    button.disabled = true
    button.innerHTML = '<span class="animate-pulse">Importing...</span>'

    try {
      const response = await fetch(`/newsletters/${newsletterId}/import_email`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ message_id: messageId, folder_id: folderId })
      })

      const data = await response.json()

      if (response.ok) {
        // Find the Lexxy editor and append content
        const lexxEditor = document.querySelector('lexxy-editor')
        if (lexxEditor && lexxEditor.contents) {
          // Focus the editor first
          lexxEditor.focus()
          // Insert a line break then the content at the end
          lexxEditor.contents.insertHtml('<br><br>' + data.content)

          // Mark as imported
          button.innerHTML = '<span class="text-green-600">✓ Imported</span>'
          button.classList.add('opacity-50')

          // Show success message with save reminder
          this.showFlash('Email content added - remember to save!')
        } else {
          console.error('Lexxy editor not found')
          alert('Could not find editor - please copy content manually')
          // Show the content in output area as fallback
          if (this.hasOutputTarget) {
            this.outputTarget.innerHTML = data.content
            this.resultTarget.classList.remove("hidden")
          }
          button.innerHTML = originalText
          button.disabled = false
        }
      } else {
        alert(data.error || "Failed to import email")
        button.innerHTML = originalText
        button.disabled = false
      }
    } catch (error) {
      console.error("Email import error:", error)
      alert("Failed to import email")
      button.innerHTML = originalText
      button.disabled = false
    }
  }

  useSuggestion(event) {
    this.promptTarget.value = event.target.dataset.prompt
    this.promptTarget.focus()
  }

  setLoading(loading) {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = loading
    }
    if (this.hasStatusTarget) {
      this.statusTarget.classList.toggle("hidden", !loading)
    }
  }

  showFlash(message) {
    // Create a temporary flash message
    const flash = document.createElement('div')
    flash.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 transition-opacity'
    flash.textContent = message
    document.body.appendChild(flash)

    setTimeout(() => {
      flash.style.opacity = '0'
      setTimeout(() => flash.remove(), 300)
    }, 3000)
  }
}
