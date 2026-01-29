import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardWidget", "loading", "error", "payButton"]

  connect() {
    this.checkoutId = null
  }

  async initiatePayment(event) {
    const membershipId = event.target.dataset.membershipId
    this.setLoading(true)
    this.hideError()

    try {
      // First create a checkout on our server
      const response = await fetch(`/memberships/${membershipId}/payment/create_checkout`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "Failed to create checkout")
      }

      this.checkoutId = data.checkout_id

      // Mount the SumUp card widget
      this.mountWidget(membershipId)
    } catch (error) {
      console.error("Payment initialization error:", error)
      this.showError(error.message)
      this.setLoading(false)
    }
  }

  mountWidget(membershipId) {
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
        this.handleResponse(type, body, membershipId)
      },
      onLoad: () => {
        this.setLoading(false)
        this.payButtonTarget.classList.add("hidden")
      }
    })
  }

  handleResponse(type, body, membershipId) {
    switch (type) {
      case "success":
        // Redirect to completion endpoint
        window.location.href = `/memberships/${membershipId}/payment/complete?checkout_id=${this.checkoutId}`
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
      this.payButtonTarget.textContent = "Processing..."
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
