# Feature flags (Flipper)

Anything a member, editor or visitor can see or feel ships behind a flag, off by default.

- **Naming:** `f<issue-number>_<slug>`, e.g. `f12_booking_calendar`.
- **Check in code:** `Flipper.enabled?(:f12_booking_calendar, Current.user)` in a controller, view or helper. Always make the code work with the flag on and off. Signed-out visitors have no user, so a flag enabled only for the `owners` group is off for them; enable it for everyone to show it on public pages.
- **Register it:** add a migration in the same PR that calls `Flipper.add(:f12_booking_calendar)` (and `Flipper.remove` in `down`). Flipper only lists features it knows about, so without this the flag does not appear, switched off, in `/flipper`.
- **Turn on:** owners open `/flipper` (owner only; anyone else gets a 404). Enable the flag for the `owners` group first and try it live, then for named users, a percentage of users, or everyone.
- **In tests:** Flipper uses an in-memory adapter (`config.flipper.test_help`). Enable with `Flipper.enable(:f12_booking_calendar)` and test both on and off; state resets between tests.
- **Delete a flag** once it is on for everyone and stable: remove the checks from code, then remove the flag in `/flipper`.
