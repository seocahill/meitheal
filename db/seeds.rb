# Seeds are idempotent: safe to run multiple times.
# Load with: bin/rails db:seed
#
# Dev users use password "password" (change in production).

# --- Users ---
admin = User.find_or_initialize_by(email_address: "admin@meitheal.example")
admin.assign_attributes(password: "password", role: :owner)
admin.save!

editor = User.find_or_initialize_by(email_address: "editor@meitheal.example")
editor.assign_attributes(password: "password", role: :editor)
editor.save!

member = User.find_or_initialize_by(email_address: "member@meitheal.example")
member.assign_attributes(password: "password", role: :viewer)
member.save!

# --- Profiles (one per user) ---
[
  [admin, "Admin User", "Co-ordinator of the space. Into making and community."],
  [editor, "Editor Person", "Designer and facilitator. I help run workshops."],
  [member, "Member One", "Maker and tinkerer. Wood, electronics, a bit of code."]
].each do |user, name, bio|
  Profile.find_or_create_by!(user: user) do |p|
    p.name = name
    p.bio = bio
    p.location = "Dublin"
    p.skills = "workshops, facilitation, making"
    p.website = "https://example.com"
    p.visible = true
  end
end

# --- Spaces ---
workshop = Space.find_or_create_by!(name: "Main Workshop") do |s|
  s.description = "Woodwork, metal, and general making. Tables, benches, basic tools."
  s.capacity = 12
  s.active = true
end

meeting_room = Space.find_or_create_by!(name: "Meeting Room") do |s|
  s.description = "Quiet space for meetings and small events. Whiteboard, screen."
  s.capacity = 8
  s.active = true
end

studio = Space.find_or_create_by!(name: "Studio") do |s|
  s.description = "Artist studio and clean work area. Natural light."
  s.capacity = 4
  s.active = true
end

# --- Events ---
base = Time.current
Event.find_or_create_by!(title: "Open Night", user: admin) do |e|
  e.description = "Drop-in open evening. Tour, chat, and see what we do."
  e.starts_at = base + 1.week
  e.ends_at = base + 1.week + 3.hours
  e.doors_at = base + 1.week
  e.capacity = 30
  e.published = true
  e.venue_name = "Meitheal Main Space"
  e.venue_address = "123 Maker Lane, Dublin"
  e.ticket_price_cents = 0
  e.ticket_url = nil
  e.bio = "Everyone welcome."
  e.links = "https://meitheal.example/events"
end

Event.find_or_create_by!(title: "Intro to Woodwork", user: editor) do |e|
  e.description = "Hands-on intro to tools and basic joins. Bring ideas."
  e.starts_at = base + 2.weeks
  e.ends_at = base + 2.weeks + 4.hours
  e.doors_at = base + 2.weeks
  e.capacity = 10
  e.published = true
  e.venue_name = "Main Workshop"
  e.ticket_price_cents = 2_500
  e.ticket_url = "https://meitheal.example/tickets/woodwork"
  e.bio = "Suitable for beginners."
  e.links = nil
end

Event.find_or_create_by!(title: "Draft: Members Showcase", user: member) do |e|
  e.description = "Work in progress – showcase event for members (draft)."
  e.starts_at = base + 1.month
  e.ends_at = base + 1.month + 2.hours
  e.published = false
  e.venue_name = "Main Space"
  e.capacity = 50
end

# --- Bookings ---
Booking.find_or_create_by!(
  user: admin,
  space: workshop,
  starts_at: (base + 3.days).change(hour: 10, min: 0)
) do |b|
  b.title = "Board meeting"
  b.description = "Monthly board prep."
  b.ends_at = (base + 3.days).change(hour: 12, min: 0)
  b.status = :confirmed
end

Booking.find_or_create_by!(
  user: member,
  space: meeting_room,
  starts_at: (base + 5.days).change(hour: 14, min: 0)
) do |b|
  b.title = "Client call"
  b.description = "Project kick-off."
  b.ends_at = (base + 5.days).change(hour: 15, min: 0)
  b.status = :pending
end

# --- Memberships ---
mem_admin = Membership.find_or_create_by!(user: admin, starts_on: 1.year.ago.to_date) do |m|
  m.membership_type = :standard
  m.expires_on = 1.year.from_now.to_date
  m.notes = "Founding member"
end

mem_editor = Membership.find_or_create_by!(user: editor, starts_on: 6.months.ago.to_date) do |m|
  m.membership_type = :standard
  m.expires_on = 6.months.from_now.to_date
  m.notes = nil
end

mem_member = Membership.find_or_create_by!(user: member, starts_on: 2.months.ago.to_date) do |m|
  m.membership_type = :concession
  m.expires_on = 10.months.from_now.to_date
  m.notes = "Student rate"
end

# --- Payments ---
Payment.find_or_create_by!(membership: mem_admin, paid_on: 1.year.ago.to_date) do |p|
  p.amount_cents = 300_00
  p.payment_method = :bank_transfer
  p.notes = "Annual membership"
end

Payment.find_or_create_by!(membership: mem_editor, paid_on: 6.months.ago.to_date) do |p|
  p.amount_cents = 150_00
  p.payment_method = :bank_transfer
  p.notes = "Half-year"
end

Payment.find_or_create_by!(membership: mem_member, paid_on: 2.months.ago.to_date) do |p|
  p.amount_cents = 75_00
  p.payment_method = :cash
  p.notes = "Concession"
end

# --- Funding opportunities ---
FundingOpportunity.find_or_create_by!(title: "Community Arts Grant", organization: "Arts Council") do |f|
  f.description = "Grants for community-led arts and making projects."
  f.deadline = 3.months.from_now.to_date
  f.amount = 5_000
  f.categories = "arts, community, making"
  f.url = "https://example.com/community-arts"
end

FundingOpportunity.find_or_create_by!(title: "Tech for Good", organization: "Local Enterprise Office") do |f|
  f.description = "Funding for tech and maker initiatives with a social impact."
  f.deadline = 2.months.from_now.to_date
  f.amount = 10_000
  f.categories = "tech, social impact, innovation"
  f.url = "https://example.com/tech-for-good"
end

# --- Email groups ---
members_group = EmailGroup.find_or_create_by!(local_part: "members") do |g|
  g.name = "Members"
  g.description = "All current members. Used for space updates and general announcements."
  g.active = true
end

newsletter_group = EmailGroup.find_or_create_by!(local_part: "newsletter") do |g|
  g.name = "Newsletter"
  g.description = "Newsletter subscribers. Receives monthly updates and event highlights."
  g.active = true
end

board_group = EmailGroup.find_or_create_by!(local_part: "board") do |g|
  g.name = "Board"
  g.description = "Board members only. Internal coordination."
  g.active = true
end

# --- Email group memberships ---
[ [ board_group, admin ], [ newsletter_group, admin ], [ members_group, admin ],
  [ newsletter_group, editor ], [ members_group, editor ],
  [ members_group, member ] ].each do |group, user|
  EmailGroupMembership.find_or_create_by!(email_group: group, user: user)
end

# --- Archived emails (sample traffic) ---
ArchivedEmail.find_or_create_by!(
  email_group: newsletter_group,
  subject: "January digest – Open Night and Woodwork intro",
  received_at: 2.weeks.ago
) do |e|
  e.from_address = "editor@meitheal.example"
  e.body = "Hi everyone,\n\nQuick recap of what's coming up:\n\n– Open Night next week. Bring friends.\n– Intro to Woodwork in two weeks. Limited places.\n\nSee you in the space."
end

ArchivedEmail.find_or_create_by!(
  email_group: members_group,
  subject: "Workshop closure Tuesday 14th",
  received_at: 1.week.ago
) do |e|
  e.from_address = "admin@meitheal.example"
  e.body = "The main workshop will be closed 9am–1pm next Tuesday for maintenance. Meeting room and studio unchanged."
end

# --- Pages (CMS) ---
Page.find_or_create_by!(slug: "about") do |p|
  p.title = "About us"
  p.visibility = :published
  p.nav_location = :footer
  p.content = "<p>We're a community makerspace in Dublin. Members get access to the workshop, tools, and each other.</p><p>Drop in on Open Night or <a href=\"/pages/contact\">get in touch</a>.</p>"
end

Page.find_or_create_by!(slug: "contact") do |p|
  p.title = "Contact"
  p.visibility = :published
  p.nav_location = :footer
  p.content = "<p>Email: <a href=\"mailto:hello@thencf.art\">hello@thencf.art</a></p><p>Open Night is every second Thursday, 6–9pm. No booking needed for a look around.</p>"
end

Page.find_or_create_by!(slug: "code-of-conduct") do |p|
  p.title = "Code of conduct"
  p.visibility = :published
  p.nav_location = :dropdown
  p.content = "<p>Be respectful. Look after the space and the tools. No harassment, no discrimination. We aim for a welcoming environment for everyone.</p><p>Reports: talk to a board member or email board@thencf.art.</p>"
end

Page.find_or_create_by!(slug: "draft-page") do |p|
  p.title = "Draft page (unpublished)"
  p.visibility = :draft
  p.nav_location = :hidden
  p.content = "<p>This page is not published and will not appear on the site.</p>"
end

Page.find_or_create_by!(slug: "ethics") do |p|
  p.title = "Ethics Code"
  p.visibility = :published
  p.nav_location = :footer
  p.content = <<~HTML
    <h2>NCF Ethics Code</h2>
    <p>As members of the North Connacht Cultural Co-op, we commit to the following principles:</p>

    <h3>Respect & Inclusion</h3>
    <ul>
      <li>We welcome all people regardless of background, identity, or experience level</li>
      <li>We listen with openness and speak with kindness</li>
      <li>We make space for diverse perspectives and creative approaches</li>
    </ul>

    <h3>Collaboration & Solidarity</h3>
    <ul>
      <li>We share knowledge, resources, and opportunities generously</li>
      <li>We support fellow artists and makers in their work</li>
      <li>We credit and acknowledge contributions fairly</li>
    </ul>

    <h3>Sustainability & Care</h3>
    <ul>
      <li>We consider environmental impact in our practice</li>
      <li>We care for shared spaces and tools</li>
      <li>We prioritise wellbeing over productivity</li>
    </ul>

    <h3>Integrity & Accountability</h3>
    <ul>
      <li>We act honestly and transparently</li>
      <li>We take responsibility for our actions and their impact</li>
      <li>We address conflicts constructively and in good faith</li>
    </ul>

    <h3>Creative Freedom & Responsibility</h3>
    <ul>
      <li>We support artistic expression and experimentation</li>
      <li>We consider the impact of our work on communities</li>
      <li>We do not tolerate work that promotes hatred or discrimination</li>
    </ul>

    <p><em>This ethics code guides our forum discussions and all co-op activities. Forum posts that violate these principles may be moderated.</em></p>
  HTML
end

# --- Model (for AI/chat features) ---
default_model = Model.find_or_create_by!(provider: "openai", model_id: "gpt-4o-mini") do |m|
  m.name = "GPT-4o mini"
  m.context_window = 128_000
  m.max_output_tokens = 16_384
  m.family = "gpt-4o"
  m.pricing = {}
  m.capabilities = []
  m.modalities = {}
  m.metadata = {}
end

# --- Newsletters ---
Newsletter.find_or_create_by!(subject: "Welcome to Meitheal – January") do |n|
  n.status = :sent
  n.sent_at = 3.days.ago
  n.content = "<p>Hi,</p><p>Welcome to the first newsletter of the year. We've got Open Night coming up and an Intro to Woodwork workshop later in the month.</p><p>See you in the space.</p>"
end

Newsletter.find_or_create_by!(subject: "February draft – events and callouts") do |n|
  n.status = :draft
  n.sent_at = nil
  n.content = "<p>Draft placeholder. Add February events and any calls for help or proposals here.</p>"
end

# --- Forum Messageboards (Thredded) ---
if defined?(Thredded::Messageboard)
  Thredded::Messageboard.find_or_create_by!(name: "General") do |mb|
    mb.slug = "general"
    mb.description = "General discussion, announcements, and community chat"
    mb.position = 1
  end

  Thredded::Messageboard.find_or_create_by!(name: "Projects & Collaborations") do |mb|
    mb.slug = "projects"
    mb.description = "Share projects, find collaborators, and discuss works in progress"
    mb.position = 2
  end

  Thredded::Messageboard.find_or_create_by!(name: "Events & Workshops") do |mb|
    mb.slug = "events-workshops"
    mb.description = "Discuss upcoming events, workshops, and propose new ones"
    mb.position = 3
  end

  Thredded::Messageboard.find_or_create_by!(name: "Resources & Tips") do |mb|
    mb.slug = "resources"
    mb.description = "Share useful resources, tutorials, and tips for fellow artists and makers"
    mb.position = 4
  end

  Thredded::Messageboard.find_or_create_by!(name: "Funding & Opportunities") do |mb|
    mb.slug = "funding"
    mb.description = "Discuss funding applications, residencies, and opportunities"
    mb.position = 5
  end

  # --- Forum Topics and Posts ---
  general = Thredded::Messageboard.find_by(slug: "general")
  projects = Thredded::Messageboard.find_by(slug: "projects")
  events_board = Thredded::Messageboard.find_by(slug: "events-workshops")

  if general && !Thredded::Topic.exists?(title: "Welcome to the NCF Forum!")
    topic = Thredded::Topic.create!(
      messageboard: general,
      user: admin,
      title: "Welcome to the NCF Forum!",
      slug: "welcome-to-the-ncf-forum"
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: general,
      user: admin,
      content: <<~CONTENT
        Welcome to the North Connacht Cultural Co-op forum!

        This is a space for members to connect, share ideas, and collaborate. A few quick notes:

        - **Be respectful** - our [ethics code](/pages/ethics) applies here
        - **Share freely** - knowledge, resources, and opportunities
        - **Ask questions** - no question is too basic

        Looking forward to seeing what we build together!
      CONTENT
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: general,
      user: editor,
      content: "Great to see the forum up and running! I'll be posting workshop updates in the Events & Workshops board."
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: general,
      user: member,
      content: "Hello everyone! New member here. Looking forward to getting involved. Anyone working on electronics projects?"
    )
  end

  if projects && !Thredded::Topic.exists?(title: "What are you working on?")
    topic = Thredded::Topic.create!(
      messageboard: projects,
      user: editor,
      title: "What are you working on?",
      slug: "what-are-you-working-on"
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: projects,
      user: editor,
      content: <<~CONTENT
        Share what you're currently making or planning! Looking for feedback, collaborators, or just want to show off your progress? Post it here.

        I'm currently working on a series of laser-cut wooden sculptures that incorporate small LED circuits. Happy to share the design files when they're ready.
      CONTENT
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: projects,
      user: member,
      content: "Building a small weather station with a Raspberry Pi. Planning to display it on a screen in the workshop. Could use some help with the enclosure if anyone has woodworking skills!"
    )
  end

  if events_board && !Thredded::Topic.exists?(title: "Workshop idea: Intro to screen printing")
    topic = Thredded::Topic.create!(
      messageboard: events_board,
      user: member,
      title: "Workshop idea: Intro to screen printing",
      slug: "workshop-idea-intro-to-screen-printing"
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: events_board,
      user: member,
      content: <<~CONTENT
        Would anyone be interested in a screen printing workshop? I've done a bit of it before and could put together a beginner session.

        We'd need:
        - A screen and squeegee (I have one)
        - Inks (need to buy)
        - Some fabric or paper to print on

        Thinking a Saturday afternoon, 2-3 hours. Let me know if you'd come!
      CONTENT
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: events_board,
      user: admin,
      content: "This sounds great! We can probably cover materials from the workshop budget. Let's chat about dates - maybe after the next Open Night?"
    )
    Thredded::Post.create!(
      postable: topic,
      messageboard: events_board,
      user: editor,
      content: "Count me in! I've wanted to learn screen printing for ages. Saturday works well for me."
    )
  end
end