require "test_helper"

class FaqsControllerTest < ActionDispatch::IntegrationTest
  test "PDF attachments in answers render as downloadable links" do
    faq = Faq.create!(question: "Fire safety", active: true)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("sample.pdf").open,
      filename: "evacuation-plan.pdf",
      content_type: "application/pdf"
    )
    faq.update!(answer: ActionText::Attachment.from_attachable(blob).to_html)

    get faq_path

    assert_response :success
    assert_select "figure.attachment a[href*=?]", rails_blob_path(blob, disposition: "attachment")
  end

  test "inline image attachments are not wrapped in a download link" do
    faq = Faq.create!(question: "Poster", active: true)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("sample.png").open,
      filename: "poster.png",
      content_type: "image/png"
    )
    faq.update!(answer: ActionText::Attachment.from_attachable(blob).to_html)

    get faq_path

    assert_response :success
    assert_select "figure.attachment", 1
    assert_select "figure.attachment a", 0
  end
end
