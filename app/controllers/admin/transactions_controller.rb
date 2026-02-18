class Admin::TransactionsController < ApplicationController
  before_action :require_owner

  def index
    filters = {}
    filters[:oldest_time] = params[:from] if params[:from].present?
    filters[:newest_time] = params[:to] if params[:to].present?
    filters[:limit] = 50

    service = SumupCheckoutService.new
    response = service.list_transactions(filters)
    @transactions = response["items"] || []
  rescue SumupCheckoutService::CheckoutError => e
    @transactions = []
    flash.now[:alert] = "Could not load transactions: #{e.message}"
  rescue StandardError => e
    @transactions = []
    Rails.logger.error("SumUp transaction fetch failed: #{e.message}")
    flash.now[:alert] = "Could not connect to SumUp. Check your API credentials."
  end
end
