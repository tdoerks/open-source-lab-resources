# Plate Label Printer

A single-page tool for lab staff to print **plate labels** (sample ID + QR code +
date/time stamp) on a DYMO LabelWriter — no DYMO software needed. The plate label
template is baked in.

**Live:** https://tdoerks.github.io/open-source-lab-resources/plate-label-printer/

## How it works
1. **Month & year** — pick them (defaults to today). This forms the ID base
   `{YY}KS{MM}` (e.g. `26KS07`). Change it to print past or future months.
2. **Pick samples** — the standard monthly panel is shown as clickable presets
   grouped by pathogen/suffix. Click the ones you need (or "select all" per group),
   set a quantity, and add them to the batch. A custom-ID builder is there too.
3. **Batch** — review the list, adjust quantities, remove rows.
4. **Preview & print** — the live preview shows exactly what prints. Use the
   rotation buttons and mm nudge to line up with your labels, then print.

The full sample ID is `{YY}KS{MM}{TYPE}{NN}-{SUFFIX}`, e.g. `26KS07CB01-EC`. The QR
code encodes that ID; the date/time stamp is today's.

## Editing the sample panel
Step 2 has an **✎ Edit panel** mode — no code needed. In it you can rename a sample,
remove one (`×`), add one (the `+` box at the end of a group), add or delete whole
pathogen groups, and **rename a type across every group at once** (e.g. `GB` → `PC`).

**Those edits are saved in your browser only** (`localStorage`, key `plate_panel`) —
other people loading the page still get the built-in panel. To change the panel *for
everyone*, hit **Copy as code** in the editor and paste the result over `DEFAULT_PANEL`
near the top of the app's second `<script>` block, then commit. **Reset to built-in
panel** discards the local copy.

`TYPES` and `SUFFIXES` no longer exist as separate lists to maintain: the custom-ID
builder's buttons are derived from `DEFAULT_PANEL.types`/`.suffixes` **plus whatever
the panel actually uses**, so adding `PC01-EC` gets you a `PC` button automatically.

## Notes
- Self-contained: one HTML file, runs offline, nothing sent anywhere.
- Rendering/print engine is shared with `../dymo-label-batch-printer/`.
