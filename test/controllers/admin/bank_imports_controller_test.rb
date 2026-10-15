require "test_helper"

class Admin::BankImportsControllerTest < ActionDispatch::IntegrationTest
  include BankReportTestHelper

  setup do
    @editor = users(:editor)
    @viewer = users(:viewer)
  end

  def upload(*rows, filename: "Transactions_Report.csv")
    Rack::Test::UploadedFile.new(StringIO.new(bank_report(*rows)), "text/csv", original_filename: filename)
  end

  test "viewers cannot see the page or upload" do
    sign_in_as(@viewer)

    get admin_bank_imports_path
    assert_redirected_to root_path

    post admin_bank_imports_path, params: { file: upload(bank_report_row(code: "C9JGL7Z67G")) }
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
    post admin_bank_imports_path, params: { file: upload(bank_report_row(code: "COLKEQW2M5", date: "30/12/2025, 05:13", type: "SumUp pay-in", reference: "SUMUP PID486934163", money_in: "98.31"), bank_report_row(code: "COEKGW544R", date: "22/12/2025, 05:13", money_in: "49.15")) }

    get admin_bank_imports_path

    assert_select "[data-last-transaction]", text: /30 Dec 2025/
    assert_select "[data-last-upload]", text: /Transactions_Report\.csv/
    assert_select "[data-upload-due]", count: 0
  end

  test "the page warns that a new upload is due when the last one is over a week old" do
    sign_in_as(@editor)
    post admin_bank_imports_path, params: { file: upload(bank_report_row(code: "COLKEQW2M5", date: "30/12/2025, 05:13", money_in: "98.31")) }

    travel_to((BankImport::DUE_AFTER + 1.day).from_now) do
      get admin_bank_imports_path
      assert_select "[data-upload-due]", text: /upload/i
    end
  end

  test "uploading stores the transactions and reports how many were new" do
    sign_in_as(@editor)

    assert_difference "BankTransaction.count", 2 do
      post admin_bank_imports_path, params: { file: upload(bank_report_row(code: "COLKEQW2M5", date: "30/12/2025, 05:13", money_in: "98.31"), bank_report_row(code: "COEKGW544R", date: "22/12/2025, 05:13", reference: "Other", money_in: "49.15")) }
    end

    assert_redirected_to admin_bank_imports_path
    assert_match "2 new", flash[:notice]
    assert_equal @editor, BankImport.last.user
  end

  test "uploading an overlapping file says how many were already held" do
    sign_in_as(@editor)
    post admin_bank_imports_path, params: { file: upload(bank_report_row(code: "COLKEQW2M5", date: "30/12/2025, 05:13", money_in: "98.31")) }

    assert_difference "BankTransaction.count", 1 do
      post admin_bank_imports_path, params: { file: upload(bank_report_row(code: "COLKEQW2M5", date: "30/12/2025, 05:13", money_in: "98.31"), bank_report_row(code: "COEKGW544R", date: "22/12/2025, 05:13", reference: "Other", money_in: "49.15")) }
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
    big = Rack::Test::UploadedFile.new(StringIO.new(bank_report + ("x" * 3.megabytes)), "text/csv", original_filename: "big.csv")

    post admin_bank_imports_path, params: { file: big }

    assert_redirected_to admin_bank_imports_path
    assert_match "too large", flash[:alert]
    assert_equal 0, BankImport.count
  end

  def hold(*rows)
    post admin_bank_imports_path, params: { file: upload(*rows) }
  end

  def filter_fixture_rows
    [
      bank_report_row(code: "FLANAGAN", date: "11/12/2025, 18:01", reference: "JONATHAN FLANAGAN IE42IPBS", payment_reference: "Unity Elec", money_in: "20.00"),
      bank_report_row(code: "COUNCIL", date: "28/11/2025, 06:19", reference: "MAYO COUNTY COUNCIL IE98AIBK", money_in: "849.00"),
      bank_report_row(code: "GASBILL", date: "09/11/2025, 23:07", type: "Direct debit", reference: "SSEAirtricity IE35BOFI", money_out: "83.25", money_in: "0.00"),
      bank_report_row(code: "PAYOUT1", date: "21/11/2025, 05:27", type: "SumUp pay-in", reference: "SUMUP PID458018620", money_in: "29.49")
    ]
  end

  test "search finds transactions by reference or by what the payer wrote" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)

    get admin_bank_imports_path(search: "flanagan")
    assert_includes response.body, "JONATHAN FLANAGAN"
    assert_not_includes response.body, "MAYO COUNTY COUNCIL"

    get admin_bank_imports_path(search: "unity")
    assert_includes response.body, "JONATHAN FLANAGAN"
    assert_not_includes response.body, "SSEAirtricity"
  end

  test "the type filter lists the types held and narrows the page to one" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)

    get admin_bank_imports_path(type: "Direct debit")

    assert_select "select[name=type] option", text: "Direct debit"
    assert_select "select[name=type] option", text: "SumUp pay-in"
    assert_select "select[name=type] option[selected]", text: "Direct debit"
    assert_includes response.body, "SSEAirtricity"
    assert_not_includes response.body, "MAYO COUNTY COUNCIL"
  end

  test "the money filter shows only money in or only money out" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)

    get admin_bank_imports_path(direction: "out")
    assert_includes response.body, "SSEAirtricity"
    assert_not_includes response.body, "MAYO COUNTY COUNCIL"

    get admin_bank_imports_path(direction: "in")
    assert_includes response.body, "MAYO COUNTY COUNCIL"
    assert_not_includes response.body, "SSEAirtricity"
  end

  test "the matched filter shows transactions matched to a payment or not" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)
    payment = memberships(:active_membership).payments.create!(
      amount_cents: 2000, paid_on: Date.current, payment_method: :bank_transfer,
      user_email: "a@example.com", user_name: "A", description: "Fee"
    )
    BankTransaction.find_by!(code: "FLANAGAN").update!(payment: payment)

    get admin_bank_imports_path(matched: "matched")
    assert_includes response.body, "JONATHAN FLANAGAN"
    assert_not_includes response.body, "MAYO COUNTY COUNCIL"

    get admin_bank_imports_path(matched: "unmatched")
    assert_not_includes response.body, "JONATHAN FLANAGAN"
    assert_includes response.body, "MAYO COUNTY COUNCIL"
  end

  test "the date filter narrows the page to a period" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)

    get admin_bank_imports_path(from: "2025-11-25", to: "2025-12-31")

    assert_includes response.body, "JONATHAN FLANAGAN"
    assert_includes response.body, "MAYO COUNTY COUNCIL"
    assert_not_includes response.body, "SSEAirtricity"
    assert_not_includes response.body, "SUMUP PID458018620"
  end

  test "filters combine" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)

    get admin_bank_imports_path(direction: "in", from: "2025-11-25", search: "council")

    assert_includes response.body, "MAYO COUNTY COUNCIL"
    assert_not_includes response.body, "JONATHAN FLANAGAN"
    assert_not_includes response.body, "SSEAirtricity"
  end

  test "an unknown money or matched value is ignored rather than hiding everything" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)

    get admin_bank_imports_path(direction: "sideways", matched: "maybe")

    assert_includes response.body, "MAYO COUNTY COUNCIL"
    assert_includes response.body, "SSEAirtricity"
  end

  test "the page says when no transaction matches the filters and offers to clear them" do
    sign_in_as(@editor)
    hold(*filter_fixture_rows)

    get admin_bank_imports_path(search: "nobody at all")

    assert_select "td", text: /No bank transactions match/
    assert_select "a[href=?]", admin_bank_imports_path, text: "Clear"
  end

  test "the page offers no clear link and the first-upload message when nothing is filtered" do
    sign_in_as(@editor)

    get admin_bank_imports_path

    assert_select "td", text: /No bank transactions yet/
    assert_select "a", text: "Clear", count: 0
  end

  test "moving to another page keeps the filters" do
    sign_in_as(@editor)
    hold(*(1..25).map { |n| bank_report_row(code: "COUNCIL#{n}", reference: "MAYO COUNTY COUNCIL", money_in: "10.00") })

    get admin_bank_imports_path(search: "council")

    assert_select "a[href*='page=2'][href*='search=council']"
  end

  test "the page lists transactions with whether each has been matched to a payment" do
    sign_in_as(@editor)
    post admin_bank_imports_path, params: { file: upload(bank_report_row(code: "COLKEQW2M5", date: "30/12/2025, 05:13", reference: "HALL HIRE IE99ZZZZ00000000000000", payment_reference: "Front room Saturday", money_in: "98.31"), bank_report_row(code: "COEKGW544R", date: "22/12/2025, 05:13", type: "Direct debit", reference: "Gas bill", money_out: "49.15", money_in: "0.00")) }

    get admin_bank_imports_path

    assert_includes response.body, "HALL HIRE IE99ZZZZ00000000000000"
    assert_includes response.body, "Gas bill"
    assert_includes response.body, "Front room Saturday"
    assert_select "[data-matched=false]", minimum: 1
  end
end
