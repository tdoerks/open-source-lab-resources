# COMPASS Pipeline Metro Map

This directory contains metro-style visualizations of the COMPASS pipeline workflow using [nf-metro](https://github.com/pinin4fjords/nf-metro).

## Files

- **compass_metro.mmd** - Metro map definition in Mermaid format with `%%metro` directives
- **compass_pipeline_dark.svg** - Rendered dark theme diagram (generated)
- **compass_pipeline_light.svg** - Rendered light theme diagram (generated)

## Pipeline Routes

The COMPASS pipeline supports 4 different input modes, visualized as colored metro lines:

| Route | Color | Description | Workflow |
|-------|-------|-------------|----------|
| **🔵 FASTA** | Blue | Pre-assembled genomes | Direct to QC → Analyses → Summary |
| **🟢 Metadata** | Green | NARMS database | Download SRA → Assembly → QC → Analyses → Summary |
| **🟠 SRA** | Orange | SRA accessions | Download → Assembly → QC → Analyses → Summary |
| **🟣 Assembly** | Purple | NCBI assemblies | Download → QC → Analyses → Summary |

## Pipeline Stations (Processes)

### Core Analysis Sections

All routes converge at the **Analysis Hub** where the following parallel analyses run:

1. **🦠 AMR Analysis** - Antimicrobial resistance detection
   - AMRFinder Plus
   - Abricate (multiple databases)

2. **🧬 Phage Analysis** - Prophage and phage detection
   - VIBRANT
   - DIAMOND search
   - PHANOTATE annotation

3. **🔬 Molecular Typing**
   - MLST
   - SISTR (Salmonella-specific)

4. **🧩 Mobile Elements**
   - MOB-suite plasmid reconstruction

5. **🌳 Comparative Genomics** (Optional)
   - Prokka annotation
   - Panaroo pangenome
   - IQ-TREE phylogeny

6. **💉 Prophage-AMR Intersection** (Optional)
   - Identifies AMR genes within prophage regions

### Final Outputs

- 📊 Summary TSV
- 🌐 Interactive HTML Report
- 📈 MultiQC Quality Report

## Installation

### Option 1: pip (Python 3.10+)
```bash
pip install nf-metro
```

### Option 2: conda
```bash
conda install -c bioconda nf-metro
```

### Option 3: From source
```bash
git clone https://github.com/pinin4fjords/nf-metro.git
cd nf-metro
pip install .
```

## Rendering the Diagram

### Dark Theme (Recommended)
```bash
nf-metro render docs/compass_metro.mmd \
    -o docs/compass_pipeline_dark.svg \
    --theme dark
```

### Light Theme
```bash
nf-metro render docs/compass_metro.mmd \
    -o docs/compass_pipeline_light.svg \
    --theme light
```

### nf-core Theme (with logo)
```bash
# First, add a COMPASS logo to docs/compass_logo.png
nf-metro render docs/compass_metro.mmd \
    -o docs/compass_pipeline_nfcore.svg \
    --theme nfcore \
    --logo docs/compass_logo.png
```

### Render All Themes
```bash
# Dark
nf-metro render docs/compass_metro.mmd -o docs/compass_pipeline_dark.svg --theme dark

# Light
nf-metro render docs/compass_metro.mmd -o docs/compass_pipeline_light.svg --theme light

# Display success message
echo "✅ Metro diagrams generated successfully!"
echo "   - docs/compass_pipeline_dark.svg"
echo "   - docs/compass_pipeline_light.svg"
```

## Usage in Documentation

### Markdown
```markdown
## Pipeline Overview

![COMPASS Pipeline Metro Map](docs/compass_pipeline_dark.svg)

The COMPASS pipeline provides 4 different entry points (routes) for genomic analysis,
all converging at a common analysis hub for comprehensive bacterial characterization.
```

### HTML
```html
<img src="docs/compass_pipeline_dark.svg" alt="COMPASS Pipeline Metro Map" width="100%">
```

## Metro Map Syntax Guide

The `.mmd` file uses Mermaid graph syntax extended with `%%metro` directives:

### Global Directives
```
%%metro title: COMPASS Pipeline - Comprehensive Omics Analysis
%%metro style: dark
```

### Section Directives (inside subgraphs)
```
subgraph amr_sect [AMR Analysis]
    %%metro direction: TB        # Top-to-bottom layout
    %%metro entry: top | route1,route2
    %%metro exit: bottom | route1,route2

    process1[Process Name]
    process2[Another Process]
end
```

### Route Edges
```
process1 -->|route1,route2,route3| process2
```

Routes listed in edge labels determine which colored lines use that connection.

## Customization

### Adding New Processes

1. Add the process as a station in the appropriate section:
   ```
   new_process[New Analysis Tool]
   ```

2. Connect it to the workflow:
   ```
   previous_step -->|fasta,metadata,sra,assembly| new_process
   new_process -->|fasta,metadata,sra,assembly| next_step
   ```

3. Re-render the diagram

### Changing Colors

Route colors are auto-assigned by nf-metro based on line IDs. The default palette works well for 4-6 routes.

### Layout Adjustments

Modify section directives to change layout:
- `%%metro direction: LR` - Left-to-right (horizontal)
- `%%metro direction: TB` - Top-to-bottom (vertical)
- `%%metro direction: RL` - Right-to-left
- `%%metro direction: BT` - Bottom-to-top

## Troubleshooting

### Issue: Diagram renders but routes are unclear
**Solution**: Check that all edges have consistent route IDs. Routes must flow continuously through stations.

### Issue: Section layout looks wrong
**Solution**: Try different `%%metro direction` values or adjust entry/exit points.

### Issue: Command not found: nf-metro
**Solution**: Ensure Python 3.10+ is installed and nf-metro is in your PATH.

### Issue: Missing dependencies
**Solution**: Install required packages:
```bash
pip install nf-metro pydantic pyyaml
```

## References

- **nf-metro GitHub**: https://github.com/pinin4fjords/nf-metro
- **nf-core Workflow Diagrams Guide**: https://nf-co.re/docs/guidelines/graphic_design/workflow_diagrams
- **Mermaid Documentation**: https://mermaid.js.org/
- **COMPASS Pipeline**: https://github.com/tdoerks/COMPASS-pipeline

## Maintenance

When updating the COMPASS pipeline:

1. **Add new processes** to the metro map definition
2. **Update route connections** if workflow changes
3. **Re-render diagrams** with nf-metro
4. **Update README** with new features
5. **Commit changes** to version control

## License

Metro map visualization uses nf-metro (MIT License).
COMPASS pipeline is licensed under MIT License.
