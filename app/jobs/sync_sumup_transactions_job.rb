# Each run re-reads a window wider than the schedule so a missed run is
# caught up and later changes, such as refunds, are picked up.
class SyncSumupTransactionsJob < ApplicationJob
  queue_as :default

  LOOKBACK_DAYS = 14

  def perform
    SumupTransactionSync.new(days: LOOKBACK_DAYS).call
  end
end
