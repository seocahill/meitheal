require "test_helper"

class Admin::BankImportsControllerTest < ActionDispatch::IntegrationTest
  HEADER = "Transaction date,Transaction code,Reference,Amount,Available balance\r\n".freeze

  setup do
    @editor = users(:editor)
    @viewer = users(:viewer)
  end

  def upload(*rows, filename: "Transactions_Report.csv")
    text = HEADER + rows.map { |row| "#{row}\r\n" }.join
    Rack::Test::UploadedFile.new(StringIO.new(text), "text/csv", original_filename: filename)
  end

  test "viewers cannot see the page or upload" do
    sign_in_as(@viewer)

    get admin_bank_imports_path
    assert_redirected_to root_path

    post admin_bank_imports_path, params: { file: upload("2025-12-11,C9JGL7Z67G,Somebody,20.00,1724.56") }
    assert_redirected_to root_path
    assert_equal 0, BankTransaction.count
  end

  test "signed out visitors are sent to sign in" do
    get admin_bank_imports_path
    assert_redirected_to new_session_path
  end

  test "the page asks for a first upload when there is none" do
    sign_in_as(@editor)

    get admin_bank_imports_path

    assert_response :success
    assert_select "[data-upload-status]", text: /No bank statement has been uploaded/
    assert_select "[data-upload-due]"
    assert_select "input[type=file][name=file]"
  end

  test "the page shows the last transaction and last upload, and no warning when recent" do
    sign_in_as(@editor)
    post admin_bank_imports_path, params: { file: upload("2025-12-30,COLKEQW2M5,SUMUP PID486934163,98.31,1872.02", "2025-12-22,COEKGW544R,Somebody,49.15,1773.71") }

    get admin_bank_imports_path

    assert_select "[data-last-transaction]", text: /30 Dec 2025/
    assert_select "[data-last-upload]", text: /Transactions_Report\.csv/
    assert_select "[data-upload-due]", count: 0
  end

  test "the page warns that a new upload is due when the last one is over a week old" do
    sign_in_as(@editor)
    post admin_bank_imports_path, params: { file: upload("2025-12-30,COLKEQW2M5,Somebody,98.31,1872.02") }

    travel_to((BankImport::DUE_AFTER + 1.day).from_now) do
      get admin_bank_imports_path
      assert_select "[data-upload-due]", text: /upload/i
    end
  end

  test "uploading stores the transactions and reports how many were new" do
    sign_in_as(@editor)

    assert_difference "BankTransaction.count", 2 do
      post admin_bank_imports_path, params: { file: upload("2025-12-30,COLKEQW2M5,Somebody,98.31,1872.02", "2025-12-22,COEKGW544R,Other,49.15,1773.71") }
    end

    assert_redirected_to admin_bank_imports_path
    assert_match "2 new", flash[:notice]
    assert_equal @editor, BankImport.last.user
  end

  test "uploading an overlapping file says how many were already held" do
    sign_in_as(@editor)
    post admin_bank_imports_path, params: { file: upload("2025-12-30,COLKEQW2M5,Somebody,98.31,1872.02") }

    assert_difference "BankTransaction.count", 1 do
      post admin_bank_imports_path, params: { file: upload("2025-12-30,COLKEQW2M5,Somebody,98.31,1872.02", "2025-12-22,COEKGW544R,Other,49.15,1773.71") }
    end

    assert_match "1 new", flash[:notice]
    assert_match "1 already held", flash[:notice]
  end

  test "uploading without choosing a file asks for one" do
    sign_in_as(@editor)

    post admin_bank_imports_path

    assert_redirected_to admin_bank_imports_path
    assert_match "Choose a", flash[:alert]
  end

  test "a file that is not a SumUp report is refused with the reason" do
    sign_in_as(@editor)
    bad = Rack::Test::UploadedFile.new(StringIO.new("Date,Memo\r\n2025-01-01,Hi\r\n"), "text/csv", original_filename: "other.csv")

    post admin_bank_imports_path, params: { file: bad }

    assert_redirected_to admin_bank_imports_path
    assert_match "Transaction date", flash[:alert]
    assert_equal 0, BankImport.count
  end

  test "a file that is far too large is refused without being read" do
    sign_in_as(@editor)
    big = Rack::Test::UploadedFile.new(StringIO.new(HEADER + ("x" * 3.megabytes)), "text/csv", original_filename: "big.csv")

    post admin_bank_imports_path, params: { file: big }

    assert_redirected_to admin_bank_imports_path
    assert_match "too large", flash[:alert]
    assert_equal 0, BankImport.count
  end

  test "the page lists transactions with whether each has been matched to a payment" do
    sign_in_as(@editor)
    post admin_bank_imports_path, params: { file: upload("2025-12-30,COLKEQW2M5,HALL HIRE IE99ZZZZ00000000000000,98.31,1872.02", "2025-12-22,COEKGW544R,Gas bill,-49.15,1773.71") }

    get admin_bank_imports_path

    assert_includes response.body, "HALL HIRE IE99ZZZZ00000000000000"
    assert_includes response.body, "Gas bill"
    assert_select "[data-matched=false]", minimum: 1
  end
end
