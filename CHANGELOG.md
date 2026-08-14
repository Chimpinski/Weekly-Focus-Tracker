# Changelog

All notable changes to Weekly Focus Tracker are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/), and this
project uses [semantic versioning](https://semver.org/).

> **Releasing:** add the new version's notes under a `## [x.y.z] - YYYY-MM-DD`
> heading at the top (below _Unreleased_), then push a matching `vx.y.z` tag.
> CI copies that section into the GitHub Release automatically.

## [Unreleased]

_Nothing yet._

## [1.6.0] - 2026-08-14

### Added
- **Notifications — off by default, with a switch for each kind.** Turn them on in Settings › Notifications:
  - **Daily goal reminder** at a random point in the day. If several goals are still short you get **one** notification listing them all, with how much time is left on each — never one per goal. It stays quiet when you've already hit everything.
  - **Weekly nudge** — a line of encouragement at a different day and time each week.
  - **Forgot to pause** — a heads-up if you leave the app with a timer still running, so you don't come back to hours you didn't work. It doesn't fire during a Pomodoro, which pauses itself.
  - **Away alerts** — when you're out of the app, hear about it the moment a daily, weekly, or limited-task goal is reached, or when Pomodoro switches between focus and break.
- **Quiet hours.** Reminders are only sent inside a window you set (9 AM–9 PM by default).

### Changed
- The Settings sheet now scrolls inside itself instead of growing past the bottom of the screen, so **Done** stays reachable on a phone.

### Notes
How much of this reaches you depends on where the app is running, and Settings says so plainly:

| | Sideloaded `.ipa` | iPhone Home-Screen app | Desktop / Android browser |
|---|---|---|---|
| Daily reminder | with the app closed | only while open | only while the tab is open |
| Weekly nudge | with the app closed | only while open | only while the tab is open |
| Forgot to pause | 2-minute grace, cancels if you return | sent **as you leave** instead | 2-minute grace |
| Goal / Pomodoro away alert | exact | not possible | yes, up to ~1 min late |

On iPhone the web app must be **added to the Home Screen** (iOS 16.4+) to have notifications at all — a plain Safari tab has none. The sideloaded `.ipa` is the only build that can reach you with the app fully closed; iOS freezes backgrounded web pages, and the web has no way to schedule a notification for later.

## [1.5.1] - 2026-07-28

### Fixed
- **Opening the app on a second device could wipe your latest progress.** A device that had been idle would, on open, run its weekly rollover and push that (stale, reset) copy to the server *before* fetching the newer data — stamping the old copy as "newest" and overwriting the time you'd just tracked elsewhere. The app now **pulls and reconciles with the server first**, and only then rolls over, snapshots, or pushes. Same order when returning to the app after it's been in the background. No more needing to restore a backup after switching devices.

## [1.5.0] - 2026-07-26

### Fixed
- **Sync could wipe your history.** A copy of your data with the objectives intact but the progress emptied (from the free sync server losing/resetting a value) could win the last-write-wins race and blank out every device — logged time, streak, and past weeks. Sync now refuses to accept a copy that erases or sharply shrinks your history (daily log, past weeks, logged time, or objectives) unless it's a change you actually made. The richer copy is kept and re-shared, so an accidental wipe can no longer propagate.

### Added
- **Automatic backups tied to your sync code.** Your history is snapshotted about once a day; the snapshots travel with your sync code and there's also an on-device "last known good" copy — so your data follows you across updates and reinstalls as long as you keep your code.
- **Backups & restore** in Settings: browse restore points (with dates and a summary of each) and roll back with two taps. If the app ever opens missing history it had before, it now offers to restore it automatically instead of silently losing it.

## [1.4.0] - 2026-07-26

### Added
- **Total objective time.** When creating (or editing) an objective you can now mark it a *limited task* and set the whole amount of time you're aiming to spend — e.g. a 90-hour course. A panel on the right of the card shows a small ring with your completion percentage inside it, plus how much time is left of the total. Finishing the whole thing pops a **congratulations** dialog with an option to **clear & start fresh** from that day.
- **Full-screen a task.** Each task has a full-screen button that hides everything else and shows just that timer, enlarged and spread out for an at-a-glance focus view. Exit with the button or Escape.
- **Sound + on-screen cues.** A stopwatch-style beep (two beeps, three times) now plays with a big glowing word for key moments. Pomodoro shows **BREAK** / **FOCUS** for a few seconds — beeping and glowing in time — before the next block starts. Finishing a daily/weekly goal shows **DAILY/WEEKLY GOAL ACHIEVED**, and completing a limited task's total shows **TASK COMPLETE**, all without stopping a running timer.

### Changed
- **Log time in any whole minute.** Time fields (manual log, goals, and Pomodoro focus/total) now accept any whole number of minutes instead of only multiples of 5.

### Fixed
- On smaller phones (e.g. iPhone 13) the card action buttons now wrap instead of the Pomodoro button spilling outside the card.

## [1.3.1] - 2026-07-10

### Changed
- The streak number now looks engraved into the flame instead of sitting on top of it.
- Pomodoro focus length now steps in clean multiples of 5 (25, 30, 35, …) instead of rejecting values like 25.
- Simplified the streak popup description ("keep your streak alive").

## [1.3.0] - 2026-07-10

### Added
- **Progress history.** A new Progress button opens a tracker where you can look back at any past week — total percentage and per-goal breakdown — so a Monday reset no longer feels like losing everything. It includes a GitHub-style **monthly activity grid** (each day shaded by how much you tracked), with the selected week highlighted; moving between months moves the weekly view with it. A **Stats** view charts hours tracked over the last eight weeks with a supporting table.
- **Streaks.** A flame in the header lights up once you've tracked at least 15 minutes for the day and grows your day count. Tap it for a popup with your streak number and this week's days. Milestone celebrations fire at 3, 5, 7, 10, 14, 30, 50, 100+ days. A setting lets you **skip weekends**, so not working Saturday/Sunday won't break your streak.
- **Pomodoro mode.** Start a focus/break cycle on any objective: set your focus and break lengths and an optional total focus time. The card becomes a Pomodoro card with the current phase timer, a total-time-left readout, and a "Focus!" / "Enjoy your break" label; it flashes when phases switch. Only focus blocks count toward your goal, and finishing your total time shows a "Focus session complete" celebration.

## [1.2.1] - 2026-07-08

### Added
- **Daily or weekly goals per objective.** A daily objective shows a `Daily` tag and resets at midnight. A weekly objective can also carry an optional **daily sub-goal**, shown as a second progress bar.
- **Completion celebrations.** A congratulations popup when you finish an objective or your entire week; daily goals glow briefly instead of interrupting.
- **Third preview** in the README showing the cross-device sync panel; added the app icon to the page.

### Changed
- Past 100%, a card now shows a smaller green **count-up timer** with a **"Goal met!"** badge instead of a static label.
- The **weekly total caps each objective at its goal**, so time logged past one goal no longer inflates the week's percentage.
- Redesigned the add/edit form: objective name on its own line, a Weekly/Daily toggle, then grouped Hours/Minutes fields.
- Sync-code entry now shows a fixed `WFT-` prefix, auto-uppercases, auto-inserts dashes, and stops at 12 characters.
- Expanded the rotation of greetings and motivational quotes.

## [1.2.0] - 2026-07-08

### Added
- **Cross-device sync with no account.** Create a sync code on one device and enter it on another to see the same timers — even a running one. Last-write-wins; the code is the only key to your data.
- Sync controls in Settings and on the first-run screen.

### Removed
- The iOS Live Activity feature (from 1.1.1). Sideloading/signing services reject the required app extension, so it was removed to keep the `.ipa` installable.

## [1.1.1] - 2026-07-08

### Added
- **iOS Live Activity** (lock screen / Dynamic Island) showing the running objective, a live countdown, a goal-progress bar, and an interactive pause/play button, themed to match the app icon. _(Removed in 1.2.0 — see above.)_

## [1.1.0] - 2026-07-07

### Added
- **First-run onboarding** that asks your name and shows a short tutorial; the greeting then uses your name.
- **Settings** gear to change your name, theme (system / light / dark), and progress style (bar or ring).
- The weekly-total summary can now display as a ring as well as a bar.

### Changed
- **Full-bleed layout** with safe-area insets — no more black bars at the top and bottom on notched iPhones.
- Larger, touch-friendly form inputs; number fields open the numeric keypad.
- The service worker is now network-first for the page, so updates reach installed apps.

### Fixed
- Disabled pinch and double-tap zoom, and set inputs to 16px so iOS no longer zooms when a field is focused.

## [1.0.0] - 2026-07-07

### Added
- Objectives with weekly time goals and per-task **Begin / Pause** timers (timestamp-based, so they survive refreshes and closed tabs; one runs at a time).
- Manual time logging to add or subtract hours and minutes.
- Live remaining-time countdown, percentage of goal, and a progress bar that turns green at the goal.
- Weekly summary of time logged vs. planned, with an automatic reset every Monday.
- Light and dark themes; all data stored locally in the browser.
- Installable PWA (web manifest, app icons, offline service worker).
- An unsigned `.ipa` attached to the release for personal sideloading.

[Unreleased]: https://github.com/Chimpinski/Weekly-Focus-Tracker/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.6.0
[1.5.1]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.5.1
[1.5.0]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.5.0
[1.4.0]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.4.0
[1.3.1]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.3.1
[1.3.0]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.3.0
[1.2.1]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.2.1
[1.2.0]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.2.0
[1.1.1]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.1.1
[1.1.0]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.1.0
[1.0.0]: https://github.com/Chimpinski/Weekly-Focus-Tracker/releases/tag/v1.0.0
