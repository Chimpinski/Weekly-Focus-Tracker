# Weekly Focus Tracker — Handoff

## What it is
A personal time-tracking web app. You define objectives (e.g. "Linear Algebra course, 5h/week"), start/pause a timestamp-based timer per objective, and watch progress toward weekly (or daily) goals. It's a single static HTML file that's also an installable PWA and is wrapped into an unsigned iOS `.ipa` for sideloading.

- **Repo:** https://github.com/Chimpinski/Weekly-Focus-Tracker (public, default branch `main`)
- **Live PWA:** https://chimpinski.github.io/Weekly-Focus-Tracker/ (GitHub Pages, serves `main` root)
- **Local working dir:** `C:\Users\alial\OneDrive - UW\Claude`
- **Current version:** v1.5.0
- **Git identity:** user "Ali", pushes over HTTPS via Git Credential Manager (already authenticated)

## Tech stack & structure
No framework, no build step. Everything is hand-written HTML/CSS/vanilla JS.

- `index.html` — the **entire app** (~3,200 lines): all markup, CSS in one `<style>`, logic in one IIFE `<script>`. This is where ~all work happens.
- `sw.js` — service worker. **Network-first for the page** (so updates reach installed PWAs), cache-first for assets. Bump the `CACHE` const (currently `"wft-v8"`) on each release.
- `manifest.webmanifest`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` — PWA install assets.
- `assets/icon.png` — 1024px source icon; CI generates native app icons from it.
- `capacitor.config.json` — `appId: com.chimpinski.weeklyfocus`, `appName: "Focus Timer"`, `webDir: "www"`, `ios.contentInset: "never"`, `backgroundColor: "#101615"`.
- `package.json` — version + Capacitor 6 deps (`@capacitor/core`, `@capacitor/ios`, `@capacitor/cli`, `@capacitor/assets`).
- `.github/workflows/build-ipa.yml` — CI that builds the `.ipa` and publishes the release.
- `README.md`, `CHANGELOG.md`, `docs/preview-*.png` (3 same-size README previews).
- `.gitignore` — ignores `node_modules/`, `/ios/`, `www/`, `dist/`, `*.ipa`, `.claude/settings.local.json`, `.claude/launch.json`.

### Data model (all in `localStorage`)
Main key `weekly-focus-timer-v1` holds one `state` object:
- `weekStart` (Monday key), `userName`, `updatedAt` (monotonic ms — drives last-write-wins sync)
- `objectives[]`: `{id, name, cadence:"weekly"|"daily", goalSeconds, dailyGoalSeconds, spentSeconds, daySpentSeconds, dayKey, running, startedAt, celebratedWeekly, celebratedDaily, totalGoalSeconds, totalSpentSeconds, celebratedTotal, totalStartKey}`
  - `totalGoalSeconds` (0 = not a limited task), `totalSpentSeconds` = **cumulative** time toward the total (incremented wherever `spentSeconds` is, but **never** reset by the weekly rollover), `celebratedTotal` guards the completion popup, `totalStartKey` = dayKey the total began/was last cleared (shown as "since …").
- `dailyLog: {dayKey: seconds}` — total tracked per calendar day; powers the month grid, stats, and streak
- `weekHistory: {mondayKey: {objectives:[{name,goalSeconds,spentSeconds}], goalTotal, spentTotal}}` — snapshot taken at each weekly rollover
- `excludeWeekends` (bool), `streakMilestone` (highest celebrated), `celebratedWeekTotal` (bool)
- `pomodoro: null | {id, focusSec, breakSec, hasTotal, totalFocusRemaining, phase, phaseStartedAt, phaseEndsAt}`
- `backups: [{ts, dayKey, weight, data}]` — rolling dated snapshots (one/day, cap 14) that **ride along inside the synced state**; `data` is a full state minus its own `backups` (no recursion) and minus the live timer. `lastDestructiveAt` (ms) — set by `markDestructive()` on intentional reductions (delete objective, reset time, subtract, clear total) so those legitimately sync.
- Separate localStorage key `weekly-focus-timer-lkg` — an on-device **last-known-good** copy (a `snapshotOf(state)`), written on each non-empty `save()` and never downgraded unless the reduction was intentional.

Separate keys: `wft-theme` (`system|light|dark`), `wft-progress` (`bar|ring`), `wft-sync-code` (`WFT-XXXX-XXXX-XXXX`).

There's a `migrate()` run on load and after adopting synced state that backfills any new fields, so adding fields is safe.

## Features
- Objectives with **weekly or daily** goals; daily ones get a "Daily" tag and reset at midnight. Weekly objectives can carry an optional **daily sub-goal** (second bar).
- Per-task **Begin/Pause** timers, timestamp-based (survive refresh/close, one runs at a time). Manual **+ Log time** (add/subtract).
- Live countdown, % of goal, **bar or ring** progress; past 100% a green **count-up timer + "Goal met!"** badge.
- **Weekly summary** that caps each objective at its goal (overflow doesn't inflate the total). Auto weekly reset (Mon) + daily reset (midnight).
- **Celebrations:** popup on completing an objective or the whole week; daily goals glow instead.
- **Cross-device sync, no account** (see tradeoffs). **Onboarding** (name + tutorial) and **Settings** (name, theme, progress style, weekend rule, sync).
- **Progress history:** per-week achievement tracker, GitHub-style monthly activity grid (day shading, selected-week highlight, month nav moves the week), and a **Stats** view (8-week bar chart + table).
- **Streaks:** header flame (lights after 15 min/day), popup with the week's day circles, milestone celebrations, optional "skip weekends".
- **Pomodoro mode:** focus/break cycles with optional total focus time; only focus counts toward the goal; completion popup.
- **Total objective time (limited tasks):** optional `totalGoalSeconds`; right-side `.total-panel` on the card with a small full-circle ring (`TR_R`/`TR_C`, % inside) + "Xh left / of Yh / since …"; completion fires a **"Task complete"** announcement then a congrats popup (`#total-overlay`) with **Clear & start fresh** (commits time, zeros the total, restarts `totalStartKey` today).
- **Full-screen task view:** per-card expand button toggles `fullscreenId`; `render()` shows only that card and sets `body.fs-mode`, which hides header/summary/footer/FAB and enlarges the card (works for normal and pomodoro cards). Exit via the button or Escape.
- **Sound + announcements:** synthesized **WebAudio** stopwatch beeps (`playStopwatchBeeps` — 2 beeps × 3, no asset files) plus a full-screen glowing word (`#announce-overlay`, `showAnnouncement`). Pomodoro focus↔break shows **BREAK/FOCUS** for ~2.4s (via `pomoAnnouncing` guard) before the next block starts; daily/weekly goals and total completion announce without stopping a running timer. Celebrations now run through one sequential `eventQueue` (`enqueueAnnounce`/`enqueueCelebration`/`enqueueTotalComplete`). Audio is unlocked on first gesture (`unlockAudio`).
- **Backups & restore (Settings):** `#restore-overlay` lists restore points (on-device LKG + in-state snapshots) with dates + a `summarizeSnap` line; two-tap confirm restores via `restoreSnapshot` (bumps `updatedAt` so the restore wins sync). "Back up now" forces a snapshot. See the sync hardening under Key decisions.

## Key decisions & tradeoffs
- **Single-file vanilla JS, no build** — keeps it trivially hostable as static and easy to wrap in Capacitor. Downside: `index.html` is large; keep functions cohesive.
- **Sync backend = textdb.online** (a free, no-signup, CORS-open key-value store). Chosen after testing ~5 services; others lacked CORS or required accounts/captchas. Sync uses a random code `WFT-XXXX-XXXX-XXXX`; the key is `"wft" + code-without-dashes, lowercased`. POSTs are form-encoded to avoid a CORS preflight. Automatic resets use a `persistLocal()` that does **not** bump `updatedAt`, so devices don't fight over deterministic resets. Tradeoffs: it's a free community service (retention not guaranteed) and the code is the only secret (treat like a password).
- **Sync arbitration is a pure function `resolveSync(local, remote) → {action:"adopt"|"reseed"|"noop", state?}`** (v1.5.0), so it's unit-testable without the network. It's last-write-wins on `updatedAt` **except** it will not adopt a copy that wipes or sharply shrinks history (empty `dailyLog`/`weekHistory`/objectives, or `dataWeight` more than halved) unless the reduction was intentional (`remote.lastDestructiveAt > local.lastDestructiveAt`). On such a "reseed", it also bumps local `updatedAt` above the rejected remote so the accidental wipe can't keep winning. **This exists because v1.4.0-era sync wiped everyone's progress** when the server returned an objectives-intact-but-progress-zeroed copy with a newer timestamp. `dataStats`/`dataWeight` measure *durable* history (cumulative `totalSpentSeconds`, `dailyLog`, `weekHistory`, streak) and deliberately ignore weekly `spentSeconds`, which resets every Monday. Don't "simplify" this back to plain last-write-wins.
- **Redundancy:** rolling in-state `backups` + on-device LKG + a boot-time regression check (`checkBootRecovery`) that offers a restore. `adoptRemoteState` merges backups from both sides and stashes a pre-adopt snapshot so an adopt/connect is always reversible from Settings › Backups.
- **Streak derived from `dailyLog`**, not a stored counter — robust across sync and time changes.
- **iOS Live Activity was built (v1.1.1) then removed (v1.2.0)** because signing services (you use **Signulous**) reject the required app extension. The native Swift/widget files were deleted but **still exist in git history** (harmless, not built). Don't re-add app extensions.
- iOS full-bleed handled via `viewport-fit=cover` + safe-area insets; inputs are 16px and zoom is disabled so iOS doesn't zoom on focus.

## Known issues / unfinished
- README `docs/preview-*.png` predate the streak/progress header buttons — slightly stale; regenerate when convenient.
- `dailyLog`/`weekHistory` grow unbounded (tiny for personal use; never pruned).
- Sync is last-write-wins for *genuine* concurrent edits — two devices editing different things offline can still lose one side's changes on next sync (the v1.5.0 guards only protect against wipes/regressions, not legitimate divergent edits).
- textdb.online retention is not guaranteed — but a lost/reset server value can no longer wipe devices (guarded), and any device with data re-seeds it. Full local copies + backups remain the safety net.
- All minute inputs now step by 1 (as of v1.4.0; previously log/goal/pomodoro-focus minutes were constrained to multiples of 5). Any whole number is accepted.
- The total panel is hidden while an objective is in Pomodoro mode (the pomodoro card is its own focused layout); it returns when the pomodoro ends.

## Environment note for verification
In this environment the **in-app browser-pane screenshot tool times out** — don't rely on it. Verify functionally via JS eval / DOM inspection, and for **visual** checks use **headless Edge** (this works):
`"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless=new --disable-gpu --no-sandbox --no-first-run --user-data-dir=<fresh temp profile> --hide-scrollbars --force-device-scale-factor=2 --virtual-time-budget=2500 --window-size=W,H --screenshot=out.png <url>` — serve the dir with `python -m http.server`, and inject a small seed `<script>` into `<head>` to prime `localStorage`/open a modal for the shot. Poll for the output file (Edge's launcher returns before the render finishes).

## Building the unsigned IPA (exact)
**You cannot build on Windows** — it's macOS/Xcode only. It's done entirely in CI:

- Workflow: `.github/workflows/build-ipa.yml`, runs on **`macos-14`**.
- **Triggers:** pushing a tag matching `v*`, or manual `workflow_dispatch`.
- **Steps:** checkout → setup Node 20 → assemble web assets into `www/` (`cp index.html manifest.webmanifest sw.js icon-192.png icon-512.png apple-touch-icon.png www/`) → `npm install` → `npx cap add ios` → `npx capacitor-assets generate --ios` (icons from `assets/icon.png`) → `npx cap sync ios` → **unsigned** `xcodebuild` → package → upload artifact → build release notes from CHANGELOG → attach to GitHub Release.
- **Unsigned build config** (the crucial part): `xcodebuild -workspace ios/App/App.xcworkspace -scheme App -configuration Release -sdk iphoneos ... MARKETING_VERSION="$MV" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""`. No certs, no provisioning profile. `MV` = tag minus the `v`. The `.ipa` is made by zipping `Payload/App.app`. You sign it at install time with Signulous/AltStore/Sideloadly.
- Output asset: `WeeklyFocusTimer-unsigned.ipa` (bundle id `com.chimpinski.weeklyfocus`, min iOS 13).
- **CI YAML gotcha we hit:** a bash heredoc with a column-0 `EOF` inside a `run: |` block breaks YAML (the unindented lines end the literal scalar; `---` reads as a doc separator → "startup_failure" with 0 jobs). Use an **indented `printf` block** instead. If a build shows 0 jobs / the run's name is the raw filename, it's a YAML parse error.

## Updating GitHub after a build (exact)
- **Branch:** always `main`. Only source is committed; `node_modules/ios/www/dist/*.ipa` are gitignored. The `.ipa` is **not** committed — it lives only as a Release asset.
- **Commit style:** subject `vX.Y.Z: short summary` for releases (or an imperative line for fixes), a bulleted body, and always the footer:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- **Releases are tagged.** Cutting a version:
  1. Add a `## [X.Y.Z] - YYYY-MM-DD` section at the top of `CHANGELOG.md` (under _Unreleased_) and update the compare/link lines at the bottom.
  2. Bump `package.json` version, `sw.js` `CACHE` (→ `wft-vN+1`), and the workflow's fallback `MV` default.
  3. Commit + `git push origin main` (fetch/rebase first — the owner sometimes edits the README directly on GitHub, which caused a non-fast-forward we had to rebase past).
  4. `git tag -a vX.Y.Z -m "..."` then `git push origin vX.Y.Z`.
  5. CI builds the `.ipa` and publishes the GitHub Release, auto-extracting that version's CHANGELOG section as the body + a sideload/PWA footer.
  6. Verify: poll the run to `success`, then download the released `.ipa` and confirm version + that new code is present, and that the public download returns HTTP 200.
- To move a tag: `git tag -f` + `git push -f origin vX.Y.Z` (re-triggers the build; the release step clobbers/updates).
- API work (checking runs, backfilling release bodies) uses a token pulled via `printf "protocol=https\nhost=github.com\n\n" | git credential fill`.
- Repo must stay **public** (free GitHub Pages + free macOS CI minutes depend on it).
