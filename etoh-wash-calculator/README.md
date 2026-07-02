# EtOH Wash Volume Calculator

**Compute ethanol and water volumes for bead-cleanup ethanol washes, scaled to sample count**

*By laboratorians, for laboratorians* 🔬

Created by [@tdoerks](https://github.com/tdoerks)

---

## 📋 What's This?

A single-page calculator for the ethanol wash step of a bead-based cleanup (e.g. post-library-prep).
Enter your sample count and it returns the total wash volume plus the ethanol and water volumes to mix,
scaled with a configurable pipetting-loss margin — no more doing this math by hand or in a spreadsheet.

### Key Features:

- 🧮 **Live calculation** - total / EtOH / H₂O volumes update as you type
- ⚙️ **Fully adjustable** - per-wash volume, number of washes, %EtOH, and loss margin are all editable
- 📊 **Quick-reference table** - volumes pre-computed for common sample counts (10–96), using your current settings
- ⚠️ **Sanity-check warning** - flags an unusually high loss margin (icon + text, not color alone)
- 🖨️ **Print-ready** - one-page bench sheet, hides the input chrome when printed
- 📱 **Works offline** - no server, no install, runs from a double-click

---

## 🚀 Quick Start

1. **Download** the [EtOH Wash Calculator](./EtOH_Wash_Calculator.html)
2. **Open** in any web browser
3. **Enter** your number of samples
4. **Confirm or adjust** per-wash volume, wash count, %EtOH, and loss margin (defaults: 180 µL, 2 washes, 80%, 10%)
5. **Read off** the total / EtOH / H₂O volumes, or check the quick-reference table below
6. **Print** for a bench-ready sheet

No installation required! Works completely offline.

---

## ✨ How It Works

### Formula

```
total_volume  = num_samples × per_wash_volume × num_washes × (1 + loss_margin%)
etoh_volume   = total_volume × etoh%
h2o_volume    = total_volume − etoh_volume
```

`h2o_volume` is computed as the remainder of `total_volume − etoh_volume` (not rounded independently),
so the two always add back up to exactly the total.

### Worked example

10 samples, 180 µL per wash, 2 washes, 10% loss margin, 80% EtOH:

```
total = 10 × 180 × 2 × 1.10 = 3960 µL
EtOH  = 3960 × 0.80          = 3168 µL
H2O   = 3960 − 3168          = 792 µL
```

Switching to a 200 µL wash volume (same sample count/margin/%EtOH) gives 4400 / 3520 / 880 µL.

### Quick-Reference Table

The bottom of the calculator lists total/EtOH/H₂O volumes for 10, 20, 30, 40, 50, 60, 70, 80, 90, and 96
samples — recomputed live from whatever wash volume, wash count, %EtOH, and margin you've currently set,
so it's always accurate to your run, not just the defaults.

---

## 🔧 Technical Details

- **Pure HTML/CSS/JavaScript** - no dependencies, no build step
- **No data saved** - a fresh visit always starts from the defaults; nothing is written to
  browser storage
- **No export** beyond print (this is a one-shot calculation, not a record you need to keep as a file)

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
