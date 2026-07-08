# Weekly Focus Tracker

A single-file web app for tracking time spent on the objectives you care about, measured against weekly goals.

## Preview

| Dark theme · bar progress | Light theme · ring progress |
| :---: | :---: |
| ![Dashboard in dark mode showing objectives with linear progress bars](docs/preview-dark.png) | ![Dashboard in light mode showing objectives with circular progress rings](docs/preview-light.png) |

Toggle between the two progress styles and light/dark themes right from the header.

## Features

- **Objectives with weekly goals** — give each objective a name and a target time for the week (e.g. "Linear Algebra course, 5 hours").
- **Per-task timer** — press **Begin task** to start tracking, **Pause** to stop. Only one timer runs at a time, so time is never double-counted. Timers are timestamp-based, so they keep counting correctly across refreshes and closed tabs.
- **Manual logging** — forgot to start the timer? Use **+ Log time** to add (or subtract) hours and minutes by hand.
- **Live progress** — each objective shows a countdown of remaining time, percentage of goal, and a progress bar that turns green when the goal is met.
- **Weekly summary** — a combined view of total time logged vs. planned across all objectives.
- **Automatic weekly reset** — goals stay, logged time zeroes out every Monday.
- **Local & private** — all data is stored in your browser via `localStorage`. Nothing is sent anywhere unless you turn on sync.
- **Cross-device sync, no account** — create a sync code on one device and enter it on another; both show the same timers (even a running one). The code is the only key to your data, so treat it like a password.
- **First-run setup** — asks your name and walks you through creating your first objective, then greets you by name.
- **Settings** — change your name, theme (system / light / dark), and progress style (bar or ring) from the gear menu.
- **Installable** — works as a full-screen home-screen app on iOS/Android (PWA), and every [release](https://github.com/Chimpinski/Weekly-Focus-Tracker/releases) ships an unsigned `.ipa` for sideloading.

## Live app

**▶ [chimpinski.github.io/Weekly-Focus-Tracker](https://chimpinski.github.io/Weekly-Focus-Tracker/)**

Open it in any modern browser — no build step, no dependencies. You can also just open `index.html` from disk.

## Install on your iPhone (or Android)

This is an installable Progressive Web App, so you can run it like a native app without the App Store:

1. Open the [live app](https://chimpinski.github.io/Weekly-Focus-Tracker/) in **Safari** on your iPhone.
2. Tap the **Share** button, then **Add to Home Screen**.
3. Launch it from your home screen — it runs full-screen with its own icon and works offline.

Your logged time is stored on the device, so keep using the same installed app to preserve your history.
