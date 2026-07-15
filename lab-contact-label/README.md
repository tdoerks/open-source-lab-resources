# Laboratory Contact Label Generator

A single-page tool for generating **freezer, refrigerator, and laboratory storage
contact labels** for academic and research laboratories. Fill in the form on the
left, watch the label build live on the right, then print or download it as
**PNG, SVG, or PDF**. Every label carries a **QR code** and an **NFC destination
URL** so anyone can reach the responsible contacts by scanning or tapping.

**Live:** https://tdoerks.github.io/open-source-lab-resources/lab-contact-label/

Kansas State CVM-inspired signage aesthetic: deep purple header, high-contrast
sections, an unmistakable red after-hours emergency band, and a dedicated QR + NFC
footer. Built to be readable at arm's length on the door of a −80 °C freezer.

---

## Features

- **Live preview** — the label updates as you type. The preview *is* the export;
  what you see is exactly what prints.
- **Five templates** — Freezer Contact, Refrigerator Contact, Liquid Nitrogen
  Storage, Molecular Samples, and DNA / RNA Storage. Each sets the heading,
  equipment type, and temperature/hazard badge.
- **QR code** generated dynamically from your destination URL.
- **NFC section** displaying the programmed URL, with a **copy-to-clipboard**
  button for tag-writing apps.
- **Exports** — Print, Download PNG, Download SVG, Download PDF.
- **Dark mode** for the editor (the label itself always prints in a high-contrast,
  print-safe palette).
- **High-contrast print mode** — forces pure black & white for maximum legibility
  and toner economy.
- **Save / load / reset** — store named labels in your browser and reload them
  later. The current form also autosaves.
- **Accessible** — keyboard navigable, labeled controls, visible focus rings, and
  a descriptive `aria-label` on the generated label.
- **Self-contained** — one HTML file. The only external dependency is a QR code
  library loaded from a CDN. No backend, no build step, no framework. Nothing you
  enter ever leaves your browser.

---

## Installation

No installation or build tools are required — it is a single static HTML file.

**Use it locally**

1. Download `index.html` from this folder.
2. Open it in any modern browser (Chrome, Edge, Firefox, Safari).

That's it. It runs offline except for the one-time CDN fetch of the QR library.
If you need fully offline use, download `qrcode.min.js`
([qrcode-generator](https://cdnjs.com/libraries/qrcode-generator)) next to
`index.html` and change the `<script src="…">` tag to point at the local copy.

**Run a local server (optional)**

Some browsers restrict clipboard access on `file://` pages. To exercise every
feature, serve the folder over HTTP:

```bash
cd lab-contact-label
python3 -m http.server 8000
# then open http://localhost:8000
```

---

## Deploying to GitHub Pages

This tool is designed to run directly from GitHub Pages.

1. Commit `index.html` (and this `README.md`) to your repository — for this repo
   it already lives at `lab-contact-label/`.
2. In your repository, go to **Settings → Pages**.
3. Under **Build and deployment → Source**, choose **Deploy from a branch**.
4. Select the `main` branch and the `/ (root)` folder, then **Save**.
5. After a minute, your tool is live at:

   ```
   https://<username>.github.io/<repository>/lab-contact-label/
   ```

   For this repository that is:
   `https://tdoerks.github.io/open-source-lab-resources/lab-contact-label/`

No workflow file or build configuration is needed because there is nothing to
build — GitHub Pages serves the HTML as-is.

---

## How the QR code works

- The QR code encodes the **Destination URL** you enter in the form (the same URL
  used for NFC).
- It is generated **entirely in your browser** using the
  [qrcode-generator](https://cdnjs.com/libraries/qrcode-generator) library, then
  drawn as vector rectangles inside the label's SVG. Because it is vector, it
  stays razor-sharp at any print size and exports cleanly to PNG, SVG, and PDF.
- Error-correction level **M** (~15 %) is used — a good balance of resilience and
  density for labels that may get scuffed or frosted.
- **Tips for reliable scanning:**
  - Keep the URL short. Long URLs pack more modules into the same space, making
    the code harder to scan on a frosty freezer. Use a short link or a redirect
    (e.g. a `labs.example.edu/frz-a14` vanity path) where possible.
  - Print at **300 DPI or higher** and keep the QR at least **20 mm × 20 mm**.
  - Preserve the white "quiet zone" around the code — don't crop it.
  - Test the printed label with a phone before laminating a whole batch.

The QR points wherever you like: a lab wiki page, a SharePoint/Google Doc contact
sheet, a Teams/Slack channel, an equipment record, or a `tel:`/`mailto:` link for
one-tap calling. To make it dial a phone directly, set the URL to
`tel:+17855550142`; for email, use `mailto:pi@example.edu`.

---

## Programming the NFC tag

NFC lets someone **tap** the label with a phone (no app, no scanning) and be taken
straight to your destination URL. The label reserves an **NFC section** showing the
exact URL that should be written to the tag, plus a copy-to-clipboard button.

**What you need**

- NTAG-family tags work well (**NTAG213/215/216**). NTAG213 (~144 bytes) is plenty
  for a normal URL; use NTAG216 if your URLs are long.
- A phone with NFC (most modern Android phones; recent iPhones can write tags with
  an app).
- A free tag-writing app such as **NFC Tools** (Android/iOS) or **NXP TagWriter**
  (Android).

**Steps**

1. In the generator, enter your **Destination URL** and click **Copy** (either the
   copy button next to the NFC row, or in the label's NFC section).
2. Open your NFC writing app and choose **Write → Add a record → URL / URI**.
3. Paste the URL and write it to the tag.
4. **(Recommended)** Use the app's **lock / make read-only** option so the tag
   can't be reprogrammed once deployed.
5. Test by tapping with another phone, then adhere the tag to (or behind) the
   printed label. Keep the tag away from bare metal — the freezer body can detune
   the antenna. Use an on-metal / ferrite-backed tag for metal surfaces.

The QR code and the NFC tag intentionally point to the **same URL**, so scanning
and tapping lead to the same place.

---

## Printing recommendations

- **Size:** the label is laid out at a **4 in × 6.2 in** portrait ratio. The PDF
  export is sized to those physical dimensions; PNG export is available at
  standard, high, and ultra resolutions.
- **Print → Save as PDF** works in every browser; the dedicated **Download PDF**
  button produces the same physical-size file directly.
- **Media:** print on **weatherproof / polyester label stock** or laminate after
  printing. Freezer condensation and frost will destroy plain paper. For −80 °C or
  cryo use, choose **cryogenic-rated labels or laminate pouches**.
- **Adhesive:** standard adhesives fail in the cold. Use **freezer-grade** or
  **cryo adhesive** labels, or mount the printed sheet in a **rigid sign holder /
  laminated pouch** attached to the door.
- **Contrast:** for laser printers or low-toner situations, enable
  **High-contrast print** (top-right of the preview) to force pure black & white.
- **Placement:** mount at eye level on the door, clear of gaskets and vents, where
  it stays visible when the unit is closed.
- Always **scan-test a printed label** before producing a batch for multiple labs.

---

## Privacy

Everything runs locally in your browser. Form contents and saved labels are stored
only in your browser's `localStorage` on your own device. No data is transmitted to
any server. The single network request is the one-time load of the QR library from
the CDN.

---

## For developers

- Single file, no build step. Open `index.html` and edit.
- The JavaScript is organized into small modules inside the closing `<script>`:
  `Icons`, `Templates`, `State`, `Svg` (label rendering), `Export`
  (PNG/SVG/PDF/print), `Storage` (localStorage), and `UI` (wiring).
- The label is authored as an inline **SVG**, so every export derives from one
  source of truth: SVG is serialized directly, PNG is rasterized via `<canvas>`,
  and PDF embeds that canvas as a JPEG image XObject (`DCTDecode`) in a
  hand-assembled PDF — no PDF library required.
- **To add a template:** add an entry to the `Templates` object and its key to
  `TEMPLATE_ORDER`.
- **To change the palette:** edit the CSS custom properties in `:root` /
  `[data-theme="dark"]` for the app chrome, and the `pal` objects in
  `Svg.render()` for the label itself.

---

*Part of [Open Source Lab Resources](https://github.com/tdoerks/open-source-lab-resources).
By laboratorians, for laboratorians.* 🔬
