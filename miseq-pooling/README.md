# Illumina MiSeq Pooling Calculators

**Interactive HTML calculators for MiSeq library pooling with automatic volume calculations**

*By laboratorians, for laboratorians* 🔬

Created by [@tdoerks](https://github.com/tdoerks)

---

## 📋 What's Included

### 1. **Standard MiSeq Pooling Calculator** (`MiSeq_Pooling_Sheet.html`)
   - For standard MiSeq runs (v2, v3 kits)
   - Calculates equimolar pooling volumes
   - Supports up to 96 samples
   - Auto-saves data in browser

### 2. **MiSeq i100 Pooling Calculator** (`MiSeq_i100_Pooling_Sheet.html`)
   - Optimized for MiSeq i100 chemistry
   - Optional PhiX spike-in toggle
   - PhiX concentration calculations
   - All standard features plus i100-specific protocols

---

## 🚀 Quick Start

### Using the Calculator:

1. **Download** the appropriate HTML file:
   - Standard MiSeq → `MiSeq_Pooling_Sheet.html`
   - MiSeq i100 → `MiSeq_i100_Pooling_Sheet.html`

2. **Open** in any web browser (Chrome, Firefox, Safari, Edge)

3. **Fill in run information**:
   - Run name/ID
   - Date
   - Operator name
   - Target pool concentration
   - Target pool volume

4. **Enter sample data**:
   - Sample IDs
   - Library concentrations (ng/µL)
   - Library sizes (bp)

5. **Watch automatic calculations**:
   - Molarity calculations (nM)
   - Required pooling volumes (µL)
   - Dilution recommendations

6. **Export** your data or print for records

No installation required! Works offline after first load.

---

## ✨ Features

### Auto-Calculations
- **Molarity conversion** - Converts ng/µL to nM based on library size
- **Equimolar pooling** - Calculates volumes for equal representation
- **PhiX calculations** (i100 version) - Optional spike-in percentages
- **Dilution recommendations** - Suggests dilutions for high-concentration libraries

### Smart Design
- 📊 **Table view** - See all samples at once
- 🎨 **Color-coded** - Quick identification of issues (low conc, high volume needed)
- 📈 **Summary statistics** - Total volume, average concentration, pool metrics
- ⚠️ **Warnings** - Alerts for samples requiring attention

### Data Management
- **Auto-save** - Data persists in browser localStorage
- **Manual save** - Export as JSON for records
- **Load previous** - Resume from saved data
- **Clear all** - Start fresh with confirmation
- **Print-ready** - Optimized for record keeping

### Quality Checks
- Highlights samples with low concentration
- Flags samples requiring large volumes
- Validates input ranges
- Warns about pooling inconsistencies

---

## 📖 Usage Guide

### Which Version Should I Use?

| Feature | Standard MiSeq | MiSeq i100 |
|---------|----------------|------------|
| **Chemistry** | v2, v3 kits | i100 kit |
| **Run types** | Standard, Nano | i100 runs |
| **PhiX calculations** | Manual | Automatic toggle |
| **Target concentration** | Flexible | Optimized for i100 |
| **Best for** | Most MiSeq runs | i100-specific runs |

**Rule of thumb**: If you're using i100 chemistry, use the i100 version. Otherwise, use the standard version.

---

## 🧮 How the Calculations Work

### Molarity Calculation (ng/µL → nM)

```
Molarity (nM) = (Concentration in ng/µL × 10⁶) / (Library size in bp × 650)
```

Where:
- 10⁶ converts ng to pmol
- 650 is the average molecular weight of a base pair (g/mol)

### Pooling Volume Calculation

```
Volume (µL) = (Target molarity × Target volume) / Sample molarity
```

Ensures each sample contributes equally to final pool.

### PhiX Spike-In (i100 version)

```
PhiX volume = Target volume × (PhiX percentage / 100)
Sample volume total = Target volume - PhiX volume
```

---

## 📊 Example Workflow

### Standard 24-Sample MiSeq Run

**Setup**:
- Run Name: "240116_MiSeq_Tyler"
- Target concentration: 4 nM
- Target volume: 20 µL
- 24 samples ready to pool

**Process**:
1. Open `MiSeq_Pooling_Sheet.html`
2. Fill in run details
3. Enter each sample:
   - ID: Sample_001
   - Concentration: 15 ng/µL
   - Size: 450 bp
   - → Auto-calculates: 51.1 nM, needs 1.57 µL

4. Review warnings for any problematic samples
5. Prepare pooling tubes with calculated volumes
6. Export data for records
7. Print for bench reference

**Result**: Perfect equimolar pool ready for sequencing!

---

## 🎯 Best Practices

### Sample Preparation
1. **Quantify accurately** - Use Qubit or similar fluorometric method
2. **Check library size** - Run TapeStation/BioAnalyzer
3. **Normalize if needed** - Dilute high-concentration samples first
4. **Keep records** - Save calculator data with run records

### Using the Calculator
1. **Start fresh** - Clear previous data before new run
2. **Double-check inputs** - Verify concentrations and sizes
3. **Review warnings** - Address flagged samples before pooling
4. **Save frequently** - Export data as you work
5. **Print protocol** - Have physical copy at bench

### Quality Control
- ✅ All samples within 2-fold concentration range (ideal)
- ✅ No samples requiring >10 µL (may need dilution)
- ✅ Final pool concentration matches target
- ✅ PhiX percentage appropriate for run type (usually 1-5%)

---

## 🔧 Technical Details

### Browser Compatibility
- ✅ Chrome/Edge (recommended)
- ✅ Firefox
- ✅ Safari
- ✅ Works on tablets and desktops

### Requirements
- Modern web browser
- JavaScript enabled
- LocalStorage enabled (for auto-save)
- No internet required after first load

### Data Storage
- Stored locally in browser (LocalStorage)
- Data persists until cleared
- Export to JSON for permanent records
- No data sent to external servers

### Offline Use
Both calculators work completely offline after first load. Perfect for labs with limited internet access.

---

## 🎨 Customization

Both calculators can be customized:

1. **Default values** - Modify target concentration/volume defaults
2. **Sample count** - Adjust maximum number of samples
3. **Warning thresholds** - Change when alerts trigger
4. **Colors** - Modify CSS color schemes
5. **Calculations** - Adjust formulas if needed

All files are open source (MIT License) - feel free to modify!

---

## 🆘 Troubleshooting

### Calculator won't load
- Check JavaScript is enabled
- Try a different browser
- Clear browser cache
- Disable browser extensions temporarily

### Calculations seem wrong
- Verify you're using correct units (ng/µL, bp, nM)
- Check library size is realistic (usually 200-800 bp)
- Ensure concentration is accurate (re-quantify if needed)
- Try calculator with known good values first

### Auto-save not working
- Check LocalStorage is enabled
- Verify you're not in private/incognito mode
- Try manually exporting data as backup
- Same browser needed to retrieve saved data

### Print looks wrong
- Use browser print (Ctrl+P), not "Save as PDF"
- Enable "Background graphics" in print settings
- Use landscape orientation for wide tables
- Adjust print margins if needed

### Large volumes required
- Sample concentration too low - requantify or concentrate
- Target pool concentration too high - adjust if possible
- Library size incorrect - verify on BioAnalyzer
- Consider diluting other samples to match

---

## 📝 Input Field Reference

### Run Information
| Field | Description | Example |
|-------|-------------|---------|
| **Run Name** | Unique identifier for this run | "240116_MiSeq_Tyler" |
| **Date** | Date of pooling | "2024-01-16" |
| **Operator** | Person performing pooling | "Tyler Doerksen" |
| **Target Concentration** | Final pool molarity | 4 nM (typical) |
| **Target Volume** | Final pool volume | 20 µL (typical) |
| **PhiX %** (i100 only) | Spike-in percentage | 1-5% (typical) |

### Sample Information
| Field | Description | Typical Range |
|-------|-------------|---------------|
| **Sample ID** | Unique sample identifier | Any text |
| **Concentration** | Library quant (ng/µL) | 5-50 ng/µL |
| **Size** | Average library size (bp) | 200-800 bp |

### Calculated Outputs
| Field | Description |
|-------|-------------|
| **Molarity** | Calculated nM concentration |
| **Volume** | µL needed for equimolar pool |
| **Status** | OK / Warning / Action needed |

---

## 🔬 Related Protocols

This calculator pairs well with:
- Illumina library prep protocols
- Qubit quantification SOPs
- TapeStation/BioAnalyzer sizing protocols
- MiSeq loading SOPs

Consider creating SOPs that reference these calculators for standardized pooling!

---

## 🤝 Contributing

Suggestions for improvements:
- Additional sequencing platforms (NextSeq, NovaSeq)
- Integration with LIMS systems
- Barcode/index tracking
- Plate-based pooling layouts
- Mobile app version

Submit issues or pull requests on GitHub!

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
