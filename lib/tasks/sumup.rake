namespace :sumup do
  desc "Compare SumUp's transaction history with our payments, read-only (DAYS=60)"
  task probe: :environment do
    puts SumupProbe.new(days: Integer(ENV.fetch("DAYS", 60))).report
  end

  desc "Store SumUp's transactions for the last DAYS days (default 60), e.g. to backfill"
  task sync: :environment do
    days = Integer(ENV.fetch("DAYS", 60))
    count = SumupTransactionSync.new(days: days).call
    puts "Synced #{ActionController::Base.helpers.pluralize(count, 'SumUp transaction')} from the last #{days} days."
  end
end
