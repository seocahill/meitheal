require "test_helper"

class BankImportTest < ActiveSupport::TestCase
  HEADER = "Transaction date,Transaction code,Reference,Amount,Available balance\r\n".freeze

  setup do
    @user = users(:editor)
  end

  def csv(*rows)
    HEADER + rows.map { |row| "#{row}\r\n" }.join
  end

  def import(text, filename: "report.csv")
    BankImport.from_csv!(text, filename: filename, user: @user)
  end

  test "stores each row as a bank transaction" do
    result = import(csv(
      "2025-12-11,C9JGL7Z67G,JONATHAN FLANAGAN IE42IPBS99073031587381,20.00,1724.56",
      "2025-11-09,C9WYNXQ2MG,SSEAirtricity IE35BOFI90102829724029,-83.25,767.09"
    ))

    assert_equal "report.csv", result.filename
    assert_equal @user, result.user
    assert_equal 2, result.rows_read
    assert_equal 2, result.rows_added

    incoming = BankTransaction.find_by!(code: "C9JGL7Z67G")
    assert_equal Date.new(2025, 12, 11), incoming.occurred_on
    assert_equal "JONATHAN FLANAGAN IE42IPBS99073031587381", incoming.reference
    assert_equal 2000, incoming.amount_cents
    assert_equal result, incoming.bank_import
    assert_equal(-8325, BankTransaction.find_by!(code: "C9WYNXQ2MG").amount_cents)
  end

  test "extra spaces in a reference are tidied" do
    import(csv("2025-10-21,CO374JV6EJ,RONAN           QUINN IE72BOFI90527219914339,90.00,1410.34"))

    assert_equal "RONAN QUINN IE72BOFI90527219914339", BankTransaction.find_by!(code: "CO374JV6EJ").reference
  end

  test "references with commas and quotes survive" do
    import(csv('2025-09-12,CDLNM76BZP,"SumUp  *Imprint, Ballina IE",-20.00,2182.55'))

    assert_equal "SumUp *Imprint, Ballina IE", BankTransaction.find_by!(code: "CDLNM76BZP").reference
  end

  test "amounts keep their cents exactly" do
    import(csv("2025-01-09,C97EGP55J5,PID 910064,157.30,2123.58", "2025-05-09,CD2ZM7VYZR,Gas,-29.43,1136.88"))

    assert_equal 15730, BankTransaction.find_by!(code: "C97EGP55J5").amount_cents
    assert_equal(-2943, BankTransaction.find_by!(code: "CD2ZM7VYZR").amount_cents)
  end

  test "a file that starts with a byte order mark is read" do
    import("﻿" + csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56"))

    assert BankTransaction.exists?(code: "C9JGL7Z67G")
  end

  test "uploading the same file again adds nothing and says so" do
    text = csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56", "2025-12-10,CDEK4WER43,Other,19.66,1665.24")
    import(text)

    assert_no_difference "BankTransaction.count" do
      again = import(text)
      assert_equal 2, again.rows_read
      assert_equal 0, again.rows_added
    end
  end

  test "an overlapping file adds only the transactions not already held" do
    import(csv("2025-12-10,CDEK4WER43,Other,19.66,1665.24"))

    result = import(csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56", "2025-12-10,CDEK4WER43,Other,19.66,1665.24"))

    assert_equal 2, result.rows_read
    assert_equal 1, result.rows_added
    assert_equal 2, BankTransaction.where(code: %w[C9JGL7Z67G CDEK4WER43]).count
  end

  test "a transaction code repeated inside one file is stored once" do
    result = import(csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56", "2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56"))

    assert_equal 2, result.rows_read
    assert_equal 1, result.rows_added
  end

  test "a transaction that has been matched to a payment is left alone by a re-upload" do
    import(csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56"))
    payment = memberships(:active_membership).payments.create!(
      amount_cents: 2000, paid_on: Date.current, payment_method: :bank_transfer,
      user_email: "a@example.com", user_name: "A", description: "Fee"
    )
    BankTransaction.find_by!(code: "C9JGL7Z67G").update!(payment: payment)

    import(csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56"))

    assert_equal payment, BankTransaction.find_by!(code: "C9JGL7Z67G").payment
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
    error = assert_raises(BankImport::InvalidFile) { import(HEADER) }

    assert_match(/no transactions/i, error.message)
  end

  test "one bad row refuses the whole file and names the row" do
    error = assert_raises(BankImport::InvalidFile) do
      import(csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56", "not-a-date,CDEK4WER43,Other,19.66,1665.24"))
    end

    assert_match "Row 3", error.message
    assert_equal 0, BankTransaction.count
    assert_equal 0, BankImport.count
  end

  test "a row with an amount that is not a number refuses the file" do
    error = assert_raises(BankImport::InvalidFile) { import(csv("2025-12-11,C9JGL7Z67G,Somebody,twenty,1724.56")) }

    assert_match "Row 2", error.message
  end

  test "a row without a transaction code refuses the file" do
    error = assert_raises(BankImport::InvalidFile) { import(csv("2025-12-11,,Somebody,20.00,1724.56")) }

    assert_match "Row 2", error.message
  end

  test "malformed CSV is refused with a message" do
    assert_raises(BankImport::InvalidFile) { import(HEADER + "2025-12-11,\"C9JGL7Z67G,Somebody,20.00,1\r\n") }
  end

  test "upload_due? is true when nothing has been uploaded" do
    assert BankImport.upload_due?
  end

  test "upload_due? is false just after an upload even when it added nothing" do
    text = csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56")
    import(text)
    import(text)

    assert_not BankImport.upload_due?
  end

  test "upload_due? is true once the last upload is older than a week" do
    import(csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56"))

    travel_to((BankImport::DUE_AFTER + 1.hour).from_now) do
      assert BankImport.upload_due?
    end
    travel_to((BankImport::DUE_AFTER - 1.hour).from_now) do
      assert_not BankImport.upload_due?
    end
  end

  test "last_uploaded_at is when the newest upload was made" do
    assert_nil BankImport.last_uploaded_at
    import(csv("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56"))

    assert_in_delta Time.current, BankImport.last_uploaded_at, 5.seconds
  end
end
