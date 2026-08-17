# Plan — Personal Planner PWA (Rails), v1

## Context

Bastien wants a personal-use PWA (installable on Android) to plan his days/weeks: goals
(daily/weekly, with simple gamification), a single place for appointments, task timers to help
future planning, and shopping lists. Requirements were captured in `SPEC.md` and refined with
him via clarifying questions (streak = ALL scheduled goals must be done to count the day/week;
points are a fixed amount per goal; recurring goals are matched by identical title rather than a
template/instance system; hosting choice deferred). This is greenfield — no existing codebase.
Environment check: Ruby 3.3.6 present, Rails not yet installed, Node v22 present but not
required. Single private user, no auth, no external services beyond Web Push.

## Recommended approach

**Stack:** Rails 8.1.3.1 (latest stable), SQLite (via the `sqlite3` gem — no system CLI needed),
Solid Queue for recurring background jobs (Rails 8's zero-infra default, no Redis/Postgres
needed — fits a small personal app), Tailwind CSS (`--css=tailwind`, vendors its own binary, no
Node build pipeline needed), Turbo + Stimulus via importmap (no JS framework, no bundler),
`webpush` gem for Web Push notifications. This keeps the whole stack self-contained in SQLite
files, easy to run locally and move to any host later.

```bash
gem install rails -v 8.1.3.1
rails new planner --database=sqlite3 --css=tailwind --javascript=importmap \
  --skip-action-mailbox --skip-action-text --skip-action-cable --skip-jbuilder
```

**No `User` model** — single private user, so no auth and no `user_id` foreign keys anywhere.
This simplification applies throughout.

### Data model

- **`Goal`**: `title`, `description`, `frequency` (`daily`/`weekly`), `recurring:boolean`,
  `scheduled_on:date` (one-off goals), `active_from:date` (recurring goals),
  `archived_at:datetime` (soft-stop a recurring goal), `current_timer_started_at:datetime`
  (timer in progress), `position`.
- **`GoalCompletion`**: `goal_id`, `occurred_on:date`, `completed_at`, `started_at`,
  `duration_seconds`, `points_awarded` (snapshot of the points setting at completion time).
  Unique index on `[goal_id, occurred_on]` — this is the per-occurrence log that lets a single
  recurring `Goal` row represent every day/week without duplicating goal rows.
- **`Appointment`**: `title`, `starts_at`, `location`, `notes`, `reminder_lead_minutes`
  (nullable override), `reminder_sent_at` (dedup guard).
- **`ShoppingList`** (`name`, `position`) `has_many :shopping_list_items`.
- **`ShoppingListItem`**: `shopping_list_id`, `name`, `checked:boolean`, `position`.
- **`PushSubscription`**: `endpoint` (unique), `p256dh_key`, `auth_key`, `user_agent` — one row
  per device/browser the PWA is installed on; pushes fan out to all rows.
- **`Setting`** (singleton via `Setting.instance`): `points_per_goal` (default 10),
  `default_appointment_lead_minutes` (default 30), `daily_goal_reminder_time` (default 18:00),
  `daily_goal_reminder_sent_on` (dedup guard).

### Streak logic (highest-risk custom logic — gets the most test coverage)

`Goal.scheduled_on(date)` / `Goal.scheduled_in_week(week_start)` scopes return the goals due
that day/week (recurring goals active and not archived, or one-off goals matching that exact
date). `StreakCalculator` walks backward from today/this-week one unit at a time:
- A day/week with **zero** scheduled goals is skipped (neutral — doesn't break or extend the
  streak).
- A day/week where every scheduled goal has a matching `GoalCompletion` counts; the first day/
  week with any incomplete scheduled goal stops the walk.
- **Today is special-cased**: if today isn't finished yet, the "current streak" number is
  computed as of yesterday (an in-progress day never shows as "broken"); the UI shows today's
  live progress (`X/Y done`) separately. Today only joins the streak once fully complete.

`Goal#average_duration` (for the timer feature) matches by **title**, not `goal_id`, per the
spec wording — this also covers ad-hoc one-off goals a user retypes with the same title on
different days, not just true recurring goals.

Points total: `GoalCompletion.sum(:points_awarded)` — simple aggregate, no separate service.

### Web Push

`webpush` gem; VAPID keys generated once (`WebPush.generate_key`) and stored in Rails encrypted
credentials; public key exposed to the frontend via a meta tag. A Stimulus controller handles
the "Enable notifications" button → `pushManager.subscribe` → POST to `/push_subscription`.
Rails 8's generated `app/views/pwa/service-worker.js` gets `push`/`notificationclick` handlers
added. Two jobs, registered in `config/recurring.yml` (Solid Queue, every 5 min):
`AppointmentReminderJob` (pushes for appointments starting within their lead window, sets
`reminder_sent_at`, prunes expired subscriptions on 404/410) and `DailyGoalReminderJob` (once/day
summary push for incomplete goals, guarded by `daily_goal_reminder_sent_on`).

### PWA

Build on Rails 8's generated `app/views/pwa/manifest.json.erb` and `service-worker.js` rather
than from scratch: set name/icons/theme colors/`display: standalone`, add 192×192 and 512×512
maskable icons, confirm service-worker registration is wired in `app/javascript/application.js`.

### Routes / controllers / views

Combined day view at `/` and `/days/:date` (`DaysController#show` — goals + appointments
interleaved, sorted by time, per the "one combined view" requirement), week view at
`/weeks/:date`. `GoalsController` (CRUD + `complete`/`start_timer`/`stop_timer` member actions,
carrying an `occurred_on` param so the same recurring `Goal` row can be completed per-day/week).
`AppointmentsController`, `ShoppingListsController`/`ShoppingListItemsController` (fully
decoupled from gamification — verified by an explicit test), `PushSubscriptionsController`,
`SettingsController`. Turbo Frames/Streams for in-place checkbox toggling; plain ERB + Tailwind
otherwise, no SPA framework.

## Task breakdown (implementation order)

Each task is a small, independently-verifiable step. Full numbered breakdown (36 tasks) covers:
**Phase 0** scaffold + webpush gem + VAPID keys → **Phase 1** `Goal`/`GoalCompletion` models +
scopes → **Phase 2** day view + complete/uncomplete → **Phase 3** `Setting` + points +
`StreakCalculator` (with dedicated unit tests) + summary bar → **Phase 4** timer + average
duration → **Phase 5** week view + weekly streak → **Phase 6** `Appointment` CRUD + combined-view
rendering → **Phase 7** shopping lists (with a test asserting zero interaction with points/
streak) → **Phase 8** settings UI → **Phase 9** PWA manifest/icons/service-worker registration →
**Phase 10** Web Push (subscription flow, service worker handlers, both reminder jobs + job
tests) → **Phase 11** system tests for the two or three main flows, streak edge-case tests, and a
short local-run README.

This maps directly onto the task-list phases already tracked (scaffold → goals/gamification →
appointments → notifications → tests/review) and will be executed incrementally, each step
committed and verified before moving to the next — no big-bang implementation.

## Testing approach

Minitest (Rails default) with `travel_to`/`freeze_time` for anything time-dependent (streaks,
reminders, timers — most of this app's interesting behavior). Priority: (1) `StreakCalculator`
unit tests covering all-complete/one-incomplete/zero-scheduled/in-progress-today/goal-archived-
mid-streak/goal-started-mid-streak cases, (2) model validations and the `GoalCompletion` unique
index, (3) `average_duration` for both recurring and ad-hoc-same-title cases, (4) job tests with
`WebPush.payload_send` stubbed (never hit the real push service in tests) asserting exactly-once
delivery and correct dedup-guard updates, (5) request tests confirming shopping lists never touch
`GoalCompletion`/points, (6) a thin layer of system tests for the highest-value flows.

## Verification (end-to-end)

- `bin/rails test` and `bin/rails test:system` green after each phase.
- `bin/rails server` + `bin/jobs` (Solid Queue runner) running locally; manually walk through:
  create a recurring daily goal, complete it today, see points/streak update on `/`.
- Manually trigger `AppointmentReminderJob.perform_now` via `bin/rails runner` against a seeded
  appointment and a `PushSubscription` created by actually clicking "Enable notifications" in a
  real browser — confirm an OS-level push notification appears.
- Chrome DevTools → Application panel: confirm manifest has no errors and the service worker is
  registered/activated (installability check for the Android PWA use case).

## Critical files

- `app/models/goal.rb` — recurrence scopes, `average_duration`
- `app/models/goal_completion.rb` — per-occurrence log replacing a template/instance system
- `app/models/streak_calculator.rb` — highest-risk custom logic, most heavily tested
- `config/recurring.yml` — Solid Queue recurring job schedule
- `app/views/pwa/service-worker.js` — push/notificationclick handlers
- `app/jobs/appointment_reminder_job.rb`, `app/jobs/daily_goal_reminder_job.rb`
