# Roadmap

Maintained by the architect (see `ARCHITECT.md`). Owner edits welcome.

## Now (approved / building)

- Feature flags: Flipper with an owner-only `/flipper` (in place; see `docs/feature_flags.md`)
- #210 Dependency security updates: doorkeeper and net-ssh (builder, PR #212)
- #216 Show owners SumUp payments Meitheal has no record of (tier 2, ships dark)

## Next (proposed, awaiting decision)

- #213 Make payment completion idempotent (tier 3; re-opening the link renews again)
- #214 Settle SumUp checkouts server-side, stop deleting pending payments (tier 3)
- #215 Renewal reminder emails before the 31 December expiry (tier 3; folds in part of #70)

## Later (ideas not yet worth a proposal)

- Booking debt reminders and matching incoming bank payments to bookings (rest of owner backlog #70)
- Booking collision resolution by asking the existing booker to share (owner backlog #69)
- Emailed receipts for membership payments

## Lens log

| Week of | Lens | Proposals |
|---|---|---|
| 2026-11-22 | 1. Membership and payments | #213, #214, #215, #216 |
