require "csv"

# One upload of the SumUp Business Account transactions report (CSV), the detailed
# download that includes the payment reference. Uploads overlap, so a transaction
# already held is skipped, matched on the code SumUp gives it.
class BankImport < ApplicationRecord
  REQUIRED_COLUMNS = [
    "Transaction date", "Transaction code", "Transaction type", "Reference", "Payment reference",
    "Billing amount out", "Billing amount in"
  ].freeze
  DUE_AFTER = 7.days

  class InvalidFile < StandardError; end

  belongs_to :user
  has_many :bank_transactions

  validates :filename, presence: true

  # Nothing is stored unless every row in the file is readable.
  def self.from_csv!(text, filename:, user:)
    rows = parse(text)

    transaction do
      import = create!(user: user, filename: filename, rows_read: rows.size, rows_added: 0)
      inserted = BankTransaction.insert_all(rows.map { |row| row.merge(bank_import_id: import.id) }, unique_by: :code)
      import.update!(rows_added: inserted.length)
      import
    end
  end

  def self.last_uploaded_at
    maximum(:created_at)
  end

  # Whether the list of bank transactions may be out of date. Counted from the last
  # upload rather than the last transaction, as a quiet week adds no new transactions.
  def self.upload_due?
    last_uploaded_at.nil? || last_uploaded_at < DUE_AFTER.ago
  end

  def rows_skipped
    rows_read - rows_added
  end

  def self.parse(text)
    text = text.dup.force_encoding(Encoding::UTF_8).delete_prefix("﻿")
    raise InvalidFile, "That file is not UTF-8 text, so it cannot be a SumUp CSV report." unless text.valid_encoding?

    table = CSV.parse(text, headers: true, skip_blanks: true)
    missing = REQUIRED_COLUMNS - table.headers.compact
    raise InvalidFile, "That does not look like a SumUp transactions report. It has no #{missing.to_sentence} column." if missing.any?
    raise InvalidFile, "That report has no transactions in it." if table.empty?

    table.each_with_index.map { |row, index| transaction_attributes(row, number: index + 2) }
  rescue CSV::MalformedCSVError => e
    raise InvalidFile, "That file could not be read as CSV: #{e.message}"
  end
  private_class_method :parse

  # The row number counts the header as row 1, as a spreadsheet would. Money out is
  # stored as a negative amount.
  def self.transaction_attributes(row, number:)
    code = row["Transaction code"].to_s.strip
    raise InvalidFile, "Row #{number} has no transaction code." if code.empty?

    {
      code: code,
      occurred_on: Date.strptime(row["Transaction date"].to_s.strip, "%d/%m/%Y, %H:%M"),
      transaction_type: row["Transaction type"].to_s.squish,
      reference: row["Reference"].to_s.squish,
      payment_reference: row["Payment reference"].to_s.squish,
      amount_cents: ((BigDecimal(row["Billing amount in"].to_s.strip) - BigDecimal(row["Billing amount out"].to_s.strip)) * 100).round
    }
  rescue Date::Error
    raise InvalidFile, "Row #{number} has a date that is not DD/MM/YYYY, HH:MM: #{row['Transaction date'].inspect}."
  rescue ArgumentError
    raise InvalidFile, "Row #{number} has an amount that is not a number: #{row['Billing amount in'].inspect} in, #{row['Billing amount out'].inspect} out."
  end
  private_class_method :transaction_attributes
end
