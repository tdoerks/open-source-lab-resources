# 📍 Check-in Board

A glanceable office **in/out board** — tap your current status ("In Lab", "At Lunch", "Out / On Leave")
on a tablet, phone, or laptop. Perfect for a small display mounted by your door.

**▶ Use it live:** https://tdoerks.github.io/open-source-lab-resources/checkin-board/

## Use it yourself

- **Just open the link** above — each person who opens it gets their **own private board**, saved in
  their **own browser**. No accounts, no sign-up, nobody sees or overwrites anyone else's status.
- **Run it offline:** download `index.html` and double-click it — it works with no internet, no server.
- **Make it your own:** fork this repo (or copy the folder) and it's live on your own GitHub Pages.

## Features

- Big, color-coded status banner readable across a room.
- Seven statuses: In Lab · In Office · In a Meeting · At Lunch · Off-site/Field · Working Remotely ·
  Out / On Leave.
- Optional short note ("back at 3pm", "back Monday") with quick presets.
- "Last updated" timestamp + a recent check-in history.
- **Colorblind-safe** — every status shows an icon **and** a word, never color alone.
- Large touch targets for tablet/phone; auto-saves in the browser (`localStorage`).
- Backup: export/import the board as JSON.

## Notes

- **Single-device by design (v1).** Your status lives in the browser you tapped it on — it is *not* a
  shared board that others watch remotely, and it doesn't sync between your phone and the tablet. That's
  what makes it safe for anyone to use their own copy.
- **Optional cross-device sync (planned).** A later version can commit your status to a repo via the
  GitHub API so your phone updates the tablet and visitors see it live — the Settings panel is already
  stubbed for it.

*Single self-contained HTML file — no build step, no dependencies, no server.*
