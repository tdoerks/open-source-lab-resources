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

## Cross-device sync (optional)

By default the board is single-device — your status lives in the browser you tapped it on. Turn on **sync**
and your phone can update the board while the tablet (and any visitor) sees it live.

**How it works:** the board reads and writes a shared `status.json` in your GitHub repo via the GitHub API.
Devices poll it (~45s) and adopt the newest status. It's a **single shared board** — your phone and tablet
show the same thing.

**Set it up (once):**
1. Make a **fine-grained GitHub token**: GitHub → *Settings → Developer settings → Fine-grained tokens →
   Generate*. Repository access: **only this repo**. Permissions: **Contents → Read and write**.
2. Open the board → **⚙️ Settings → Cross-device sync**. The owner/repo/path autofill on GitHub Pages —
   just paste the token → **Save & connect** (use **Test** to check it first).
3. Repeat on every device that should *update* the board (tablet + phone). A device with **no token** can
   still *view* the live status, just not change it.

The sync pill in the header shows the state: **Local only · Synced · Live (view only) · Sync error**.

**Security:** the token is stored only in that device's browser (`localStorage`, separate from the board
data so it never lands in an Export). Scope it to this one repo's Contents, and revoke it anytime from the
same GitHub page. For a **public** repo this is low-risk; the token only lets someone edit that repo's files.

## Notes

- **Forkers get their own board.** Fork the repo and each fork syncs to its *own* `status.json` with its own
  token — so "anyone can use it themselves" still holds.
- **Last-write-wins.** If two devices tap at once, the later timestamp wins (no merge). Fine for a presence
  board.
- **Without sync** the board is fully self-contained and works offline from `file://`.

*Single self-contained HTML file — no build step, no dependencies, no server.*
