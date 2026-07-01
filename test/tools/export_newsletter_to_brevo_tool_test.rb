require "test_helper"

class ExportNewsletterToBrevoToolTest < ActiveSupport::TestCase
  # Fakes the Brevo API collaborator at its boundary (mirrors the approach in
  # BrevoServiceTest) so the test exercises the tool's orchestration, not the
  # external HTTP call.
  class FakeBrevo
    attr_reader :created, :updated

    def initialize(configured:, create_id: nil)
      @configured = configured
      @create_id = create_id
    end

    def configured?
      @configured
    end

    def create_campaign(newsletter)
      @created = newsletter
      @create_id
    end

    def update_campaign(campaign_id, newsletter)
      @updated = [ campaign_id, newsletter ]
      campaign_id
    end
  end

  test "exports a new newsletter and stores the returned campaign id" do
    newsletter = Newsletter.create!(subject: "S", content: "<p>c</p>")

    output = tool_with(FakeBrevo.new(configured: true, create_id: 555)).call(id: newsletter.id)

    assert_equal 555, newsletter.reload.brevo_campaign_id
    assert_match "555", output
  end

  test "updates an already-exported newsletter instead of creating a new campaign" do
    newsletter = Newsletter.create!(subject: "S", content: "<p>c</p>", brevo_campaign_id: 42)
    fake = FakeBrevo.new(configured: true)

    output = tool_with(fake).call(id: newsletter.id)

    assert_equal 42, fake.updated.first
    assert_nil fake.created
    assert_match(/updated/i, output)
  end

  test "does nothing when Brevo is not configured" do
    newsletter = Newsletter.create!(subject: "S", content: "<p>c</p>")

    output = tool_with(FakeBrevo.new(configured: false)).call(id: newsletter.id)

    assert_nil newsletter.reload.brevo_campaign_id
    assert_match(/not configured/i, output)
  end

  test "reports when the newsletter is missing" do
    assert_match(/no newsletter found/i, ExportNewsletterToBrevoTool.new.call(id: 999_999))
  end

  private

  def tool_with(fake)
    tool = ExportNewsletterToBrevoTool.new
    tool.define_singleton_method(:brevo_service) { fake }
    tool
  end
end
