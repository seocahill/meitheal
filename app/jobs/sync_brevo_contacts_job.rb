class SyncBrevoContactsJob < ApplicationJob
  queue_as :default

  def perform(brevo_service: BrevoService.new)
    @brevo = brevo_service
    return unless @brevo.configured?

    # Fetch contacts from both sides
    brevo_contacts = fetch_brevo_contacts
    local_users = User.where(approved: true)

    # Build email sets for comparison (normalized)
    brevo_emails = brevo_contacts.map { |c| c[:email].downcase }.to_set
    local_emails = local_users.map { |u| u.email_address.downcase }.to_set

    # Sync local → Brevo (users not in Brevo)
    local_users.each do |user|
      email_normalized = user.email_address.downcase
      next if brevo_emails.include?(email_normalized)

      sync_user_to_brevo(user)
    end

    # Sync Brevo → local (contacts not in local DB)
    brevo_contacts.each do |contact|
      email_normalized = contact[:email].downcase
      next if local_emails.include?(email_normalized)

      sync_contact_to_local(contact)
    end
  rescue BrevoService::ApiError => e
    Rails.logger.error("SyncBrevoContactsJob Brevo error: #{e.message}")
  end

  private

  def fetch_brevo_contacts
    all_contacts = []
    offset = 0
    limit = 500

    loop do
      batch = @brevo.list_contacts(limit: limit, offset: offset)
      break if batch.empty?

      all_contacts.concat(batch)
      offset += limit
      break if batch.size < limit
    end

    all_contacts
  end

  def sync_user_to_brevo(user)
    @brevo.add_contact(user.email_address, name: user.name)
    Rails.logger.info("SyncBrevoContactsJob: Added #{user.email_address} to Brevo")
  rescue BrevoService::ApiError => e
    Rails.logger.warn("SyncBrevoContactsJob: Could not add #{user.email_address} to Brevo: #{e.message}")
  end

  def sync_contact_to_local(contact)
    email = contact[:email]
    first_name = contact.dig(:attributes, :FIRSTNAME)

    # Create user with secure random password
    password = SecureRandom.hex(32)
    user = User.create!(
      email_address: email,
      password: password,
      password_confirmation: password,
      approved: true
    )

    # Create profile with name if provided
    if first_name.present?
      user.create_profile!(name: first_name)
    end

    Rails.logger.info("SyncBrevoContactsJob: Created local user #{email} from Brevo")
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("SyncBrevoContactsJob: Could not create user #{email}: #{e.message}")
  end
end
