require "test_helper"

class SyncBrevoNewslettersJobTest < ActiveJob::TestCase
  setup do
    # Campaigns are Hashes with symbol keys (Brevo API with symbolize_names: true)
    @campaigns = [
      { id: 101, subject: "October Newsletter" },
      { id: 102, subject: "November Newsletter" }
    ]

    # campaign_content returns a model object with accessor methods
    @details_101 = build_campaign_details(
      subject: "October Newsletter",
      html_content: "<html><body><p>Hello October</p></body></html>",
      sent_date: "2024-10-01T09:00:00Z"
    )
    @details_102 = build_campaign_details(
      subject: "November Newsletter",
      html_content: "<html><body><p>Hello November</p></body></html>",
      sent_date: "2024-11-01T09:00:00Z"
    )

    @stub_brevo = build_stub_brevo
  end

  test "imports new campaigns as newsletters" do
    assert_difference "Newsletter.count", 2 do
      SyncBrevoNewslettersJob.perform_now(brevo_service: @stub_brevo)
    end

    oct = Newsletter.find_by(brevo_campaign_id: 101)
    assert_equal "October Newsletter", oct.subject
    assert_equal :sent, oct.status.to_sym
    assert_in_delta Time.parse("2024-10-01T09:00:00Z"), oct.sent_at, 1

    nov = Newsletter.find_by(brevo_campaign_id: 102)
    assert_equal "November Newsletter", nov.subject
  end

  test "skips campaigns already imported" do
    Newsletter.create!(
      subject: "October Newsletter",
      content: "<p>Hello October</p>",
      status: :sent,
      sent_at: Time.parse("2024-10-01T09:00:00Z"),
      brevo_campaign_id: 101
    )

    assert_difference "Newsletter.count", 1 do
      SyncBrevoNewslettersJob.perform_now(brevo_service: @stub_brevo)
    end

    # Campaign 101 was pre-existing — must not be duplicated
    assert_equal 1, Newsletter.where(brevo_campaign_id: 101).count
    # Campaign 102 was new — must have been imported
    assert Newsletter.find_by(brevo_campaign_id: 102)
  end

  test "does nothing when Brevo is not configured" do
    @stub_brevo.define_singleton_method(:configured?) { false }

    assert_no_difference "Newsletter.count" do
      SyncBrevoNewslettersJob.perform_now(brevo_service: @stub_brevo)
    end
  end

  test "handles Brevo API errors gracefully" do
    @stub_brevo.define_singleton_method(:sent_campaigns) do
      raise BrevoService::ApiError, "Rate limited"
    end

    assert_nothing_raised do
      SyncBrevoNewslettersJob.perform_now(brevo_service: @stub_brevo)
    end
  end

  test "continues past individual campaign errors" do
    call_count = 0
    @stub_brevo.define_singleton_method(:campaign_content) do |id|
      call_count += 1
      raise BrevoService::ApiError, "Not found" if id == 101
      OpenStruct.new(
        subject: "November Newsletter",
        html_content: "<html><body><p>Hello November</p></body></html>",
        sent_date: "2024-11-01T09:00:00Z"
      )
    end

    assert_difference "Newsletter.count", 1 do
      SyncBrevoNewslettersJob.perform_now(brevo_service: @stub_brevo)
    end

    assert Newsletter.find_by(brevo_campaign_id: 102)
    assert_nil Newsletter.find_by(brevo_campaign_id: 101)
  end

  test "continues past campaigns that fail to save as newsletters" do
    # Campaign 101 returns empty content — Newsletter.create! will raise RecordInvalid
    # because content is required. The job must not crash; campaign 102 must still import.
    @stub_brevo.define_singleton_method(:campaign_content) do |id|
      case id
      when 101
        OpenStruct.new(
          subject: "October Newsletter",
          html_content: "",
          sent_date: "2024-10-01T09:00:00Z"
        )
      when 102
        OpenStruct.new(
          subject: "November Newsletter",
          html_content: "<html><body><p>Hello November</p></body></html>",
          sent_date: "2024-11-01T09:00:00Z"
        )
      end
    end

    assert_difference "Newsletter.count", 1 do
      assert_nothing_raised do
        SyncBrevoNewslettersJob.perform_now(brevo_service: @stub_brevo)
      end
    end

    assert Newsletter.find_by(brevo_campaign_id: 102)
    assert_nil Newsletter.find_by(brevo_campaign_id: 101)
  end

  test "strips email HTML wrapper from content" do
    SyncBrevoNewslettersJob.perform_now(brevo_service: @stub_brevo)

    oct = Newsletter.find_by(brevo_campaign_id: 101)
    refute_includes oct.content.to_s, "<html>"
    refute_includes oct.content.to_s, "<body>"
    assert_includes oct.content.to_s, "Hello October"
  end

  private

  def build_campaign_details(subject:, html_content:, sent_date:)
    OpenStruct.new(subject: subject, html_content: html_content, sent_date: sent_date)
  end

  def build_stub_brevo
    test_case = self
    stub = Object.new
    stub.define_singleton_method(:configured?) { true }
    stub.define_singleton_method(:sent_campaigns) do
      test_case.instance_variable_get(:@campaigns)
    end
    stub.define_singleton_method(:campaign_content) do |id|
      case id
      when 101 then test_case.instance_variable_get(:@details_101)
      when 102 then test_case.instance_variable_get(:@details_102)
      end
    end
    stub
  end
end
