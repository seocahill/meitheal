# Uploads of the SumUp Business Account transactions report, which is the bank statement.
class Admin::BankImportsController < Admin::BaseController
  include Pagy::Method

  MAX_FILE_SIZE = 2.megabytes

  before_action :require_editor

  def index
    @imports = BankImport.includes(:user).order(created_at: :desc, id: :desc).limit(5)
    @pagy, @transactions = pagy(BankTransaction.order(occurred_on: :desc, id: :desc), limit: 20)
  end

  def create
    file = params[:file]
    return back_with(alert: "Choose a SumUp transactions report (CSV) to upload.") unless file.respond_to?(:read)
    return back_with(alert: "That file is too large for a bank statement.") if file.size > MAX_FILE_SIZE

    import = BankImport.from_csv!(file.read, filename: file.original_filename, user: Current.user)
    back_with(notice: "Uploaded #{import.filename}: #{import.rows_added} new, #{import.rows_skipped} already held.")
  rescue BankImport::InvalidFile => e
    back_with(alert: e.message)
  end

  private

  def back_with(**flash)
    redirect_to admin_bank_imports_path, **flash
  end
end
