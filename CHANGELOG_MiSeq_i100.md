# MiSeq i100 Pooling Sheet - Changelog

## February 21, 2026 - Save/Load Functionality Added

### Features
Added comprehensive save/load functionality using browser localStorage - no database required!

#### 1. Auto-Save (Background)
- Automatically saves form data every 2 seconds after last change
- Persists in browser localStorage
- Auto-loads on page refresh
- Status indicator shows last save time

#### 2. Named Session Save/Load
- Save current work with a custom name (e.g., "Pool_2026-02-21")
- Load any previously saved session from dropdown
- Sessions include timestamp
- Multiple sessions can be saved

#### 3. Export/Import JSON
- Export button downloads complete session as .json file
- Import button loads data from .json file
- Portable - can backup, share, or archive pooling runs
- Files include all samples and protocol settings

#### 4. Clear Form
- Reset all data to defaults
- Confirmation dialog prevents accidental clearing

### What Gets Saved
- All sample entries (name, Qubit, BioAnalyzer values)
- Pool concentration
- Loading concentration
- PhiX checkbox state and percentage
- Volume settings
- Complete protocol configuration

### Usage
1. **Auto-save**: Just work normally - data saves automatically
2. **Save session**: Enter name, click "💾 Save Session"
3. **Load session**: Select from dropdown, click "📂 Load Session"
4. **Export**: Click "⬇️ Export JSON" to download backup file
5. **Import**: Click "⬆️ Import JSON" to load from file

### Technical Details
- Uses browser localStorage API (5-10 MB limit)
- Data persists between browser sessions
- 2-second debounce on auto-save (performance optimization)
- JSON format for easy serialization
- Graceful error handling

### Limitations
- Data is browser-specific (won't sync across devices)
- Clearing browser cache deletes saved data
- Use Export/Import for cross-browser/cross-device transfers

---

## February 21, 2026 - PhiX Dilution Instructions Added

### Problem
The pooling sheet previously showed "Add PhiX Control (at 10x)" but didn't explain HOW to dilute the PhiX stock to get it to 10x concentration. Users might add undiluted PhiX stock (10 nM) directly to the library pool, which would be incorrect.

### Solution
Added clear, step-by-step PhiX dilution instructions using sub-steps that appear only when PhiX is enabled.

### Changes Made

#### 1. Dynamic Step 1 Display
**WITHOUT PhiX (checkbox unchecked):**
```
Step 1: Dilute to 10x Loading Concentration
• X μL pool (Y nM)
• Z μL RSB (Resuspension Buffer)
= 30 μL at 10x target concentration
```

**WITH PhiX (checkbox checked):**
```
Step 1: Prepare Library and PhiX at 10x Concentration

a) Dilute library pool to 10x concentration
   • X μL pool (Y nM)
   • Z μL RSB (Resuspension Buffer)
   = 30 μL at W nM (10x)

b) Dilute PhiX stock to 10x concentration
   • A μL PhiX stock (10 nM)
   • B μL RSB (Resuspension Buffer)
   = 30 μL at W nM (10x)
   ⚠ PhiX must be diluted to match library concentration before mixing

c) Mix library + PhiX (both at 10x)
   • C μL from Step 1a (library at 10x)
   • D μL from Step 1b (PhiX at 10x)
   = 30 μL total with E% PhiX
```

#### 2. PhiX Dilution Calculation
Added automatic calculation for diluting PhiX stock (10 nM from Illumina) to match the library pool's 10x concentration.

**Formula:**
```javascript
phixStockVol = (targetConc / 10 nM) × desiredVolume
phixBufferVol = desiredVolume - phixStockVol
```

**Example:** For 100 pM loading concentration:
- Target 10x concentration: 1 nM
- PhiX dilution: 3 μL stock (10 nM) + 27 μL RSB = 30 μL at 1 nM

#### 3. Visual Improvements
- Sub-steps (a, b, c) only show when PhiX checkbox is enabled
- Purple highlighting for PhiX-specific steps
- Warning message: "⚠ PhiX must be diluted to match library concentration before mixing"
- Maintains clean numbering (always "Step 1, Step 2, Step 3" regardless of PhiX)

### Technical Details

**Files Modified:**
- `miseq-pooling/MiSeq_i100_Pooling_Sheet.html`

**JavaScript Functions Updated:**
1. `togglePhiX()` - Now switches between simple and sub-step display
2. `calculateProtocol()` - Added PhiX dilution calculations

**New HTML Elements:**
- `step1NoPhiX` - Simple step display (without PhiX)
- `step1WithPhiX` - Sub-step display (with PhiX)
- `step1a_*` - Library dilution values
- `step1b_*` - PhiX dilution values
- `step1c_*` - Mixing values

### Example Output

For a typical run with:
- Pool concentration: 10 nM
- Loading concentration: 100 pM (0.1 nM)
- PhiX: 1%

**Step 1a (Library):**
- 3 μL pool (10 nM)
- 27 μL RSB
- = 30 μL at 1 nM

**Step 1b (PhiX):**
- 3 μL PhiX stock (10 nM)
- 27 μL RSB
- = 30 μL at 1 nM

**Step 1c (Mix):**
- 29.7 μL library (from 1a)
- 0.3 μL PhiX (from 1b)
- = 30 μL with 1% PhiX

### Testing
- Verified calculations for different loading concentrations (50-200 pM)
- Tested with and without PhiX enabled
- Confirmed visual display switches correctly

### Notes
- PhiX stock concentration is hardcoded as 10 nM (standard Illumina concentration)
- Both library and PhiX are diluted to the same 10x concentration before mixing
- This ensures accurate PhiX percentage in the final mix

---

**Updated by:** Tyler Doerks & Claude Code
**Date:** February 21, 2026
**Version:** MiSeq i100 v1.1
