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
  p.content = <<~HTML
    <h2>About THENCF</h2>
    <p>THENCF is a cultural cooperative based in Ballina, County Mayo. Our legal form is "THENCF COMPANY LIMITED BY GUARANTEE" r/n 767209.</p>
    <p>We are organised <a href="https://www.ica.coop/en/whats-co-op/co-operative-identity-values-principles">according to the ICA cooperative principles</a>.</p>
    <blockquote>
      <p>Cooperatives are based on the values of self-help, self-responsibility, democracy, equality, equity, and solidarity. In the tradition of their founders, cooperative members believe in the ethical values of honesty, openness, social responsibility and caring for others.</p>
    </blockquote>
    <p>We are also a member of the <a href="https://encc.eu/pages/the-encc">European Network of Cultural Centres</a>.</p>

    <h2>Location</h2>
    <p>THENCF community art space is located at 5 Pearse Street, Upstairs, Old Albany Store, Ballina, Co. Mayo, F26 F9T7.</p>
    <p>The space comprises two large rooms, two small rooms and a terrace.</p>

    <h3>Goals</h3>
    <ul>
      <li>Community and social meet-ups for local artists.</li>
      <li>Public and private spaces for artists.</li>
      <li>Reduce youth migration from area through better social facilities.</li>
      <li>Increase participation in the arts.</li>
      <li>Develop local artists.</li>
      <li>To regenerate the town by reusing vacant spaces.</li>
      <li>To create a vibrant, authentic, modern nightlife in the area.</li>
      <li>Improve prestige of area abroad.</li>
    </ul>
  HTML
end

## Contact page is now served by ContactsController, not a CMS page.

Page.find_or_create_by!(slug: "privacy") do |p|
  p.title = "Privacy Policy"
  p.visibility = :published
  p.nav_location = :footer
  p.content = <<~HTML
    <h2>Privacy Policy</h2>
    <p>THENCF respects your privacy. This policy explains what data we collect and how we use it.</p>

    <h3>What we collect</h3>
    <p>The only personal data we collect is your <strong>email address</strong>, provided when you register as a member or use our contact form.</p>

    <h3>How we use it</h3>
    <p>Your email address is used solely for:</p>
    <ul>
      <li>Sending our newsletter</li>
      <li>Communications related to your membership and our activities</li>
    </ul>

    <h3>What we don't do</h3>
    <ul>
      <li>We do not use any tracking, analytics, or monitoring on this website.</li>
      <li>We do not share, sell, or disclose your data to any third party.</li>
    </ul>

    <h3>Your rights</h3>
    <p>You can request access to, correction of, or deletion of your data at any time by contacting us at <a href="mailto:info@thencf.art">info@thencf.art</a>.</p>
  HTML
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

Page.find_or_create_by!(slug: "faq") do |p|
  p.title = "Frequently Asked Questions"
  p.visibility = :published
  p.nav_location = :dropdown
  p.content = <<~HTML
    <h2>About THENCF</h2>

    <h3>What is THENCF?</h3>
    <p>THENCF (The North Connacht Cultural Co-op) is a member-owned cooperative dedicated to supporting artists, makers, and creative practitioners in the northwest of Ireland. Based in Ballina, Co. Mayo, we provide workspace, resources, and a supportive community for creative work.</p>

    <h3>Who can join?</h3>
    <p>Anyone with an interest in arts, making, or creative practice is welcome. You don't need to be a professional artist - we welcome hobbyists, learners, and curious people of all skill levels.</p>

    <h3>Where are you located?</h3>
    <p>We're based in Ballina, County Mayo. The full address and directions are available on our <a href="/pages/contact">contact page</a>.</p>

    <h2>Membership</h2>

    <h3>How much does membership cost?</h3>
    <p>Membership rates vary by type. We offer standard memberships and concession rates for students, unwaged, and those on limited income. Contact us for current pricing.</p>

    <h3>What do I get as a member?</h3>
    <ul>
      <li>Access to the workshop and studio spaces during opening hours</li>
      <li>Use of shared tools and equipment</li>
      <li>Access to the members' forum and community</li>
      <li>Discounts on workshops and events</li>
      <li>Storage space (subject to availability)</li>
      <li>A say in how the co-op is run</li>
    </ul>

    <h3>How do I become a member?</h3>
    <p>Come along to an Open Night to see the space and meet current members. If you'd like to join, we'll help you sign up on the spot or you can apply online through your account.</p>

    <h2>The Space</h2>

    <h3>What spaces and equipment do you have?</h3>
    <p>We have a main workshop for woodwork, metalwork, and general making; a studio space for cleaner work; and a meeting room for gatherings and small events. Specific equipment lists are available to members.</p>

    <h3>Can I book the space for private events?</h3>
    <p>Members can book spaces through the calendar on this site. For larger events or non-member bookings, please <a href="/pages/contact">get in touch</a> to discuss.</p>

    <h3>What are your opening hours?</h3>
    <p>Opening hours vary - check the calendar for current availability. Open Nights are held regularly and are open to everyone.</p>

    <h2>Events & Workshops</h2>

    <h3>Do I need to be a member to attend events?</h3>
    <p>Most of our events are open to everyone. Some member-only events are marked as such. Open Night is always open to all.</p>

    <h3>Can I propose a workshop or event?</h3>
    <p>Absolutely! We welcome members proposing and running workshops. Post your idea in the forum or speak to any board member.</p>

    <h3>How do I stay updated about events?</h3>
    <p>Join our newsletter for regular updates, or check the events page on this site. Members can also follow discussions in the forum.</p>

    <h2>Getting Involved</h2>

    <h3>How is the co-op run?</h3>
    <p>We're a member-owned cooperative. Major decisions are made collectively at general meetings. Day-to-day operations are handled by the board, who are elected by members.</p>

    <h3>Can I help out?</h3>
    <p>Yes! We're always looking for help with maintenance, events, outreach, and more. Speak to any board member or post in the forum if you'd like to get involved.</p>

    <h3>I have another question</h3>
    <p>Drop us a line at <a href="mailto:hello@thencf.art">hello@thencf.art</a> or ask on the forum. We're happy to help.</p>
  HTML
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