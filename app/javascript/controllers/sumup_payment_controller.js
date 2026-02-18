import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardWidget", "loading", "error", "payButton", "donationOption", "customDonation", "donationDisplay", "totalDisplay", "buttonTotal", "typeSelect", "feeDisplay"]
  static values = { prices: Object }

  connect() {
    this.checkoutId = null
    this.donationCents = 0
    this.baseAmountCents = parseInt(this.payButtonTarget.dataset.baseAmount) || 0
    this.updateDisplays()

    // Set "No donation" as active by default
    const noDonationBtn = this.donationOptionTargets.find(btn => btn.dataset.amount === "0")
    if (noDonationBtn) {
      this.setActiveButton(noDonationBtn)
    }
  }

  changeType() {
    const selected = this.typeSelectTarget.selectedOptions[0]
    this.baseAmountCents = parseInt(selected.dataset.price) || 0
    this.payButtonTarget.dataset.baseAmount = this.baseAmountCents
    this.updateDisplays()
  }

  setDonation(event) {
    const amount = parseInt(event.target.dataset.amount) || 0
    this.donationCents = amount
    this.customDonationTarget.value = ""
    this.setActiveButton(event.target)
    this.updateDisplays()
  }

  setCustomDonation(event) {
    const euros = parseFloat(event.target.value) || 0
    this.donationCents = Math.round(euros * 100)
    this.clearActiveButtons()
    this.updateDisplays()
  }

  setActiveButton(activeBtn) {
    this.donationOptionTargets.forEach(btn => {
      btn.classList.remove("border-purple-500", "text-purple-600", "bg-purple-50")
      btn.classList.add("border-gray-300")
    })
    activeBtn.classList.remove("border-gray-300")
    activeBtn.classList.add("border-purple-500", "text-purple-600", "bg-purple-50")
  }

  clearActiveButtons() {
    this.donationOptionTargets.forEach(btn => {
      btn.classList.remove("border-purple-500", "text-purple-600", "bg-purple-50")
      btn.classList.add("border-gray-300")
    })
  }

  updateDisplays() {
    const feeEuros = (this.baseAmountCents / 100).toFixed(2)
    const donationEuros = (this.donationCents / 100).toFixed(2)
    const totalCents = this.baseAmountCents + this.donationCents
    const totalEuros = (totalCents / 100).toFixed(2)

    if (this.hasFeeDisplayTarget) {
      this.feeDisplayTarget.textContent = `€${feeEuros}`
    }
    this.donationDisplayTarget.textContent = `€${donationEuros}`
    this.totalDisplayTarget.textContent = `€${totalEuros}`
    this.buttonTotalTarget.textContent = totalEuros
  }

  async initiatePayment(event) {
    const membershipId = event.target.dataset.membershipId
    const membershipType = this.typeSelectTarget.value
    this.setLoading(true)
    this.hideError()

    try {
      // First create a checkout on our server with donation amount and membership type
      const response = await fetch(`/memberships/${membershipId}/payment/create_checkout`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ donation_cents: this.donationCents, membership_type: membershipType })
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
