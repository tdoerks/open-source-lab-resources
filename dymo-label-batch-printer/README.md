# DYMO Label Batch Printer

**Batch-print DYMO labels from a saved template merged with a list of entries**

*By laboratorians, for laboratorians* 🔬

Created by [@tdoerks](https://github.com/tdoerks)

---

## 📋 What's This?

An interactive HTML tool for printing many DYMO labels at once from a single design. Design a
label's look once in DYMO Label Software (or any image editor), export it as an image, load it here
as a **template**, place text/date/counter/QR fields on top of it by clicking and dragging, then paste
or type a **batch list** — one row per label (e.g. 20 instrument serial numbers) — and print one
physical label per row.

This tool does not parse real `.dymo`/`.label` files (the format is proprietary and undocumented) —
it works from an exported/screenshotted image of your design instead.

### Key Features:

- 🖼️ **Template manager** — save, edit, duplicate, and reuse label designs
- 🎯 **Click/drag field placement** — position text, date, counter, and QR fields directly on a live preview
- 📋 **Batch table** — one editable row per label, with CSV paste and column mapping for bulk entry
- 🔢 **Auto-incrementing counters** — sequential IDs with a configurable start value, step, and zero-padding
- 📱 **Offline QR codes** — QR generation is fully inlined, no CDN or internet required
- 📅 **"Fill today"** — stamp today's date into every row in one click
- 💾 **Autosave + JSON export/import** — templates (including the embedded image) round-trip as portable JSON
- 🖨️ **Print-ready** — one label per physical page, sized to match your label stock

---

## 🚀 Quick Start

1. **Download** the [Batch Printer](./DYMO_Label_Batch_Printer.html)
2. **Open** in any web browser
3. **Create a template**: upload your label design image, pick a size preset (or enter custom dimensions)
4. **Place fields**: click the preview to add text/date/counter/QR fields, drag to position them
5. **Save** the template
6. **Build a batch**: type rows manually or paste a CSV and map columns to fields
7. **Print** — one label per page, ready for your DYMO printer

No installation required! Works completely offline, including QR code generation.

---

## 🏷️ Label Size Presets

Matches the size table used by the [DYMO Label Converter](../dymo-label-converter/):

| Size | Dimensions | Use Case |
|------|-----------|----------|
| **Small Address** | 1.125" x 3.5" (28mm x 89mm) | Small labels, barcodes |
| **Large Address** | 1.4" x 3.5" (36mm x 89mm) | Address labels |
| **Shipping** | 2.25" x 4" (57mm x 102mm) | Equipment labels |
| **Badge/Name** | 2.25" x 1.25" (57mm x 32mm) | Name tags, IDs |
| **Square** | 2" x 2" (51mm x 51mm) | Logos, calibration stickers |
| **Custom** | any W×H | Anything else |

---

## ✨ Field Types

- **Text** — free-typed value per row (e.g. sample ID, technician name)
- **Date** — typed or filled via the "Fill today" button
- **Counter** — auto-computed as `start + row index × step`, zero-padded to a set number of digits;
  recomputes from current row order, so reordering or deleting rows shifts later counter values
- **QR** — encodes the resolved value of another field on the same row (e.g. QR-encode the counter or
  a sample ID); empty source values simply skip the QR for that row

---

## 🎯 Use Cases

### Instrument Serial Number Labels
Load a template with your lab's logo and a counter field, batch-print 20+ sequential labels for new
equipment in one pass.

### Sample Batch Labels with QR
Design a template with a sample-ID text field and a QR field sourced from it — paste a CSV of sample
IDs and print scan-ready labels for an entire batch.

### Calibration/Date-Stamped Labels
Use a date field with "Fill today" to stamp an entire batch with the current date in one click.

---

## 💾 Persistence & Export

- **Autosave**: templates and the current batch are saved to browser localStorage automatically.
- **Export template as JSON**: fully self-contained (includes the background image), for backup or
  moving to another machine.
- **Import template JSON**: round-trips your exported templates exactly.
- **Export batch as CSV**: typed values only (no images), for record-keeping.
- **Print**: opens the browser print dialog with one composited label per page, sized to your
  template's physical dimensions.

---

## 🔧 Technical Details

- **Pure HTML/CSS/JavaScript** — no dependencies, no build step
- **Canvas API** — for compositing the background image with text/QR fields
- **Inlined QR encoder** — no CDN, works fully offline
- **No server required** — runs completely offline from disk or GitHub Pages

### Browser Compatibility
- ✅ Chrome/Edge (recommended)
- ✅ Firefox
- ✅ Safari

---

## 📄 License

MIT License - See [LICENSE](../LICENSE) file

Free to use, modify, and share!

---

## 👤 Contact

Created by Tyler Doerksen - [@tdoerks](https://github.com/tdoerks)

*By laboratorians, for laboratorians* 🔬

Questions, suggestions, or want to collaborate? Open an issue or reach out!

---

*Part of the [Open Source Lab Resources](../) collection*
