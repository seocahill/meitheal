class Admin::StoredFilesController < Admin::BaseController
  include Pagy::Method
  before_action :require_editor

  def index
    scope = StoredFile.search(params[:q]).newest_first.includes(:user, file_attachment: :blob)
    @pagy, @stored_files = pagy(scope, items: 20)
  end

  def create
    uploads = Array(params.dig(:stored_file, :files)).compact_blank
    return redirect_to admin_stored_files_path, alert: "Choose at least one file to upload." if uploads.empty?

    description = params.dig(:stored_file, :description).presence
    stored_files = uploads.map { |upload| Current.user.stored_files.build(file: upload, description: description) }

    if stored_files.all?(&:valid?)
      stored_files.each(&:save!)
      redirect_to admin_stored_files_path, notice: "Uploaded #{stored_files.map(&:filename).to_sentence}."
    else
      problems = stored_files.reject(&:valid?).map { |f| "#{f.filename}: #{f.errors.full_messages.to_sentence}" }
      redirect_to admin_stored_files_path, alert: "Nothing was uploaded. #{problems.join('; ')}"
    end
  end

  def destroy
    stored_file = StoredFile.find(params[:id])
    stored_file.destroy
    redirect_to admin_stored_files_path, notice: "Deleted #{stored_file.filename}."
  end
end
