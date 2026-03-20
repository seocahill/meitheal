import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardWidget", "loading", "error", "payButton", "amountInput", "purposeInput", "descriptionInput", "totalDisplay", "buttonTotal"]

  connect() {
    this.checkoutId = null
  }

  updateTotal() {
    const euros = parseFloat(this.amountInputTarget.value) || 0
    const formatted = euros.toFixed(2)
    this.totalDisplayTarget.textContent = `€${formatted}`
    this.buttonTotalTarget.textContent = formatted
  }

  async initiatePayment() {
    const amountEuro = parseFloat(this.amountInputTarget.value) || 0
    const purpose = this.purposeInputTarget.value
    const description = this.descriptionInputTarget.value.trim()

    if (amountEuro <= 0) {
      this.showError("Please enter an amount greater than zero")
      return
    }

    if (!purpose) {
      this.showError("Please select a purpose for this payment")
      return
    }

    if (!description) {
      this.showError("Please enter a description for this payment")
      return
    }

    this.setLoading(true)
    this.hideError()

    try {
      const response = await fetch("/payment/create_checkout", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          amount_euro: amountEuro,
          purpose: purpose,
          description: description
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "Failed to create checkout")
      }

      this.checkoutId = data.checkout_id

      // Mount the SumUp card widget
      this.mountWidget()
    } catch (error) {
      console.error("Payment initialization error:", error)
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

    // Clear loading message
    this.loadingTarget.classList.add("hidden")

    SumUpCard.mount({
      id: "sumup-card",
      checkoutId: this.checkoutId,
      onResponse: (type, body) => {
        console.log("SumUp response:", type, body)
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
        // Redirect to completion endpoint
        window.location.href = `/payment/complete?checkout_id=${this.checkoutId}`
        break
      case "error":
      case "fail":
        this.showError(body?.message || "Payment failed. Please try again.")
        break
      case "sent":
        // Payment is being processed
        this.setLoading(true)
        break
      case "auth-screen":
        // 3D Secure authentication shown
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
