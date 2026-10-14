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

  def campaign(subject:, sent: "2026-10-02T12:07:22.000+02:00", link: "http://sh1.sendinblue.com/abc.html")
    { id: 1, subject: subject, sentDate: sent, shareLink: link }
  end

  def list(brevo, cache: ActiveSupport::Cache::MemoryStore.new)
    SentNewsletter.all(brevo: brevo, cache: cache)
  end

  test "maps each sent campaign to its subject, send date and public link" do
    entries = list(FakeBrevo.new(campaigns: [ campaign(subject: "October Newsletter") ]))

    assert_equal 1, entries.size
    assert_equal "October Newsletter", entries.first.subject
    assert_equal Date.new(2026, 10, 2), entries.first.sent_on
    assert_equal "http://sh1.sendinblue.com/abc.html", entries.first.url
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

  test "reuses the cached list instead of asking Brevo again" do
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
    failing = FakeBrevo.new(error: BrevoService::ApiError.new("Brevo is down"))

    assert_equal [], list(failing, cache: cache)

    working = FakeBrevo.new(campaigns: [ campaign(subject: "October Newsletter") ])
    assert_equal [ "October Newsletter" ], list(working, cache: cache).map(&:subject)
  end
end
