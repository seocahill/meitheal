# claude.ai MCP Connector

Lets you read and edit the site's main resources from **claude.ai on the web**
(and Claude Desktop / Code) through a custom connector, using natural language.

The connector is an MCP server backed by an OAuth 2.1 authorization server built
into this app. Only an **owner** account can authorize it, and every action runs
as that owner.

## What it exposes

Four tools over the same resources as the REST API (`faqs`, `pages`, `posts`,
`events`, `newsletters`, `funding_opportunities`, `spaces`, `bookings`,
`memberships`, `proposals`, `payments`, `tickets`, `email_groups`, `admin_todos`,
`profiles`, `users`):

- `list_records(resource)`
- `get_record(resource, id)`
- `create_record(resource, attributes)`
- `update_record(resource, id, attributes)`

Writable fields per resource come straight from the REST API controllers
(`app/controllers/api/v1/*`), so the two surfaces never disagree. There is **no
delete tool**. `users.role` is not writable and password digests are never
returned. Rich-text fields (`answer`, `content`, `body`, `rich_description`)
accept and return HTML.

## Endpoints

| Path | Purpose |
|------|---------|
| `POST /mcp` | The MCP endpoint (JSON-RPC, Streamable HTTP). Requires a Bearer token with the `mcp:access` scope. |
| `/.well-known/oauth-authorization-server` | RFC 8414 metadata Claude reads to discover the OAuth server. |
| `/.well-known/oauth-protected-resource` | RFC 9728 metadata linking `/mcp` to its authorization server. |
| `POST /oauth/register` | RFC 7591 dynamic client registration (Claude self-registers a public client). |
| `/oauth/authorize`, `/oauth/token` | Doorkeeper authorization + token endpoints (PKCE S256 required). |

## Adding it on claude.ai

1. Deploy this app (the connector must be reachable over the public internet —
   Claude connects from Anthropic's cloud, not your browser).
2. In claude.ai: **Settings → Connectors → Add custom connector**.
3. Enter the MCP URL: `https://<your-host>/mcp`
4. Leave OAuth Client ID/Secret blank — Claude registers itself automatically via
   dynamic client registration.
5. Click **Add**, then **Connect**. Claude sends you to this app's sign-in page;
   log in as an **owner** and approve. Claude then completes the PKCE flow and the
   tools become available.

Claude Desktop / Code use the same URL; they perform the same OAuth flow with a
loopback redirect.

## Deploy notes

- Run migrations on deploy — the connector needs the `oauth_*` tables
  (`CreateDoorkeeperTables`).
- Token lifetime is 2 hours with refresh tokens (see
  `config/initializers/doorkeeper.rb`).
- The discovery metadata is built from the request host/scheme, so the app must
  see its real external host (it does behind Thruster/Kamal via forwarded headers).
- To revoke access, delete the relevant `Doorkeeper::Application` (and its tokens)
  in the console: `Doorkeeper::Application.find_by(name: "...").destroy`.

## Relationship to the REST API

The REST API (`/api/v1/*`, single bearer token) still exists and is the simplest
way to drive the same resources from **Claude Code / scripts**. The MCP connector
is specifically what makes claude.ai on the web work. Both share the resource
definitions and `Api::RecordSerializer`.
