require "csv"

# Builds the SumUp Business Account "Transactions report" CSV in the layout SumUp downloads,
# so tests upload the same shape of file the app receives.
module BankReportTestHelper
  BANK_REPORT_HEADER = [
    "Transaction date", "Transaction code", "Transaction type", "Reference", "Payment reference", "Status",
    "Billing amount out", "Billing amount in", "Card currency", "Transaction amount out", "Transaction amount in",
    "Transaction currency", "Exchange rate", "Fee", "Available balance"
  ].freeze

  def bank_report_row(code: "C9JGL7Z67G", date: "11/12/2025, 18:01", type: "Incoming bank transfer", reference: "Somebody",
                      payment_reference: "", money_out: "0.00", money_in: "20.00")
    status = type == "SumUp pay-in" ? "Pay-in" : "Approved"
    [ date, code, type, reference, payment_reference, status, money_out, money_in, "EUR", money_out, money_in, "EUR", "1.00", "0.00", "1724.56" ]
  end

  def bank_report(*rows)
    CSV.generate(row_sep: "\r\n") do |csv|
      csv << BANK_REPORT_HEADER
      rows.each { |row| csv << row }
    end
  end
end
