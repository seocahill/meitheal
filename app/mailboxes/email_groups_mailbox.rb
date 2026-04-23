class EmailGroupsMailbox < ApplicationMailbox
  before_processing :ensure_group_exists

  def process
    # Archive the incoming email
    archived = @group.archived_emails.create!(
      from_address: mail.from.first,
      subject: mail.subject,
      body: mail.body.decoded,
      received_at: Time.current
    )

    # Distribute to all group members
    distribute_to_members(archived)
  end

  private

  def ensure_group_exists
    local_part = mail.to.first.split("@").first.downcase
    @group = EmailGroup.active.find_by(local_part: local_part)

    unless @group
      bounced!
      nil
    end
  end

  def distribute_to_members(archived)
    @group.members.each do |member|
      EmailGroupMailer.forward_email(
        group: @group,
        archived_email: archived,
        recipient: member
      ).deliver_later
    end
  end
end
