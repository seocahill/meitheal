require "test_helper"

class BankImportTest < ActiveSupport::TestCase
  include BankReportTestHelper

  setup do
    @user = users(:editor)
  end

  def import(text, filename: "report.csv")
    BankImport.from_csv!(text, filename: filename, user: @user)
  end

  test "stores each row as a bank transaction" do
    result = import(bank_report(
      bank_report_row(code: "C9JGL7Z67G", date: "11/12/2025, 18:01", type: "Incoming bank transfer",
                      reference: "JONATHAN FLANAGAN IE42IPBS99073031587381", payment_reference: "UNITY ELEC", money_in: "20.00"),
      bank_report_row(code: "C9WYNXQ2MG", date: "09/11/2025, 23:07", type: "Direct debit",
                      reference: "SSEAirtricity IE35BOFI90102829724029", money_out: "83.25", money_in: "0.00")
    ))

    assert_equal "report.csv", result.filename
    assert_equal @user, result.user
    assert_equal 2, result.rows_read
    assert_equal 2, result.rows_added

    incoming = BankTransaction.find_by!(code: "C9JGL7Z67G")
    assert_equal Date.new(2025, 12, 11), incoming.occurred_on
    assert_equal "JONATHAN FLANAGAN IE42IPBS99073031587381", incoming.reference
    assert_equal 2000, incoming.amount_cents
    assert_equal "UNITY ELEC", incoming.payment_reference
    assert_equal "Incoming bank transfer", incoming.transaction_type
    assert_equal result, incoming.bank_import

    direct_debit = BankTransaction.find_by!(code: "C9WYNXQ2MG")
    assert_equal(-8325, direct_debit.amount_cents)
    assert_equal "Direct debit", direct_debit.transaction_type
    assert_equal "", direct_debit.payment_reference
  end

  test "dates are day first and the time of day is ignored" do
    import(bank_report(
      bank_report_row(code: "EARLY", date: "03/10/2026, 00:53"),
      bank_report_row(code: "LATE", date: "12/01/2026, 23:00")
    ))

    assert_equal Date.new(2026, 10, 3), BankTransaction.find_by!(code: "EARLY").occurred_on
    assert_equal Date.new(2026, 1, 12), BankTransaction.find_by!(code: "LATE").occurred_on
  end

  test "extra spaces in a reference are tidied" do
    import(bank_report(bank_report_row(code: "CO374JV6EJ", reference: "RONAN           QUINN IE72BOFI90527219914339")))

    assert_equal "RONAN QUINN IE72BOFI90527219914339", BankTransaction.find_by!(code: "CO374JV6EJ").reference
  end

  test "extra spaces in a payment reference are tidied" do
    import(bank_report(bank_report_row(
      code: "CDR63W7Q2J", payment_reference: "Paul Recording 30 euro             JF Punk Acoustic night 40 euro     "
    )))

    assert_equal "Paul Recording 30 euro JF Punk Acoustic night 40 euro", BankTransaction.find_by!(code: "CDR63W7Q2J").payment_reference
  end

  test "references with commas and quotes survive" do
    import(bank_report(bank_report_row(code: "CDLNM76BZP", type: "POS payment", reference: "SumUp  *Imprint, Ballina IE",
                                       payment_reference: 'Said "thanks", twice', money_out: "20.00", money_in: "0.00")))

    assert_equal "SumUp *Imprint, Ballina IE", BankTransaction.find_by!(code: "CDLNM76BZP").reference
    assert_equal 'Said "thanks", twice', BankTransaction.find_by!(code: "CDLNM76BZP").payment_reference
  end

  test "amounts keep their cents exactly" do
    import(bank_report(
      bank_report_row(code: "C97EGP55J5", money_in: "157.30"),
      bank_report_row(code: "CD2ZM7VYZR", money_out: "29.43", money_in: "0.00")
    ))

    assert_equal 15730, BankTransaction.find_by!(code: "C97EGP55J5").amount_cents
    assert_equal(-2943, BankTransaction.find_by!(code: "CD2ZM7VYZR").amount_cents)
  end

  test "a file that starts with a byte order mark is read" do
    import("﻿" + bank_report(bank_report_row(code: "C9JGL7Z67G")))

    assert BankTransaction.exists?(code: "C9JGL7Z67G")
  end

  test "uploading the same file again adds nothing and says so" do
    text = bank_report(bank_report_row(code: "C9JGL7Z67G"), bank_report_row(code: "CDEK4WER43", money_in: "19.66"))
    import(text)

    assert_no_difference "BankTransaction.count" do
      again = import(text)
      assert_equal 2, again.rows_read
      assert_equal 0, again.rows_added
    end
  end

  test "an overlapping file adds only the transactions not already held" do
    import(bank_report(bank_report_row(code: "CDEK4WER43", money_in: "19.66")))

    result = import(bank_report(bank_report_row(code: "C9JGL7Z67G"), bank_report_row(code: "CDEK4WER43", money_in: "19.66")))

    assert_equal 2, result.rows_read
    assert_equal 1, result.rows_added
    assert_equal 2, BankTransaction.where(code: %w[C9JGL7Z67G CDEK4WER43]).count
  end

  test "a transaction code repeated inside one file is stored once" do
    result = import(bank_report(bank_report_row(code: "C9JGL7Z67G"), bank_report_row(code: "C9JGL7Z67G")))

    assert_equal 2, result.rows_read
    assert_equal 1, result.rows_added
  end

  test "a transaction that has been matched to a payment is left alone by a re-upload" do
    import(bank_report(bank_report_row(code: "C9JGL7Z67G")))
    payment = memberships(:active_membership).payments.create!(
      amount_cents: 2000, paid_on: Date.current, payment_method: :bank_transfer,
      user_email: "a@example.com", user_name: "A", description: "Fee"
    )
    BankTransaction.find_by!(code: "C9JGL7Z67G").update!(payment: payment)

    import(bank_report(bank_report_row(code: "C9JGL7Z67G")))

    assert_equal payment, BankTransaction.find_by!(code: "C9JGL7Z67G").payment
  end

  test "the simpler statement layout without the payment reference is refused" do
    simple = "Transaction date,Transaction code,Reference,Amount,Available balance\r\n2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56\r\n"

    error = assert_raises(BankImport::InvalidFile) { import(simple) }

    assert_match "Transaction type", error.message
    assert_equal 0, BankTransaction.count
  end

  test "a date that is not day/month/year refuses the file" do
    error = assert_raises(BankImport::InvalidFile) { import(bank_report(bank_report_row(date: "2025-12-11"))) }

    assert_match "Row 2", error.message
    assert_match "DD/MM/YYYY", error.message
  end

  test "a file without the SumUp report columns is refused" do
    error = assert_raises(BankImport::InvalidFile) { import("Date,Memo,Amount\r\n2025-01-01,Hello,1.00\r\n") }

    assert_match "Transaction date", error.message
    assert_equal 0, BankTransaction.count
    assert_equal 0, BankImport.count
  end

  test "an empty file is refused" do
    assert_raises(BankImport::InvalidFile) { import("") }
    assert_equal 0, BankImport.count
  end

  test "a file with no transactions is refused" do
    error = assert_raises(BankImport::InvalidFile) { import(bank_report) }

    assert_match(/no transactions/i, error.message)
  end

  test "one bad row refuses the whole file and names the row" do
    error = assert_raises(BankImport::InvalidFile) do
      import(bank_report(bank_report_row(code: "C9JGL7Z67G"), bank_report_row(code: "CDEK4WER43", date: "not-a-date")))
    end

    assert_match "Row 3", error.message
    assert_equal 0, BankTransaction.count
    assert_equal 0, BankImport.count
  end

  test "a row with an amount that is not a number refuses the file" do
    error = assert_raises(BankImport::InvalidFile) { import(bank_report(bank_report_row(money_in: "twenty"))) }

    assert_match "Row 2", error.message
  end

  test "a row without a transaction code refuses the file" do
    error = assert_raises(BankImport::InvalidFile) { import(bank_report(bank_report_row(code: ""))) }

    assert_match "Row 2", error.message
  end

  test "malformed CSV is refused with a message" do
    assert_raises(BankImport::InvalidFile) { import(bank_report + "11/12/2025,\"C9JGL7Z67G,Somebody,20.00,1\r\n") }
  end

  test "upload_due? is true when nothing has been uploaded" do
    assert BankImport.upload_due?
  end

  test "upload_due? is false just after an upload even when it added nothing" do
    text = bank_report(bank_report_row(code: "C9JGL7Z67G"))
    import(text)
    import(text)

    assert_not BankImport.upload_due?
  end

  test "upload_due? is true once the last upload is older than a week" do
    import(bank_report(bank_report_row(code: "C9JGL7Z67G")))

    travel_to((BankImport::DUE_AFTER + 1.hour).from_now) do
      assert BankImport.upload_due?
    end
    travel_to((BankImport::DUE_AFTER - 1.hour).from_now) do
      assert_not BankImport.upload_due?
    end
  end

  test "last_uploaded_at is when the newest upload was made" do
    assert_nil BankImport.last_uploaded_at
    import(bank_report(bank_report_row(code: "C9JGL7Z67G")))

    assert_in_delta Time.current, BankImport.last_uploaded_at, 5.seconds
  end
end
