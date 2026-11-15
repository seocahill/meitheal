# Decisions

The owner's yes/no decisions on proposals, newest first. The architect reads
this every run so it learns what the owner wants and doesn't re-propose
rejected ideas. The architect appends entries from issue activity (approved =
`approved` label; rejected = closed with `rejected` label and the owner's
one-line reason as the last comment). The owner can also edit this file
directly to state standing preferences.

## Standing preferences

- Meitheal has real users and takes real money, so be conservative: improve
  steadily, ship small, and keep anything members can see behind a flag.
- Autopilot (owner, 2026-11-15): the architect proposes, the builder builds,
  merges on green CI and the site deploys. Visible changes ship dark behind a
  Flipper flag for the `owners` group; the owner switches flags on. Only the
  tier 3 items in `ARCHITECT.md` §6 wait for the owner's yes.
- Fixing: the nightly watchdog turns breakage (Sentry errors, a red `main`, a
  down site, vulnerable gems) into `auto` issues labelled `regression` or
  `security`, and the builder fixes those before anything else. There is no
  separate fixer.
- Pace: steady, not hectic. A few good changes a week beats many.
- Dependencies: patch and minor bumps merge on green (Dependabot's
  auto-merge workflow already handles non-major). Major bumps are prepared by
  the builder; dev/test-only and GitHub Actions majors merge if the suite is
  green, everything else waits for the owner's review.

## Log

<!-- - YYYY-MM-DD #<issue> <title> — approved | rejected: <reason> -->
