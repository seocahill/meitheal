# Seeds are idempotent: safe to run multiple times.
# Load with: bin/rails db:seed
#
# Dev users use password "password" (change in production).

# --- Users ---
admin = User.find_by(email_address: "seosamh@seocahill.com")

editor = User.second

member = User.third


# --- Spaces ---

front_room = Space.find_or_create_by!(name: "Front Room") do |s|
  s.description = "Front room of the space."
  s.capacity = 8
  s.active = true
end

back_room = Space.find_or_create_by!(name: "Back Room") do |s|
  s.description = "Back room of the space."
  s.capacity = 8
  s.active = true
end

# --- Events ---
base = Time.current


# --- Memberships ---

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

# --- Newsletters ---
Newsletter.find_or_create_by!(subject: "Welcome to THENCF – January") do |n|
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
