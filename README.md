# Open Source Lab Resources

**Practical, free resources for modern laboratories**

*By laboratorians, for laboratorians* 🔬

Created by [@tdoerks](https://github.com/tdoerks)

---

## 🔬 What's Inside

This repository contains open-source resources designed to streamline laboratory operations, improve documentation, and enhance safety protocols. All resources are free to use, modify, and share.

### Current Resources:

#### 📋 [Freezer Defrosting Management](./freezer-defrost/)
Complete system for managing freezer defrosting procedures:
- **Interactive Sign** - Fill-in-the-browser HTML form with auto-calculations
- **Full SOP** - Comprehensive standard operating procedure
- **Features:**
  - Auto-calculates completion dates (24-48 hours)
  - Auto-calculates safe return dates (7 days)
  - NOW button for instant timestamp
  - Dynamic QR codes for emergency phone numbers
  - Color-coded sections for quick scanning
  - Auto-saves data in browser
  - Print-ready single-page layout

#### 🧮 [MiSeq Pooling Calculators](./miseq-pooling/)
Interactive calculators for Illumina MiSeq library pooling:
- **Standard MiSeq Calculator** - For v2/v3 chemistry
- **MiSeq i100 Calculator** - Optimized for i100 runs with PhiX toggle
- **Features:**
  - Auto-calculates equimolar pooling volumes
  - Molarity conversions (ng/µL → nM)
  - PhiX spike-in calculations (i100 version)
  - Color-coded warnings for problematic samples
  - Export data for records
  - Auto-saves in browser
  - Print-ready protocols

#### 🗂️ [Freezer & Fridge Inventory](./freezer-inventory/)
Comprehensive box-level sample inventory management system:
- **Multi-Freezer Support** - Manage unlimited freezers/fridges
- **Box-Level Tracking** - Track location and contents of each box
- **Visual Box Maps** - Interactive grid view of sample positions
- **Features:**
  - Shelf → Rack → Drawer → Box hierarchy
  - Sample types, box sizes, research/clinical flags
  - CSV import/export for bulk operations
  - Individual sample tracking within boxes
  - Backup/restore functionality
  - Statistics dashboard
  - Auto-saves in browser

#### 🎓 [Pipetting Tutorial](./pipetting-tutorial/)
Interactive animated tutorial for learning proper pipetting technique:
- **Step-by-Step Version** - Guided 4-step walkthrough for beginners
- **Complete Animation** - Full demonstration for quick reference
- **Features:**
  - Visual animations of plunger movement
  - Liquid transfer visualization
  - Detailed descriptions for each step
  - Best practices and common mistakes
  - Perfect for training new lab members

#### 🦠 [Bacterial Isolation Tracker](./bacterial-isolation-tracker/)
Complete LIMS for bacterial culture and sequencing workflows:
- **8-Stage Workflow** - Receipt → Culture → Extraction → QC → Sequencing
- **Batch Processing** - Handle multiple samples simultaneously
- **Comprehensive Tracking** - Reagent lots, technicians, equipment, QC data
- **Features:**
  - Auto-save with browser LocalStorage
  - CSV/JSON export for records
  - Search and filter capabilities
  - Status dashboard with visualizations
  - Dark mode support

#### 🏷️ [DYMO Label Converter](./dymo-label-converter/)
Convert images to high-contrast black & white for thermal label printers:
- **Real-time Preview** - See original vs converted side-by-side
- **Adjustable Settings** - Threshold, contrast, brightness controls
- **DYMO 450 Optimized** - Perfect for thermal label printing
- **Features:**
  - Drag & drop image upload
  - All image formats (TIF, PNG, JPG, BMP, GIF)
  - Invert option for white-on-black
  - Download as PNG or JPG
  - Perfect for logos, calibration stickers, equipment labels

#### 🧪 [EtOH Wash Volume Calculator](./etoh-wash-calculator/)
Compute ethanol/water volumes for bead-cleanup ethanol washes:
- **Live Calculation** - total, EtOH, and H₂O volumes update as you type
- **Fully Adjustable** - per-wash volume, wash count, %EtOH, and loss margin
- **Quick-Reference Table** - pre-computed volumes for common sample counts
- **Features:**
  - Sanity-check warning for an unusually high loss margin
  - Print-ready one-page bench sheet
  - No data saved - starts fresh from defaults every time

---

## 🚀 Quick Start

### Freezer Defrosting Sign

1. **Download** the [Interactive Sign](./freezer-defrost/Freezer_Defrosting_Sign_Interactive.html)
2. **Open** in any web browser (Chrome, Firefox, Safari, Edge)
3. **Click NOW** to set start time
4. **Fill in** contact and storage information
5. **Print** the completed sign
6. **Post** on your freezer during defrosting

### MiSeq Pooling Calculators

1. **Download** your version:
   - [Standard MiSeq](./miseq-pooling/MiSeq_Pooling_Sheet.html) - v2/v3 kits
   - [MiSeq i100](./miseq-pooling/MiSeq_i100_Pooling_Sheet.html) - i100 kit
2. **Open** in any web browser
3. **Enter** run details and sample data (ID, concentration, size)
4. **Watch** automatic molarity and volume calculations
5. **Export** or print your pooling protocol

### Freezer Inventory Manager

1. **Download** the [Inventory Manager](./freezer-inventory/Freezer_Inventory_Manager.html)
2. **Open** in any web browser
3. **Add freezers** with "Add Freezer" button
4. **Add boxes** with shelf, rack, drawer, position details
5. **Click "Box Map"** to track individual samples
6. **Export CSV** or backup all data regularly

### Pipetting Tutorial

1. **Download** your version:
   - [Step-by-Step](./pipetting-tutorial/Pipetting_Tutorial_Step_by_Step.html) - For learning
   - [Complete Animation](./pipetting-tutorial/Pipetting_Tutorial_Complete.html) - For reference
2. **Open** in any web browser
3. **Watch** animations and read descriptions
4. **Practice** with actual pipettes alongside tutorial

### Bacterial Isolation Tracker

1. **Download** the [Bacterial Tracker](./bacterial-isolation-tracker/Bacterial_Isolation_Tracker.html)
2. **Open** in any web browser
3. **Add samples** using single or bulk input
4. **Process through workflow** stages with batch capabilities
5. **Track reagents, QC data, and technicians**
6. **Export** CSV for analysis or JSON for backup

### DYMO Label Converter

1. **Download** the [Label Converter](./dymo-label-converter/DYMO_Label_Converter.html)
2. **Open** in any web browser
3. **Upload** your image (drag & drop or browse)
4. **Adjust** threshold, contrast, and brightness sliders
5. **Preview** the black & white conversion
6. **Download** as PNG for printing on DYMO 450

### EtOH Wash Volume Calculator

1. **Download** the [EtOH Wash Calculator](./etoh-wash-calculator/EtOH_Wash_Calculator.html)
2. **Open** in any web browser
3. **Enter** your number of samples
4. **Confirm or adjust** per-wash volume, wash count, %EtOH, and loss margin
5. **Read off** the total/EtOH/H₂O volumes, or check the quick-reference table
6. **Print** for a bench-ready sheet

No installation required! Works offline after first load.

---

## 💡 Features

- ✅ **No installation** - Just download and open in browser
- ✅ **Works offline** - No internet needed after initial load
- ✅ **Auto-calculations** - Dates compute automatically
- ✅ **Auto-save** - Never lose your data
- ✅ **Print-ready** - Optimized for 8.5" x 11" paper
- ✅ **Mobile-friendly** - Works on tablets and phones
- ✅ **Free & Open Source** - Use, modify, share freely

---

## 📚 Documentation

Each resource includes:
- Detailed README with usage instructions
- Standard Operating Procedures (SOPs)
- Screenshots and examples
- Best practices

---

## 🤝 Contributing

We welcome contributions from the laboratory community!

### How to contribute:
1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Ideas for contributions:
- New laboratory resources (inventory trackers, safety checklists, etc.)
- Translations to other languages
- Improvements to existing resources
- Bug fixes and enhancements

---

## 🛠️ Coming Soon

- Equipment maintenance logs
- Laboratory safety checklists
- More SOPs and templates

Have a suggestion? [Open an issue](../../issues)!

---

## 📖 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**TL;DR:** You can use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software freely. Just keep the copyright notice.

---

## 👤 About

These resources are developed by laboratory professionals with real-world experience in research, clinical, and academic settings. We understand the challenges of lab management because we live them every day.

**Created by:** Tyler Doerksen
**GitHub:** [@tdoerks](https://github.com/tdoerks)
**Background:** Bioinformatics, Laboratory Operations, Microbiology

---

## ⭐ Support This Project

If you find these resources helpful:
- ⭐ Star this repository
- 🍴 Fork it and customize for your lab
- 📢 Share it with colleagues
- 🐛 Report issues or suggest improvements
- 💡 Contribute new resources

---

## 🙏 Acknowledgments

Built by laboratorians who understand the daily challenges of running a lab. Special thanks to the open-source community for inspiration and tools that make this possible.

---

*Made with 🧬 for the laboratory community*
