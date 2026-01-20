# DYMO 450 Label Converter

**Convert any image to high-contrast black & white format optimized for DYMO thermal label printers**

*By laboratorians, for laboratorians* 🔬

Created by [@tdoerks](https://github.com/tdoerks)

---

## 📋 What's This?

An interactive HTML tool that converts color or grayscale images into high-contrast black and white format, optimized for printing on DYMO 450 (and other thermal) label printers. Perfect for logos, calibration stickers, equipment labels, and more.

### Key Features:

- 🎨 **Real-time preview** - See original vs converted side-by-side
- ⚙️ **Adjustable settings** - Threshold, contrast, brightness
- 🔄 **Invert option** - Switch black/white backgrounds
- 📤 **Multiple formats** - Download as PNG or JPG
- 📱 **Drag & drop** - Easy file upload
- 🖼️ **All image types** - Supports TIF, PNG, JPG, BMP, GIF

---

## 🚀 Quick Start

1. **Download** the [DYMO Label Converter](./DYMO_Label_Converter.html)
2. **Open** in any web browser
3. **Upload** your image (drag & drop or click to browse)
4. **Adjust** threshold, contrast, and brightness sliders
5. **Preview** the converted result
6. **Download** as PNG (recommended) or JPG

No installation required! Works completely offline.

---

## ✨ Features Explained

### Threshold Control
**What it does**: Determines the cutoff point between black and white pixels

- **Lower values (0-127)**: More pixels become black (darker result)
- **Higher values (128-255)**: More pixels become white (lighter result)
- **Default: 128** (middle point)

**Use case**:
- Logo too faint? Lower threshold (more black)
- Text too thick? Raise threshold (more white)

### Contrast Control
**What it does**: Increases difference between light and dark areas

- **Lower (0.5-1.0)**: Softer edges, more gradual transition
- **Higher (1.5-3.0)**: Sharper edges, crisper details
- **Default: 1.5**

**Use case**:
- Blurry edges? Increase contrast
- Too harsh? Decrease contrast

### Brightness Control
**What it does**: Shifts overall lightness/darkness before thresholding

- **Negative (-100 to 0)**: Makes image darker
- **Positive (0 to +100)**: Makes image lighter
- **Default: 0** (no change)

**Use case**:
- Washed out image? Decrease brightness first
- Too dark overall? Increase brightness before threshold

### Invert Option
**What it does**: Reverses black and white

- **Unchecked**: White background, black foreground (standard)
- **Checked**: Black background, white foreground

**Use case**:
- Create negative/inverse labels
- White-on-black for high visibility
- Thermal printer shows opposite colors

---

## 🖨️ DYMO 450 Specifications

### Printer Details
- **Type**: Thermal label printer (no ink/toner)
- **Resolution**: 300 DPI
- **Print width**: Up to 2.25" (57mm)
- **Best format**: High-contrast black & white

### Common Label Sizes

| Size | Dimensions | Use Case |
|------|-----------|----------|
| **Small Address** | 1.125" x 3.5" (28mm x 89mm) | Small labels, barcodes |
| **Large Address** | 1.4" x 3.5" (36mm x 89mm) | Address labels |
| **Shipping** | 2.25" x 4" (57mm x 102mm) | Equipment labels |
| **Badge/Name** | 2.25" x 1.25" (57mm x 32mm) | Name tags, IDs |
| **Square** | 2" x 2" (51mm x 51mm) | Logos, calibration stickers |

### Recommended Settings for Logo Conversion

**For clean logos with text**:
- Threshold: 140-160
- Contrast: 2.0-2.5
- Brightness: +10 to +20

**For photographs/complex images**:
- Threshold: 120-140
- Contrast: 1.5-2.0
- Brightness: -10 to +10

**For faint/low contrast originals**:
- Threshold: 100-120
- Contrast: 2.5-3.0
- Brightness: -20 to 0

---

## 📖 Step-by-Step Guide

### Converting a Logo for Calibration Sticker

**Example**: Convert "CalibrationsInternationalLogoFinal.tif" for 2" x 2" label

1. **Upload the TIF file**
   - Drag & drop onto the upload area
   - OR click "Choose Image" button

2. **Initial preview**
   - Left side: Your original logo
   - Right side: Default conversion

3. **Adjust for clean text**
   - Threshold: 150 (to remove gray artifacts)
   - Contrast: 2.0 (to sharpen edges)
   - Brightness: +15 (if logo seems too dark)

4. **Check the preview**
   - Text should be clean and readable
   - No gray pixels (pure black & white only)
   - Logo elements should be distinct

5. **Download**
   - Click "Download as PNG" (best quality)
   - File saves as `dymo-label-bw.png`

6. **Print in DYMO Software**
   - Open DYMO Label Software
   - Insert image
   - Resize to fit label (e.g., 2" x 2")
   - Print

---

## 💡 Tips & Best Practices

### For Best Results

**Original image quality**:
- ✅ Use high resolution (300 DPI or higher)
- ✅ Clean, simple designs work best
- ✅ Bold fonts over thin fonts
- ⚠️ Avoid very fine details (may disappear)

**Conversion settings**:
- Start with default values
- Adjust threshold first (biggest impact)
- Then tweak contrast if needed
- Brightness as final adjustment

**Testing**:
1. Convert and preview in tool
2. Download PNG
3. Do a test print on one label
4. Adjust settings if needed
5. Print final batch

### Common Issues & Solutions

**Issue: Text is too thin or disappearing**
- ✅ **Solution**: Lower threshold (try 120-130)
- ✅ **Solution**: Decrease contrast slightly

**Issue: Background has gray spots/artifacts**
- ✅ **Solution**: Increase threshold (try 150-170)
- ✅ **Solution**: Increase contrast to 2.0+

**Issue: Image is too dark/too light**
- ✅ **Solution**: Adjust brightness first, then threshold

**Issue: Edges are jagged/pixelated**
- ✅ **Solution**: Start with higher resolution original
- ✅ **Solution**: Decrease contrast slightly
- ⚠️ **Note**: Thermal printers have resolution limits

**Issue: Logo doesn't fit label size**
- ✅ **Solution**: Resize in DYMO software (not in converter)
- ✅ **Solution**: Maintain aspect ratio when resizing

---

## 🎯 Use Cases

### Laboratory Equipment Labels

**Scenario**: Label all pipettes with lab name/logo

**Process**:
1. Convert lab logo to B&W
2. Print on 2" x 2" labels
3. Apply to equipment
4. Labels survive autoclaving (thermal print)

### Calibration Stickers

**Scenario**: Custom calibration certification labels

**Process**:
1. Design sticker with logo and text in any software
2. Export as high-res image
3. Convert to B&W with this tool
4. Print on appropriate size label
5. Apply to calibrated equipment

### Sample Container Labels

**Scenario**: High-contrast labels for freezer boxes

**Process**:
1. Create QR code or logo in any tool
2. Convert to pure B&W
3. Print on small labels
4. Labels remain readable at -80°C

### Name Badges/Tags

**Scenario**: Event name tags with organization logo

**Process**:
1. Upload organization logo
2. Convert to B&W
3. Print on badge labels
4. Cost-effective for large batches

---

## 🔧 Technical Details

### Technology Stack
- **Pure HTML/CSS/JavaScript** - No dependencies
- **Canvas API** - For image processing
- **File API** - For drag & drop upload
- **No server required** - Runs completely offline

### Image Processing Algorithm

1. **Load image** to canvas
2. **Convert to grayscale**: `gray = 0.299*R + 0.587*G + 0.114*B`
3. **Apply contrast**: `gray = ((gray/255 - 0.5) * contrast + 0.5) * 255`
4. **Apply brightness**: `gray = gray + brightness`
5. **Apply threshold**: `gray = gray > threshold ? 255 : 0`
6. **Optional invert**: `gray = 255 - gray`

### Browser Compatibility

- ✅ **Chrome/Edge** (recommended)
- ✅ **Firefox**
- ✅ **Safari**
- ✅ **Mobile browsers** (works on tablets)

### Limitations

- **Maximum file size**: Limited by browser memory (typically 100MB+)
- **Processing speed**: Large images (>5000px) may take a few seconds
- **Output format**: PNG or JPG only (no TIF export)

---

## 📊 Comparison: PNG vs JPG Output

| Format | Pros | Cons | Best For |
|--------|------|------|----------|
| **PNG** | Lossless, perfect quality | Slightly larger file | **Recommended** for labels |
| **JPG** | Smaller file size | Slight compression artifacts | OK for larger labels |

**Recommendation**: Always use PNG for DYMO labels. The file size difference is negligible for label-sized images, and quality is perfect.

---

## 🆘 Troubleshooting

### Tool won't load/work
**Solutions**:
- Check JavaScript is enabled
- Try different browser (Chrome recommended)
- Disable browser extensions
- Clear browser cache

### Image won't upload
**Solutions**:
- Check file format (TIF, PNG, JPG, etc.)
- Try smaller file size (<50MB)
- Use drag & drop instead of button
- Check file isn't corrupted

### Preview is blank
**Solutions**:
- Wait for processing (large images take time)
- Check browser console for errors (F12)
- Try reloading page
- Try different image

### Downloaded file won't open in DYMO software
**Solutions**:
- Use PNG format (not JPG)
- Check file downloaded completely
- Update DYMO software
- Try opening in image viewer first to verify

### Print quality is poor
**Solutions**:
- Start with higher resolution original
- Adjust threshold/contrast settings
- Do test print before full batch
- Clean DYMO printer head
- Check label type matches printer

---

## 🤝 Customization

### Easy Modifications (No Coding)
- Default threshold value (line ~200)
- Default contrast value (line ~208)
- Color scheme in CSS

### Moderate Modifications (Some Coding)
- Add more image filters
- Change output filename
- Add preset buttons for common settings
- Support for batch processing

### Advanced Modifications (Significant Coding)
- Add dithering algorithms
- Support for other printer types
- Direct DYMO printer integration
- Advanced image editing features

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
