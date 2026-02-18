class Admin::TransactionsController < ApplicationController
  before_action :require_owner

  def index
    filters = {}
    filters[:oldest_time] = params[:from] || 30.days.ago.iso8601
    filters[:newest_time] = params[:to] || Date.today.iso8601
    filters[:limit] = 50

    service = SumupCheckoutService.new
    response = service.list_transactions(filters)
    all_transactions = response["items"] || []

    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1

    # Simple text search across key fields
    query = params[:q].to_s.strip
    if query.present?
      downcased = query.downcase
      all_transactions = all_transactions.select do |txn|
        [
          txn["transaction_code"],
          txn["status"],
          txn["type"],
          txn["payment_type"],
          txn["product_summary"]
        ].compact.any? { |value| value.to_s.downcase.include?(downcased) }
      end
    end

    per_page = 10
    offset = (@page - 1) * per_page
    page_items = all_transactions.slice(offset, per_page) || []

    @transactions = page_items
    @has_more = offset + per_page < all_transactions.size

    transaction_ids = @transactions.map { |txn| txn["id"] }.compact
    @payments_by_transaction_id =
      if transaction_ids.any?
        Payment.includes(membership: :user)
               .where(sumup_transaction_id: transaction_ids)
               .index_by(&:sumup_transaction_id)
      else
        {}
      end
  rescue SumupCheckoutService::CheckoutError => e
    @transactions = []
    flash.now[:alert] = "Could not load transactions: #{e.message}"
  rescue StandardError => e
    @transactions = []
    Rails.logger.error("SumUp transaction fetch failed: #{e.message}")
    flash.now[:alert] = "Could not connect to SumUp. Check your API credentials."
  end
end
