# Seeds are idempotent: safe to run multiple times.
# Load with: bin/rails db:seed
#
# Dev users use password "password" (change in production).

# --- Users ---
admin = User.find_or_initialize_by(email_address: "admin@meitheal.example")
admin.assign_attributes(password: "password", role: :owner, approved: true)
admin.save!

editor = User.find_or_initialize_by(email_address: "editor@meitheal.example")
editor.assign_attributes(password: "password", role: :editor, approved: true)
editor.save!

member = User.find_or_initialize_by(email_address: "member@meitheal.example")
member.assign_attributes(password: "password", role: :viewer, approved: true)
member.save!

# --- Profiles (one per user) ---
[
  [ admin, "Admin User", "Co-ordinator of the space. Into making and community." ],
  [ editor, "Editor Person", "Designer and facilitator. I help run workshops." ],
  [ member, "Member One", "Maker and tinkerer. Wood, electronics, a bit of code." ]
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
  starts_at: (base + 3.days).change(hour: 10, min: 0),
) do |b|
  b.title = "Board meeting"
  b.description = "Monthly board prep."
  b.ends_at = (base + 3.days).change(hour: 12, min: 0)
  b.status = :confirmed
  b.agree_booking_rules = "1"
  b.agree_ethics = "1"
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
  b.agree_booking_rules = "1"
  b.agree_ethics = "1"
end

# --- Memberships ---
mem_admin = Membership.find_or_create_by!(user: admin, starts_on: 1.year.ago.to_date) do |m|
  m.membership_type = :associate
  m.expires_on = 1.year.from_now.to_date
  m.notes = "Founding member"
end

mem_editor = Membership.find_or_create_by!(user: editor, starts_on: 6.months.ago.to_date) do |m|
  m.membership_type = :associate
  m.expires_on = 6.months.from_now.to_date
  m.notes = nil
end

mem_member = Membership.find_or_create_by!(user: member, starts_on: 2.months.ago.to_date) do |m|
  m.membership_type = :youth
  m.expires_on = 10.months.from_now.to_date
  m.notes = "Student rate"
end

# --- Payments ---
Payment.find_or_create_by!(membership: mem_admin, paid_on: 1.year.ago.to_date) do |p|
  p.amount_cents = 300_00
  p.payment_method = :bank_transfer
  p.user_email = admin.email_address
  p.user_name = admin.name
  p.description = "NCF Associate Membership"
  p.notes = "Annual membership"
end

Payment.find_or_create_by!(membership: mem_editor, paid_on: 6.months.ago.to_date) do |p|
  p.amount_cents = 150_00
  p.payment_method = :bank_transfer
  p.user_email = editor.email_address
  p.user_name = editor.name
  p.description = "NCF Associate Membership"
  p.notes = "Half-year"
end

Payment.find_or_create_by!(membership: mem_member, paid_on: 2.months.ago.to_date) do |p|
  p.amount_cents = 75_00
  p.payment_method = :cash
  p.user_email = member.email_address
  p.user_name = member.name
  p.description = "NCF Youth Membership"
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
