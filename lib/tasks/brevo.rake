namespace :brevo do
  desc "Import sent campaigns from Brevo as newsletter records"
  task import_newsletters: :environment do
    brevo = BrevoService.new
    unless brevo.configured?
      puts "Brevo is not configured. Set BREVO_API_KEY, BREVO_SENDER_EMAIL, and BREVO_LIST_ID."
      next
    end

    campaigns = brevo.sent_campaigns
    puts "Found #{campaigns.size} sent campaigns in Brevo"

    imported = 0
    skipped = 0

    campaigns.each do |campaign|
      # Campaign list items are Hashes with symbol keys from the Brevo API
      campaign_id = campaign[:id]
      campaign_subject = campaign[:subject]

      if Newsletter.exists?(brevo_campaign_id: campaign_id)
        puts "  SKIP: #{campaign_subject} (already imported)"
        skipped += 1
        next
      end

      details = brevo.campaign_content(campaign_id)
      sent_at = begin
        Time.parse(details.sent_date)
      rescue
        details.created_at ? Time.parse(details.created_at) : Time.current
      end

      Newsletter.create!(
        subject: details.subject,
        content: BrevoService.strip_email_wrapper(details.html_content),
        status: :sent,
        sent_at: sent_at,
        brevo_campaign_id: campaign_id
      )

      puts "  OK: #{details.subject}"
      imported += 1
    rescue => e
      puts "  ERROR: #{campaign_subject || campaign} - #{e.message}"
    end

    puts "\nDone: #{imported} imported, #{skipped} skipped"
  end

  desc "Sync all associate members to Brevo contact list"
  task sync_contacts: :environment do
    brevo = BrevoService.new
    unless brevo.configured?
      puts "Brevo is not configured. Set BREVO_API_KEY, BREVO_SENDER_EMAIL, and BREVO_LIST_ID."
      next
    end

    users = User.joins(:memberships)
                .where(memberships: { membership_type: :associate })
                .distinct

    puts "Syncing #{users.count} associate members to Brevo..."

    synced = 0
    failed = 0

    users.find_each do |user|
      brevo.add_contact(user.email_address, name: user.profile&.name)
      synced += 1
      print "."
    rescue BrevoService::ApiError => e
      failed += 1
      puts "\n  FAIL: #{user.email_address} - #{e.message}"
    end

    puts "\nDone: #{synced} synced, #{failed} failed"
  end
end
