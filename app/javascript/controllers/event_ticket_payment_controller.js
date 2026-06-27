import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["buyerName", "buyerEmail", "quantity", "totalDisplay", "buttonTotal", "cardWidget", "loading", "error", "payButton"]
  static values = { price: Number, eventId: Number, capacity: Number }

  connect() {
    this.checkoutId = null
    this.updateTotal()
  }

  updateTotal() {
    const qty = parseInt(this.quantityTarget.value) || 1
    const total = (this.priceValue * qty / 100).toFixed(2)
    this.totalDisplayTarget.textContent = `€${total}`
    this.buttonTotalTarget.textContent = total
  }

  async initiatePayment() {
    const buyerName = this.buyerNameTarget.value.trim()
    const buyerEmail = this.buyerEmailTarget.value.trim()
    const quantity = parseInt(this.quantityTarget.value) || 1

    if (!buyerName || !buyerEmail) {
      this.showError("Please enter your name and email address.")
      return
    }

    if (quantity < 1) {
      this.showError("Quantity must be at least 1.")
      return
    }

    this.setLoading(true)
    this.hideError()

    try {
      const response = await fetch(`/events/${this.eventIdValue}/tickets/create_checkout`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ buyer_name: buyerName, buyer_email: buyerEmail, quantity })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "Failed to create checkout")
      }

      this.checkoutId = data.checkout_id
      this.mountWidget()
    } catch (error) {
      console.error("Ticket payment error:", error)
      this.showError(error.message)
      this.setLoading(false)
    }
  }

  mountWidget() {
    if (typeof SumUpCard === "undefined") {
      this.showError("Payment system not loaded. Please refresh the page.")
      this.setLoading(false)
      return
    }

    this.loadingTarget.classList.add("hidden")

    SumUpCard.mount({
      id: "event-sumup-card",
      checkoutId: this.checkoutId,
      onResponse: (type, body) => {
        this.handleResponse(type, body)
      },
      onLoad: () => {
        this.setLoading(false)
        this.payButtonTarget.classList.add("hidden")
      }
    })
  }

  handleResponse(type, body) {
    switch (type) {
      case "success":
        window.location.href = `/events/${this.eventIdValue}/tickets/complete?checkout_id=${this.checkoutId}`
        break
      case "error":
      case "fail":
        this.showError(body?.message || "Payment failed. Please try again.")
        break
      case "sent":
        this.setLoading(true)
        break
      case "auth-screen":
        break
    }
  }

  setLoading(loading) {
    this.payButtonTarget.disabled = loading
    if (loading) {
      this.payButtonTarget.innerHTML = "Processing..."
      this.loadingTarget.classList.remove("hidden")
    } else {
      this.loadingTarget.classList.add("hidden")
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }
}
