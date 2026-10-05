# Deprecated tables and columns

These tables and columns are no longer used by the app. Their features were retired and the code removed, but the data was left in place so nothing is lost until someone decides to clear it out.

Before dropping anything, take a backup and check the row counts in production (`kamal console`). Dropping is a separate migration per group.

| Feature (retired) | Tables | Notes |
|---|---|---|
| Forum (Thredded) | `thredded_*` (24 tables), `friendly_id_slugs` | Member posts live here. `db/migrate/20260202011753_create_thredded.thredded.rb` is now a no-op because the gem is gone; the tables come from `db/schema.rb`. |
| AI compose / forum moderation (ruby_llm) | `chats`, `messages`, `tool_calls`, `models` | Also the `newsletters.chat_id` column. |
| Inbox (Zoho email sync) | `cached_emails` | Attachments are Active Storage blobs and are purged by `CleanupOrphanedBlobsJob` once unattached. |
| Email groups | `email_groups`, `email_group_memberships`, `archived_emails`, `action_mailbox_inbound_emails` | |
| Admin todos | `admin_todos` | Auto-created from inbox emails. |
| Newsletter editor | `newsletters.chat_id` (column) | The `newsletters` table itself is **in use again, read-only**: it holds the site's archived copies of past newsletters, shown on the public newsletter page. Drafts in it are unused. |
| Funding approval queue | `funding_opportunities.approved` (column) | Opportunities are visible as soon as they are added. |

Still in use, do not drop: `newsletters` (see above), `oauth_*` (the claude.ai connector), `stored_files`, and everything not listed above.
