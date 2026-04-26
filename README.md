# Meitheal

**Meitheal** (from the Irish tradition of communal labour) is a platform for de-bottlenecking art collectives. It distributes the administrative and organisational work that typically concentrates in one or two overloaded people — memberships, bookings, funding, communication, publishing — across the whole collective.

Built for [NCF — The North Connacht Co-op](https://thencf.art), an arts cooperative in Ballina, Co. Mayo, Ireland.

---

## What it does

### Membership management
Members sign up and are approved by admins. Multiple tiers are supported (associate, concession, full, youth), with expiry tracking and payment recording.

### Space booking
Members can book shared studio/event spaces. The system detects overlapping bookings across linked (component) spaces and tracks payment status per booking.

### Events & posts
Editors can publish events and news posts with rich text and images. Content can be scheduled and toggled between draft and published states.

### Funding opportunities
A curated directory of grants and funding calls, with deadline tracking and category filtering. Funding opportunities can be manually added by any member (in order to ensure equally access for all). A background job uses an LLM (Mistral) supplements this by researching and suggesting new opportunities from sources like Mayo Arts Service, the Arts Council, and European funding bodies. 

### Proposals
Members can submit funding proposals against opportunities. Proposals move through a draft → submitted → approved/rejected workflow, with document upload support.

### Newsletters
Rich-text newsletters with Brevo (Sendinblue) integration for sending campaigns. An AI-assisted content generation step drafts the news section from recent emails.

### Member directory & profiles
An opt-in public directory of member artists with skill-based search and portfolio images.

### Forum
Integrated community discussion forum (Thredded), with AI-powered moderation against the collective's ethics code.

### Email groups
Mailing lists (e.g. info@thencf.art) with Zoho Mail integration and per-group email archiving.

### Admin tooling
- Full user/membership/payment/booking management
- Internal todo list with priority and due dates
- Funding opportunity curation and AI-refresh
- Inbox view for inbound emails
- Calendar import (iCalendar format)
- Job queue and Litestream monitoring

---

## Technical overview

| Concern | Approach |
|---|---|
| Framework | Rails 8.1 |
| Database | SQLite3 (with Litestream for replication) |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS, importmap |
| Background jobs | Solid Queue |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| File storage | Active Storage → AWS S3 (production) |
| Auth | Custom cookie sessions, bcrypt |
| Payments | SumUp |
| Email marketing | Brevo |
| Email sync | Zoho Mail |
| LLM | ruby_llm (Mistral primary) |
| Deployment | Kamal + Docker |
| Error tracking | Sentry |

---

## Getting started

**Requirements:** Ruby 3.4.2, bundler, SQLite3

```sh
bundle install
bin/rails db:setup
bin/rails server
```

### Running tests

```sh
bin/rails test
```

### Environment variables

Copy `.env.example` (if present) and fill in:

- `BREVO_API_KEY` — Brevo email marketing
- `SUMUP_API_KEY` — SumUp payment processing
- `ZOHO_*` — Zoho Mail OAuth credentials
- `MISTRAL_API_KEY` — LLM access
- `AWS_*` — S3 for file storage (production)
- `RECAPTCHA_*` — reCAPTCHA site/secret keys
- `SENTRY_DSN` — Error reporting

### Accessing production

```sh
kamal console   # Rails console on prod
```

---

## Roles

| Role | Can do |
|---|---|
| `viewer` | Browse content, book spaces, submit proposals |
| `editor` | Everything above + publish events/posts, manage newsletters, confirm bookings |
| `owner` | Full admin access |

New accounts require admin approval before activation.
