# Freezer & Fridge Inventory Management System

**Comprehensive box-level inventory tracker for laboratory cold storage units**

*By laboratorians, for laboratorians* 🔬

Created by [@tdoerks](https://github.com/tdoerks)

---

## 📋 What's This?

A complete inventory management system for tracking samples stored in laboratory freezers and refrigerators at the **box level**. Perfect for research labs, clinical facilities, and biobanks that need to maintain detailed records of sample locations and contents.

### Key Features:

- 🗂️ **Multi-Freezer Support** - Manage unlimited freezers/fridges
- 📦 **Box-Level Tracking** - Track location, contents, and metadata for each storage box
- 🗺️ **Visual Box Maps** - Interactive grid view of individual sample positions within boxes
- 📊 **Statistics Dashboard** - Real-time counts of boxes, samples, research vs clinical
- 💾 **Auto-Save** - Data persists in browser (LocalStorage)
- 📤 **CSV Import/Export** - Bulk upload box contents or export for records
- 🔄 **Backup/Restore** - Full data backup and restore capability
- 📱 **Responsive Design** - Works on desktop, tablets, and mobile devices

---

## 🚀 Quick Start

### Getting Started:

1. **Download** the [Freezer Inventory Manager](./Freezer_Inventory_Manager.html)
2. **Open** in any web browser (Chrome, Firefox, Safari, Edge)
3. **Add your first box**:
   - Enter shelf, rack, drawer, and box position
   - Add box label/ID
   - Select sample types in the box
   - Choose box size (96-well, 81-well, etc.)
   - Mark as Research or Clinical
   - Add comments
4. **Click "Add Box"** to save
5. **Click "Box Map"** to track individual samples within the box

No installation required! Works completely offline after first load.

---

## ✨ Main Features

### Multi-Freezer Management
- Add unlimited freezers or fridges
- Switch between units with tabbed interface
- Track details for each unit:
  - Location (room/building)
  - Serial number
  - Temperature setting
  - Model and manufacturer
  - Install date
  - Maintenance history
  - Notes

### Box-Level Tracking
Track essential information for each box:
- **Location**: Shelf → Rack → Drawer → Box Position
- **Box Label/ID**: Custom identifier
- **Sample Types**: Feces, tissue, viral isolates, blood, serum, plasma, custom types
- **Box Size**: 8x12 (96), 9x9 (81), 10x10 (100), 5x10 (50 tubes)
- **Research/Clinical**: Classification flags
- **Comments**: Additional notes
- **Date Added**: Automatic timestamp

### Interactive Box Maps
- Visual grid representation of box contents
- Click any position to add/edit sample info
- Color-coded: Empty (white), Occupied (green), Selected (yellow)
- Sample-level tracking:
  - Sample ID
  - Description
  - Position (A1, B2, etc.)

### CSV Functionality
- **Download Template**: Pre-populated CSV with all positions
- **Upload CSV**: Bulk import sample data
- **Export Inventory**: Download box-level inventory
- Format: Position, Sample_ID, Description

### Data Management
- **Auto-Save**: Every change saved to browser LocalStorage
- **Backup All Data**: Export complete inventory as JSON
- **Restore from Backup**: Import previous backup file
- **Clear All**: Reset to fresh start (with confirmation)

---

## 📖 Usage Guide

### Adding Your First Freezer

1. The system starts with "Freezer 6 (-70°)" by default
2. Click **"+ Add Freezer"** to add more units
3. Enter a descriptive name (e.g., "Freezer 7", "Lab Fridge A")
4. Click **"View/Edit Freezer Details"** to add:
   - Location
   - Serial number
   - Temperature
   - Model/manufacturer
   - Dates

### Adding Boxes

1. **Select your freezer** from the tabs
2. **Enter location details**:
   - Shelf: Which shelf level (1-10)
   - Rack: Which rack on that shelf (1-10)
   - Drawer: Which drawer in that rack (1-10)
   - Box Position: Box number in that drawer (1-100)

3. **Enter box details**:
   - Box Label/ID: Your naming scheme (e.g., "Mouse-001", "RNA-2024-01")
   - Sample Types: Check all that apply (or add custom)
   - Box Size: Select from dropdown
   - Research/Clinical: Check if applicable
   - Comments: Any additional notes

4. **Click "Add Box"**

### Mapping Box Contents

After adding a box:

1. **Click "Box Map"** button for that box
2. **Interactive grid** appears showing all positions
3. **Click any position** to add sample:
   - Enter Sample ID (required)
   - Enter Description (optional)
   - Click "Save"
4. **Bulk upload option**:
   - Click "Download Template" to get CSV with all positions
   - Fill in Sample_ID and Description columns
   - Click "Upload CSV" to import

### Exporting Data

**Box-Level Export**:
- Click **"Export CSV"** button
- Downloads CSV with all boxes in current freezer
- Includes: Location, box details, sample types, classifications

**Full Backup**:
- Click **"Backup/Restore"** → **"Backup All Data"**
- Downloads JSON file with complete inventory
- Includes all freezers, boxes, samples, and details

---

## 📊 Use Cases

### Research Laboratory
**Scenario**: Track 5 different -80°C freezers with tissue samples

**Setup**:
- Add each freezer with its location and serial number
- Track research boxes by project (box labels: "Project-A-001")
- Use box maps for high-value samples
- Export data monthly for lab records

### Clinical Laboratory
**Scenario**: Manage patient sample biobank in multiple freezers

**Setup**:
- Separate freezers for different sample types
- Mark all boxes as "Clinical"
- Use box maps for patient sample tracking
- Regular backups for regulatory compliance
- CSV export for quarterly reports

### Biobank
**Scenario**: Large-scale sample storage across many freezers

**Setup**:
- Multiple freezers at different temperatures (-80°C, -20°C, 4°C)
- Detailed box labeling by cohort/study
- Complete box maps for all biobanked samples
- Daily backups
- CSV export for data sharing with researchers

---

## 🔧 Technical Details

### Data Storage

**LocalStorage**:
- All data stored in browser LocalStorage
- Persists until manually cleared
- ~5-10 MB storage limit (sufficient for thousands of boxes)
- Data structure:
  ```javascript
  {
    inventoryData: {
      "Freezer Name": [
        {
          id, shelf, rack, drawer, boxPosition,
          boxLabel, sampleTypes, boxSize,
          research, clinical, comments,
          dateAdded, sampleMap: { "A1": {id, description}, ... }
        }
      ]
    },
    freezerDetails: {
      "Freezer Name": {
        location, serialNumber, temperature,
        model, manufacturer, installDate,
        lastMaintenance, notes
      }
    }
  }
  ```

### Box Sizes Supported

| Size | Dimensions | Total Positions | Common Use |
|------|------------|-----------------|------------|
| **8x12** | 8 rows × 12 cols | 96 tubes | Most common, standard box |
| **9x9** | 9 rows × 9 cols | 81 tubes | Square boxes |
| **10x10** | 10 rows × 10 cols | 100 tubes | Large capacity |
| **5x10** | 5 rows × 10 cols | 50 tubes | Half-size boxes |

Position naming: Rows = Letters (A-J), Columns = Numbers (1-12)
- Example: A1, A2, B1, C5, H12

### Browser Compatibility

- ✅ **Chrome/Edge** (recommended) - Full support
- ✅ **Firefox** - Full support
- ✅ **Safari** - Full support
- ✅ **Mobile browsers** - Responsive design, works on tablets/phones

### Requirements

- Modern web browser (2020+)
- JavaScript enabled
- LocalStorage enabled
- ~5 MB free storage
- No internet required (offline after first load)

---

## 💡 Best Practices

### Naming Conventions

**Freezers**:
- Include temperature: "Freezer 6 (-80°C)"
- Include location: "L200 Research Freezer"
- Be consistent across your lab

**Boxes**:
- Project-based: "Mouse-Cohort-A-001"
- Date-based: "2024-01-Tissue-001"
- Sample type: "RNA-Extraction-001"
- Keep under 30 characters for readability

**Samples**:
- Unique identifiers only: "MS001", "PT-12345"
- Use description field for details
- Maintain master list separately if needed

### Organization Strategies

**Hierarchical**:
```
Freezer → Shelf → Rack → Drawer → Box → Sample
Example: Freezer 6 → Shelf 2 → Rack 1 → Drawer 3 → Box 5 → Position A7
```

**By Project**:
- Dedicate shelves or racks to specific projects
- All boxes for Project A on Shelf 1
- Easy to locate all samples for one project

**By Sample Type**:
- Separate drawers for different sample types
- Feces: Drawer 1, Tissue: Drawer 2, Blood: Drawer 3
- Reduces cross-contamination risk

**By Date**:
- Organize chronologically
- Older samples in lower shelves
- Recent samples easily accessible

### Data Management

**Backup Schedule**:
- Daily: If actively adding data
- Weekly: For stable inventories
- Before major changes: Always backup first
- Keep 3-5 historical backups

**Validation**:
- Monthly: Spot-check random boxes
- Quarterly: Full inventory audit
- After power outages: Verify affected freezers

**Export for Records**:
- Monthly CSV exports
- Attach to lab notebooks
- Share with PIs/lab managers
- Regulatory compliance

---

## 📝 CSV Format Guide

### Box Map CSV Format

**Template Structure**:
```csv
Position,Sample_ID,Description
A1,MS001,Mouse tissue - liver
A2,MS002,Mouse tissue - spleen
A3,,
B1,MS003,Mouse tissue - kidney
```

**Rules**:
- Header row required: Position,Sample_ID,Description
- Position: Letter + Number (A1, B2, H12, etc.)
- Sample_ID: Required if adding sample
- Description: Optional
- Empty rows (no Sample_ID): Position remains empty/is cleared
- Commas in descriptions: Wrap in quotes: "Sample, with, commas"

### Inventory Export CSV Format

**Columns**:
```
Freezer, Shelf, Rack, Drawer, Box Position, Box Label/ID,
Sample Types, Box Size, Research, Clinical, Comments, Date Added
```

**Uses**:
- Import into lab management systems
- Share with collaborators
- Regulatory documentation
- Data analysis in Excel/R/Python

---

## 🆘 Troubleshooting

### Data Not Saving
**Symptoms**: Changes disappear after closing browser

**Solutions**:
- Check LocalStorage is enabled (not in private/incognito mode)
- Check browser storage isn't full
- Try different browser
- Use backup/restore to save to file instead

### Can't Find My Data
**Symptoms**: Data was there, now it's gone

**Possible Causes**:
- Browser cache cleared
- Different browser/device
- Private browsing mode
- Browser update reset storage

**Prevention**:
- Regular backups (JSON export)
- Use same browser consistently
- Don't use private mode for working

### Box Map Won't Load
**Symptoms**: Click "Box Map" but nothing happens

**Solutions**:
- Check JavaScript errors in console (F12)
- Refresh page
- Try different browser
- Clear browser cache
- Re-add the box if corrupted

### CSV Upload Failed
**Symptoms**: Error message when uploading CSV

**Common Issues**:
- Wrong file format (must be .csv)
- Missing header row
- Invalid position names (must be A1 format)
- Extra columns or formatting

**Fix**:
- Download template from the app
- Copy your data into template format
- Don't modify header row
- Save as CSV (not Excel)

### Performance Slow
**Symptoms**: App becomes sluggish with many boxes

**Solutions**:
- System handles 1000+ boxes typically
- Try different browser (Chrome recommended)
- Export and archive old data
- Split into multiple freezers
- Use CSV export instead of viewing all at once

---

## 🎯 Example Workflows

### Workflow 1: New Lab Setup

1. **Initial Setup** (30 minutes):
   - Add all freezers with details
   - Establish naming conventions
   - Create backup schedule
   - Train team members

2. **Bulk Data Entry**:
   - Add all existing boxes manually OR
   - Create CSV template and bulk upload

3. **Ongoing Use**:
   - Add boxes as new samples arrive
   - Update box maps when samples added/removed
   - Export monthly for records
   - Weekly backups

### Workflow 2: Sample Retrieval

**Scenario**: Need to find "MS001" sample

1. **Search approach**:
   - Know which freezer? Switch to that tab
   - Know which box? Check box map
   - Don't know location? Export CSV and search in Excel

2. **Physical retrieval**:
   - Note: Shelf 3, Rack 2, Drawer 1, Box 5, Position A7
   - Retrieve box
   - Take sample
   - Update box map if sample removed

### Workflow 3: Moving Samples

**Scenario**: Reorganizing freezer space

1. **Before moving**:
   - Export CSV of current locations
   - Backup all data

2. **During move**:
   - Update each box position in app as you move it
   - OR note all moves, update in batch later

3. **After moving**:
   - Export new CSV
   - Compare old vs new locations
   - Verify no boxes lost

### Workflow 4: Lab Handoff

**Scenario**: New lab manager taking over

1. **Export everything**:
   - Backup all data (JSON)
   - Export CSV for each freezer
   - Document naming conventions

2. **Transfer**:
   - Send backup file to new manager
   - They restore from backup
   - Or email HTML file + backup file

3. **Verification**:
   - New manager spot-checks random boxes
   - Confirms data accuracy
   - Ready to maintain inventory

---

## 🔒 Data Privacy & Security

### What Data is Stored?

- Box locations and labels
- Sample types and descriptions
- Sample IDs
- Freezer details (model, serial, etc.)
- Comments and notes

### Where is Data Stored?

- **Locally only**: In your browser's LocalStorage
- **Not sent anywhere**: No external servers
- **Stays on your computer**: Data never leaves your device
- **Manual export only**: Only exported when you click export/backup

### Security Recommendations

**For sensitive data**:
- Use generic IDs, not patient names
- Keep master key separately (paper/secure database)
- Don't include PHI in box labels or comments
- Regular backups encrypted and stored securely
- Password-protect backup files
- Use institutional computers, not personal devices

**For regulated environments**:
- May not meet 21 CFR Part 11 requirements (no audit trail)
- Suitable for internal tracking only
- Export data to validated system for official records
- Consult your QA/compliance team

---

## 🤝 Contributing & Customization

### Customization Ideas

**Easy modifications** (no coding required):
- Default freezer name and details
- Sample type options
- Box size options
- Color scheme (CSS)

**Moderate modifications** (basic coding):
- Additional fields (owner, project, expiration date)
- Custom sample type categories
- Different grid sizes
- Custom export formats

**Advanced modifications** (significant coding):
- Integration with LIMS
- Barcode scanning
- Multi-user sync via database
- Advanced search and filtering
- Print box labels

All code is open source (MIT License) - feel free to modify!

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
