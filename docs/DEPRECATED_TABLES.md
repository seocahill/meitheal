# Deprecated tables and columns

These tables and columns are no longer used by the app. Their features were retired and the code removed, but the data was left in place so nothing is lost until someone decides to clear it out.

Before dropping anything, take a backup and check the row counts in production (`kamal console`). Dropping is a separate migration per group.

| Feature (retired) | Tables | Notes |
|---|---|---|
| Forum (Thredded) | `thredded_*` (24 tables), `friendly_id_slugs` | Member posts live here. `db/migrate/20260202011753_create_thredded.thredded.rb` is now a no-op because the gem is gone; the tables come from `db/schema.rb`. |
| AI compose / forum moderation (ruby_llm) | `chats`, `messages`, `tool_calls`, `models` | Also `newsletters.chat_id`. |
| Inbox (Zoho email sync) | `cached_emails` | Attachments are Active Storage blobs and are purged by `CleanupOrphanedBlobsJob` once unattached. |
| Email groups | `email_groups`, `email_group_memberships`, `archived_emails`, `action_mailbox_inbound_emails` | |
| Admin todos | `admin_todos` | Auto-created from inbox emails. |
| Newsletter editor | `newsletters` | Also rows in `action_text_rich_texts` with `record_type = 'Newsletter'`. Sent newsletters now come from Brevo. |
| Funding approval queue | `funding_opportunities.approved` (column) | Opportunities are visible as soon as they are added. |

Still in use, do not drop: `oauth_*` (the claude.ai connector), `stored_files`, and everything not listed above.
