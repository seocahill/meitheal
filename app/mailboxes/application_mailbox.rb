class ApplicationMailbox < ActionMailbox::Base
  # Route emails to email groups (e.g., all@thencf.art, artists@thencf.art)
  routing /@thencf\.art\z/i => :email_groups
end
