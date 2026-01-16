# Bacterial Isolation & Sequencing Workflow Tracker

**Comprehensive web-based tracking system for bacterial culture, isolation, and whole genome sequencing workflows**

*By laboratorians, for laboratorians* 🔬

Created by [@tdoerks](https://github.com/tdoerks)

---

## 📋 What's This?

A complete laboratory information management system (LIMS) for tracking bacterial samples through an 8-stage workflow from initial receipt through final quality control. Perfect for microbiology labs, clinical facilities, and research institutions performing bacterial whole genome sequencing (WGS).

### Key Features:

- 📊 **8-Stage Workflow** - Complete pipeline tracking
- 🔄 **Batch Processing** - Handle multiple samples simultaneously
- 📝 **Detailed Tracking** - Reagent lots, technicians, dates, equipment
- 💾 **Auto-Save** - Browser-based persistence (LocalStorage)
- 📤 **Export/Import** - CSV and JSON formats
- 🔍 **Search & Filter** - Find samples instantly
- 📈 **Status Dashboard** - Visual overview of sample distribution
- 🌓 **Dark Mode** - Eye-friendly interface option

---

## 🚀 Quick Start

1. **Download** the [Bacterial Isolation Tracker](./Bacterial_Isolation_Tracker.html)
2. **Open** in any web browser (Chrome, Firefox, Safari, Edge)
3. **Add samples** using single or bulk input
4. **Track progress** through each workflow stage
5. **Export data** for records and reporting

No installation, no server, no database required! All data stays in your browser.

---

## ✨ Workflow Stages

### Stage 1: Received
**Initial sample intake**
- Record sample ID and technician initials
- Track date and time of receipt
- Add initial observations/notes

### Stage 2: BAP Complete (Blood Agar Plate)
**Primary culture on blood agar**
- Plate lot number
- Incubation temperature
- Incubator ID
- Technician performing plating
- Date/time

### Stage 3: TSB Complete (Tryptic Soy Broth)
**Enrichment culture**
- Broth lot number
- Incubation temperature
- Incubator ID
- Technician
- Date/time

### Stage 4: Extraction Complete
**DNA extraction from culture**
- Extraction kit lot number
- Method/protocol used
- Technician
- Date
- Initial quality notes

### Stage 5: Clean Extraction Complete
**DNA cleanup/purification**
- Cleanup kit lot number
- Method used
- Technician
- Date
- Preparation for QC

### Stage 6: Clean Extraction Qubit Complete
**Quality control after cleanup**
- Qubit concentration (ng/µL)
- Volume (µL)
- Total DNA (ng)
- Pass/fail assessment
- Technician and date

### Stage 7: Indexing Complete
**Library preparation with barcodes**
- Index/barcode assignment
- Library prep kit lot
- Plate/well position
- Run assignment
- Technician and date

### Stage 8: Qubit Complete (Final QC)
**Final quality control before sequencing**
- Final Qubit concentration
- Library quality assessment
- Ready for sequencing confirmation
- Technician and date

---

## 💡 Main Features

### Sample Management

**Single Sample Input**:
- Add one sample at a time with full details
- Perfect for smaller batches or mixed timing

**Bulk Sample Input**:
- Paste multiple sample IDs at once
- Assign tech initials and date to all
- Rapid data entry for large batches

**Sample Tracking**:
- View all samples in a sortable table
- Search by sample ID
- Filter by workflow stage
- View detailed chain of custody

### Batch Processing

When multiple samples are at the same stage:
- Checkboxes automatically appear
- Select 2+ samples
- Click "Start Batch Processing"
- Fill shared reagent information once
- Individual fields (like indexes) filled per sample
- Save all samples simultaneously

**Batch capabilities**:
- Same lot numbers for all samples
- Consistent technician assignment
- Uniform incubation conditions
- Time-saving for high throughput

### Data Management

**Auto-Save**:
- Every action automatically saved to browser
- Data persists between sessions
- No manual save needed

**JSON Export/Import**:
- Full backup of all sample data
- Restore from previous backup
- Transfer data between browsers/computers
- Archive completed projects

**CSV Export**:
- Excel-compatible format
- All workflow data included
- Ready for analysis or reporting
- Share with non-technical staff

**Clear All Data**:
- Reset tracker to start fresh
- Double confirmation required
- Use for testing or new projects

### Search & Filter

**Real-Time Search**:
- Type sample ID to find instantly
- Highlights matching samples
- Case-insensitive
- Searches across all fields

**Status Filters**:
- View only samples at specific stages
- Radio buttons for each workflow step
- "All Samples" to view everything
- Counts displayed for each stage

**Status Dashboard**:
- Visual bar chart of sample distribution
- Color-coded by stage
- Real-time updates
- Quick overview of workflow progress

### Quality of Life Features

**Delete Samples**:
- Remove test or incorrect entries
- Confirmation required
- Permanent deletion

**Sample Details Modal**:
- Click any sample for full history
- Complete chain of custody
- All reagent lots and technicians
- Date/time for each step

**Auto-Numbering**:
- Plates, runs, and wells auto-increment
- Customizable prefixes
- Prevents duplicate assignments

**Duplicate Detection**:
- Prevents adding existing sample IDs
- Alert when duplicate attempted
- Maintains data integrity

**Sample Notes**:
- Add observations at any stage
- Track issues or special handling
- Viewable in sample details

**Dark Mode**:
- Toggle for eye strain reduction
- Preference saved
- All interfaces supported

---

## 📖 Usage Guide

### Adding Samples

**Method 1: Single Sample**
1. Enter Sample ID (e.g., "MS001", "Sample-2025-001")
2. Enter technician initials
3. Click "Add Sample"
4. Sample appears in table with "Received" status

**Method 2: Bulk Input**
1. Click "Switch to Bulk Input"
2. Paste multiple sample IDs (one per line)
3. Enter technician initials (applied to all)
4. Click "Add Samples"
5. All samples added with "Received" status

**Example bulk format**:
```
MS001
MS002
MS003
```

### Processing Individual Samples

1. Find sample in table (use search or filter)
2. Click the blue action button (e.g., "Start BAP")
3. Modal opens with fields for that stage
4. Fill in:
   - Reagent lot numbers
   - Temperatures, incubators, equipment
   - Technician info
   - Date/time (auto-filled, editable)
5. Click "Complete [Stage Name]"
6. Sample advances to next stage

### Batch Processing Workflow

**Scenario**: You have 24 samples ready for DNA extraction

1. **Filter** to "Received" or "TSB Complete" (whatever stage they're at)
2. **Checkboxes appear** automatically when 2+ samples at same stage
3. **Select** all 24 samples (or use "Select All" if available)
4. **Click** "Start Batch Processing for [Stage]"
5. **Fill shared info**:
   - Extraction kit lot: "EXT-2025-001"
   - Technician: "TD"
   - Date: Auto-filled
6. **Individual fields**:
   - Each sample gets a row
   - Fill sample-specific info if needed
7. **Click** "Complete All"
8. **All 24 samples** advance simultaneously

### Searching and Filtering

**Find specific sample**:
- Type "MS001" in search box
- Table filters to show only matching samples

**View samples at specific stage**:
- Click radio button "BAP Complete"
- Table shows only samples at that stage
- Count shown next to button

**View all samples**:
- Click "All Samples" radio button
- Full table displayed

### Exporting Data

**For backup (JSON)**:
1. Click "📥 Export JSON"
2. File downloads: `bacterial-tracker-backup-YYYY-MM-DD.json`
3. Save to safe location (network drive, cloud, etc.)
4. Can be imported back into tracker

**For analysis (CSV)**:
1. Click "📥 Export CSV"
2. File downloads: `bacterial-tracker-export-YYYY-MM-DD.csv`
3. Open in Excel, Google Sheets, R, Python
4. Contains all workflow data in columns

### Importing Data

1. Click "📤 Import JSON"
2. Select previously exported JSON file
3. Data loads into tracker
4. Existing data is replaced (backup first!)

---

## 🔬 Use Cases

### Research Laboratory

**Scenario**: Isolate and sequence bacteria from environmental samples

**Workflow**:
1. Receive 50 environmental swabs
2. Add all samples in bulk input
3. Process through BAP and TSB enrichment
4. Batch-extract DNA from all positive cultures
5. QC with Qubit, batch process cleanup
6. Prepare libraries with unique indexes
7. Final QC before pooling for sequencing
8. Export CSV for manuscript supplementary data

**Benefits**:
- Track all samples through complete workflow
- Document reagent lots for methods section
- Export data for publications
- Chain of custody for data integrity

### Clinical Laboratory

**Scenario**: Process patient isolates for WGS epidemiology

**Workflow**:
1. Receive bacterial isolates from clinical cases
2. Add with patient identifiers (de-identified)
3. Culture and extract DNA
4. Track all QC values
5. Prepare sequencing libraries
6. Export data for LIMS integration
7. Chain of custody for regulatory compliance

**Benefits**:
- Complete documentation for audits
- Reagent lot tracking for recalls
- Technician accountability
- Export for outbreak investigations

### Teaching Laboratory

**Scenario**: Students learning bacterial isolation and sequencing

**Workflow**:
1. Each student receives samples
2. Students add their samples to tracker
3. Follow workflow steps over semester
4. Document all procedures and observations
5. Export individual data for lab reports

**Benefits**:
- Students learn LIMS usage
- Practice good documentation habits
- Track progress over time
- Export data for assignments

---

## 🔧 Technical Details

### Technology Stack
- **Pure HTML/CSS/JavaScript** - No frameworks, no dependencies
- **LocalStorage API** - Browser-based persistence
- **No server required** - Runs completely offline
- **No installation** - Just open HTML file

### Data Storage

**LocalStorage**:
- 5-10 MB typical limit (sufficient for thousands of samples)
- Data stays on local computer
- Persists until manually cleared
- Browser-specific (Chrome data ≠ Firefox data)

**Data Structure**:
```javascript
{
  samples: [
    {
      id: "MS001",
      received: { date, tech, notes },
      bap: { lotNumber, temp, incubator, tech, date },
      tsb: { lotNumber, temp, incubator, tech, date },
      extraction: { kit, tech, date },
      cleanExtraction: { kit, tech, date },
      cleanQubit: { concentration, volume, total, tech, date },
      indexing: { index, plate, well, run, kit, tech, date },
      qubit: { concentration, volume, total, tech, date }
    }
  ]
}
```

### Browser Compatibility

- ✅ **Chrome/Edge** (recommended) - Full support
- ✅ **Firefox** - Full support
- ✅ **Safari** - Full support
- ⚠️ **Internet Explorer** - Not supported (use Edge)
- ✅ **Mobile browsers** - Functional but desktop recommended

### File Size & Performance

- HTML file: ~1 MB
- Loads in <1 second on modern hardware
- Handles 1000+ samples smoothly
- Search and filter operations <100ms

---

## 💾 Data Backup Recommendations

Since data is stored in browser LocalStorage:

### Backup Schedule
- **Daily**: If actively processing samples
- **Weekly**: For stable/slow-moving projects
- **Before major changes**: Always backup first
- **End of project**: Archive final data

### Backup Strategy
1. **JSON Export**: Full backup with all data
2. **CSV Export**: Human-readable, analysis-ready
3. **Keep multiple versions**: Don't overwrite old backups
4. **Use descriptive filenames**: Include date and project
   - Good: `bacterial-tracker-ProjectX-2025-01-15.json`
   - Bad: `backup.json`

### Important Notes
- **Browser-specific**: Data doesn't sync between browsers
- **Computer-specific**: Data doesn't follow you to other computers
- **Clearing browser data**: Will delete tracker data
- **Private/Incognito mode**: Data won't persist
- **Browser updates**: Usually safe, but backup first

---

## 🎯 Best Practices

### Sample Naming
- Use consistent format: `MS001`, `Sample-2025-001`, `ENV-001`
- Include project identifier if managing multiple projects
- Avoid special characters that might cause issues
- Keep under 30 characters for readability

### Workflow Discipline
- Complete stages in order (don't skip)
- Fill in all required fields
- Add notes for anything unusual
- Use batch processing when possible

### Quality Control
- Document all QC values (Qubit, etc.)
- Flag samples that fail QC in notes
- Track re-extraction attempts
- Export data regularly for analysis

### Team Collaboration
- Establish technician initial standards (2-3 letters)
- Use consistent reagent lot number formats
- Document equipment IDs (incubators, etc.)
- Export and share data files for team visibility

### Data Management
- Export JSON daily during active work
- Export CSV at project milestones
- Keep backups on network drive or cloud
- Don't rely solely on browser storage

---

## 🆘 Troubleshooting

### Data Not Saving
**Symptoms**: Changes disappear after closing browser

**Solutions**:
- Check LocalStorage is enabled (not in private mode)
- Check browser storage isn't full (clear cache if needed)
- Try different browser
- Use JSON export/import as workaround

### Can't Find Sample
**Symptoms**: Sample missing from table

**Solutions**:
- Clear search box (might be filtered out)
- Select "All Samples" filter
- Check if accidentally deleted
- Import backup if needed

### Batch Processing Not Available
**Symptoms**: No checkboxes, can't select multiple samples

**Solutions**:
- Need 2+ samples at exact same stage
- Samples at different stages can't be batched
- Process next stage for one sample to match others
- Use individual processing if needed

### Export Not Working
**Symptoms**: Click export but nothing downloads

**Solutions**:
- Check browser popup blocker
- Try different browser
- Check download folder permissions
- Use browser dev console to check errors (F12)

### Performance Slow
**Symptoms**: Tracker becomes sluggish with many samples

**Solutions**:
- System handles 1000+ samples typically
- Try different browser (Chrome recommended)
- Close other browser tabs
- Export old data, clear tracker, start fresh project

---

## 📊 Example Workflows

### Workflow 1: Standard 96-Sample Batch

**Day 1**: Receive 96 samples
- Bulk input all sample IDs
- Note: Received from field team

**Day 2**: Plate on BAP
- Filter to "Received"
- Select all 96 samples
- Batch process BAP plating
- Same plate lot, incubator, technician

**Day 3**: TSB enrichment for 48 positive cultures
- Filter to "BAP Complete"
- Select 48 positive samples (others deleted or kept)
- Batch process TSB
- Note: Enterococcus-like colonies

**Day 5**: DNA extraction
- Batch extract all 48 samples
- Same extraction kit lot

**Day 6**: DNA cleanup and QC
- Batch cleanup
- Individual Qubit values recorded

**Day 7**: Library prep
- Batch library prep
- Individual indexes assigned (I001-I048)
- Plate positions assigned automatically

**Day 8**: Final QC and pooling
- Final Qubit on all libraries
- Export CSV with all sample data
- Pool for sequencing run

**Result**: Complete documentation for 48 sequenced samples

### Workflow 2: Mixed Timing Project

**Ongoing**: Samples arrive continuously
- Add individual samples as received
- Process through workflow at different rates
- Use filters to organize by stage
- Batch process when multiple at same stage

**Weekly**:
- Export CSV for PI review
- Check status dashboard for bottlenecks
- Plan next week's processing based on stage counts

**Monthly**:
- Export JSON for archive
- Clear out completed samples or start new project
- Update reagent inventory based on lot usage

---

## 🤝 Customization

### Easy Customizations (No Coding)
- Sample naming conventions
- Technician initials format
- Reagent lot number format
- Equipment ID schemes

### Moderate Customizations (Some Coding)
- Add custom workflow stages
- Additional fields per stage
- Change color scheme
- Modify export formats

### Advanced Customizations (Significant Coding)
- Integration with barcode scanners
- Connection to external LIMS
- Database backend for multi-user
- Custom reporting dashboards

All code is open source (MIT License) - modify as needed!

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
