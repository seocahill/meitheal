namespace :sumup do
  desc "Compare SumUp's transaction history with our payments, read-only (DAYS=60)"
  task probe: :environment do
    puts SumupProbe.new(days: Integer(ENV.fetch("DAYS", 60))).report
  end
end
