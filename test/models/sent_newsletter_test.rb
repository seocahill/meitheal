require "test_helper"

class SentNewsletterTest < ActiveSupport::TestCase
  class FakeBrevo
    attr_reader :calls

    def initialize(campaigns: [], error: nil)
      @campaigns = campaigns
      @error = error
      @calls = 0
    end

    def sent_campaigns
      @calls += 1
      raise @error if @error

      @campaigns
    end
  end

  setup do
    # Start from no archive so each test states exactly the archive it needs.
    Newsletter.delete_all
    @next_id = 100
  end

  def campaign(subject:, id: (@next_id += 1), sent: "2026-10-02T12:07:22.000+02:00", link: "http://sh1.sendinblue.com/abc.html")
    { id: id, subject: subject, sentDate: sent, shareLink: link }
  end

  def archive(subject, brevo_campaign_id: nil, sent_at: Time.zone.local(2025, 12, 26, 15, 0), status: :sent)
    Newsletter.create!(subject: subject, content: "<p>#{subject}</p>", status: status, sent_at: sent_at, brevo_campaign_id: brevo_campaign_id)
  end

  def list(brevo, cache: ActiveSupport::Cache::MemoryStore.new)
    SentNewsletter.all(brevo: brevo, cache: cache)
  end

  # From Brevo
  test "maps each sent campaign to its subject, send date and public link" do
    entries = list(FakeBrevo.new(campaigns: [ campaign(subject: "October Newsletter") ]))

    assert_equal 1, entries.size
    assert_equal "October Newsletter", entries.first.subject
    assert_equal Date.new(2026, 10, 2), entries.first.sent_on
    assert_equal "http://sh1.sendinblue.com/abc.html", entries.first.url
    assert_nil entries.first.archive_id
  end

  test "keeps the send date as Brevo states it, even late in the evening" do
    entries = list(FakeBrevo.new(campaigns: [ campaign(subject: "Late", sent: "2026-08-01T23:50:00.000+02:00") ]))
    assert_equal Date.new(2026, 8, 1), entries.first.sent_on
  end

  test "lists newest first whatever order Brevo returns" do
    entries = list(FakeBrevo.new(campaigns: [
      campaign(subject: "August", sent: "2026-08-01T20:18:45.000+02:00"),
      campaign(subject: "October", sent: "2026-10-02T12:07:22.000+02:00"),
      campaign(subject: "September", sent: "2026-09-02T14:59:29.000+02:00")
    ]))

    assert_equal %w[October September August], entries.map(&:subject)
  end

  test "skips campaigns without a public link or send date" do
    entries = list(FakeBrevo.new(campaigns: [
      campaign(subject: "No link", link: nil),
      campaign(subject: "Blank link", link: ""),
      campaign(subject: "No date", sent: nil),
      campaign(subject: "Complete")
    ]))

    assert_equal [ "Complete" ], entries.map(&:subject)
  end

  test "reuses the cached Brevo list instead of asking Brevo again" do
    brevo = FakeBrevo.new(campaigns: [ campaign(subject: "October Newsletter") ])
    cache = ActiveSupport::Cache::MemoryStore.new

    2.times { list(brevo, cache: cache) }

    assert_equal 1, brevo.calls
  end

  test "an empty list from Brevo is cached too" do
    brevo = FakeBrevo.new(campaigns: [])
    cache = ActiveSupport::Cache::MemoryStore.new

    2.times { assert_equal [], list(brevo, cache: cache) }

    assert_equal 1, brevo.calls
  end

  test "returns an empty list when Brevo is not configured" do
    assert_equal [], list(FakeBrevo.new(error: BrevoService::ConfigurationError.new("Missing configuration")))
  end

  test "returns an empty list and logs when Brevo fails, and does not cache the failure" do
    cache = ActiveSupport::Cache::MemoryStore.new

    assert_equal [], list(FakeBrevo.new(error: BrevoService::ApiError.new("Brevo is down")), cache: cache)

    working = FakeBrevo.new(campaigns: [ campaign(subject: "October Newsletter") ])
    assert_equal [ "October Newsletter" ], list(working, cache: cache).map(&:subject)
  end

  # Merged with our own archived copies
  test "links to our archived copy when one exists for the Brevo campaign" do
    copy = archive("December Newsletter", brevo_campaign_id: 11)
    entries = list(FakeBrevo.new(campaigns: [ campaign(subject: "December Newsletter", id: 11, sent: "2025-12-26T15:04:25.000+01:00") ]))

    assert_equal 1, entries.size
    assert_equal copy.id, entries.first.archive_id
    assert_equal Date.new(2025, 12, 26), entries.first.sent_on
  end

  test "campaigns with no archived copy link to Brevo's hosted copy" do
    archive("December Newsletter", brevo_campaign_id: 11)
    entries = list(FakeBrevo.new(campaigns: [ campaign(subject: "October Newsletter", id: 9999) ]))

    october = entries.find { |e| e.subject == "October Newsletter" }
    assert_nil october.archive_id
    assert_equal "http://sh1.sendinblue.com/abc.html", october.url
  end

  test "keeps archived newsletters Brevo no longer lists" do
    copy = archive("December Newsletter", brevo_campaign_id: 11)
    entries = list(FakeBrevo.new(campaigns: []))

    assert_equal [ "December Newsletter" ], entries.map(&:subject)
    assert_equal copy.id, entries.first.archive_id
    assert_equal Date.new(2025, 12, 26), entries.first.sent_on
  end

  test "archived newsletters still appear when Brevo is unavailable" do
    archive("December Newsletter", brevo_campaign_id: 11)
    entries = list(FakeBrevo.new(error: BrevoService::ApiError.new("down")))

    assert_equal [ "December Newsletter" ], entries.map(&:subject)
  end

  test "drafts and unsent newsletters are never listed" do
    archive("Still a draft", status: :draft, sent_at: nil)
    assert_equal [], list(FakeBrevo.new(campaigns: [])).map(&:subject)
  end

  test "a campaign and its archived copy are listed once" do
    archive("December Newsletter", brevo_campaign_id: 11)
    entries = list(FakeBrevo.new(campaigns: [ campaign(subject: "December Newsletter", id: 11) ]))

    assert_equal 1, entries.size
  end

  test "archive and Brevo entries are merged newest first" do
    archive("Old archived", brevo_campaign_id: 5, sent_at: Time.zone.local(2024, 8, 1, 12, 0))
    entries = list(FakeBrevo.new(campaigns: [ campaign(subject: "October Newsletter", sent: "2026-10-02T12:07:22.000+02:00") ]))

    assert_equal [ "October Newsletter", "Old archived" ], entries.map(&:subject)
  end

  test "the archive is read fresh even when the Brevo list is cached" do
    brevo = FakeBrevo.new(campaigns: [])
    cache = ActiveSupport::Cache::MemoryStore.new
    list(brevo, cache: cache)

    archive("Added later")

    assert_includes list(brevo, cache: cache).map(&:subject), "Added later"
  end
end
