# COMPASS Pipeline - Claude Improvement Roadmap

**Branch:** `claude/pipeline-improvements`
**Created:** 2026-03-24
**Purpose:** Comprehensive analysis and improvement suggestions for COMPASS pipeline

---

## Executive Summary

Based on analysis of the current COMPASS pipeline (v1.0.1-candidate), this document outlines prioritized improvements across 5 categories:

1. **New Analysis Modules** - Add cutting-edge genomics tools
2. **Performance Optimization** - Improve speed and resource usage
3. **User Experience** - Better outputs, documentation, visualization
4. **Robustness** - Error handling, validation, recovery
5. **Data Integration** - Better metadata handling and result aggregation

---

## Priority 1: New Analysis Modules (High Impact)

### 1.1 Pangenome Analysis Module 🔥

**Rationale:** Critical for temporal studies (Pseudomonas, Vibrio, Salmonella)
- Track gene gain/loss over time
- Identify core vs accessory genome
- Detect horizontally transferred genes

**Tool:** Panaroo or Roary
- **Panaroo** (recommended): Graph-based, handles fragmented assemblies
- **Roary**: Fast, widely used, good for large datasets

**Implementation:**
```nextflow
process PANAROO {
    container 'quay.io/biocontainers/panaroo:1.5.0--pyhdfd78af_0'

    input:
    path(gff_files)  // From Prokka annotations

    output:
    path("panaroo_results/"), emit: results
    path("panaroo_results/gene_presence_absence.csv"), emit: matrix
    path("panaroo_results/core_gene_alignment.aln"), emit: alignment

    script:
    """
    panaroo \\
        -i *.gff \\
        -o panaroo_results \\
        --clean-mode strict \\
        --remove-invalid \\
        -t ${task.cpus}
    """
}
```

**Outputs:**
- Gene presence/absence matrix (critical for temporal analysis)
- Core genome alignment (for phylogeny)
- Pangenome graph
- Gene frequency statistics

**Integration:** Add to `subworkflows/comparative_genomics.nf`

### 1.2 Prokka Annotation Module

**Rationale:** Needed for pangenome, provides better gene predictions than PHANOTATE alone
- Required input for Panaroo
- Provides functional annotations
- Essential for comparative genomics

**Tool:** Prokka
- Fast, well-established
- Handles bacteria, archaea
- Outputs GFF3 for downstream tools

**Implementation:**
```nextflow
process PROKKA {
    container 'quay.io/biocontainers/prokka:1.14.6--pl5321hdfd78af_4'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_prokka/${meta.id}.gff"), emit: gff
    tuple val(meta), path("${meta.id}_prokka/${meta.id}.faa"), emit: proteins
    path("${meta.id}_prokka/"), emit: results

    script:
    """
    prokka \\
        --outdir ${meta.id}_prokka \\
        --prefix ${meta.id} \\
        --cpus ${task.cpus} \\
        --kingdom Bacteria \\
        --genus ${meta.organism} \\
        --usegenus \\
        ${assembly}
    """
}
```

### 1.3 SNP Calling Module

**Rationale:** Essential for outbreak investigation and phylogenetics
- Track mutations over time
- Identify transmission clusters
- Build high-resolution phylogenies

**Tool:** Snippy (variant calling against reference)
- Fast, simple, well-documented
- Handles haploid organisms
- Outputs VCF + annotated variants

**Implementation:**
```nextflow
process SNIPPY {
    container 'quay.io/biocontainers/snippy:4.6.0--hdfd78af_2'

    input:
    tuple val(meta), path(reads)
    path(reference)

    output:
    tuple val(meta), path("${meta.id}_snippy/"), emit: results
    tuple val(meta), path("${meta.id}_snippy/${meta.id}.vcf"), emit: vcf
    path("${meta.id}_snippy/${meta.id}.txt"), emit: summary

    script:
    """
    snippy \\
        --outdir ${meta.id}_snippy \\
        --ref ${reference} \\
        --R1 ${reads[0]} \\
        --R2 ${reads[1]} \\
        --cpus ${task.cpus} \\
        --prefix ${meta.id}
    """
}
```

**Add:** snippy-core for multi-sample alignment

### 1.4 Phylogenetic Tree Building 🌳

**Rationale:** Visualize temporal/geographic relationships
- Essential for all 3 temporal studies
- Complements MLST clustering
- Identifies clonal groups

**Tools:**
- **IQ-TREE** (maximum likelihood, best for publication)
- **FastTree** (fast approximation for large datasets)
- **RAxML-NG** (good balance)

**Recommend:** IQ-TREE for quality, FastTree for speed

**Implementation:**
```nextflow
process IQTREE {
    container 'quay.io/biocontainers/iqtree:2.2.2.6--hdbdd923_0'

    input:
    path(alignment)  // From Panaroo core genome or snippy-core

    output:
    path("alignment.treefile"), emit: tree
    path("alignment.iqtree"), emit: report

    script:
    """
    iqtree2 \\
        -s ${alignment} \\
        -m MFP \\
        -bb 1000 \\
        -nt ${task.cpus} \\
        --prefix alignment
    """
}
```

### 1.5 Prophage Integration Site Analysis

**Rationale:** Specialized for phage-rich studies
- Identify where prophages integrate (tRNA genes, etc.)
- Compare integration sites across serotypes/species
- Track prophage mobility

**Tool:** Custom script using VIBRANT output + assembly
- Parse VIBRANT boundaries
- Extract flanking sequences
- Identify integration sites (tRNA, genes, etc.)

**Output:** TSV with:
- Prophage ID
- Integration site type (tRNA, gene, intergenic)
- Flanking genes
- Repeat sequences

### 1.6 Virulence Factor Database Screening

**Rationale:** Complement AMR with virulence profiling
- VFDB (Virulence Factor Database)
- Track virulence genes on prophages vs plasmids
- Salmonella-specific: SPI islands, invasion genes

**Tool:** ABRicate with VFDB

**Already have ABRicate**, just add VFDB database:
```bash
abricate --setupdb
abricate --list  # Should include vfdb
```

**Update** `modules/abricate.nf` to run VFDB scan

---

## Priority 2: Performance Optimization

### 2.1 Conditional Process Execution

**Current issue:** All processes run regardless of organism
- SISTR runs on non-Salmonella (wastes resources)
- Species-specific tools could be conditional

**Solution:**
```nextflow
process SISTR {
    when:
    meta.organism =~ /Salmonella/

    // rest of process
}
```

**Apply to:**
- SISTR (Salmonella only)
- Future: Seroba (Streptococcus pneumoniae serotyping)
- Future: Kleborate (Klebsiella typing)

### 2.2 Caching Optimization

**Add cache hints for expensive processes:**
```nextflow
process ASSEMBLE_SPADES {
    cache 'lenient'  // Re-use if inputs similar (helpful for -resume)

    // process definition
}
```

### 2.3 Resource Tuning Based on Input Size

**Dynamic resource allocation:**
```nextflow
process ASSEMBLE_SPADES {
    cpus = { reads.size() > 500.MB ? 16 : 8 }
    memory = { reads.size() > 1.GB ? '64.GB' : '32.GB' }
}
```

**Benefit:** Saves resources on small datasets, allocates more for large

### 2.4 Parallel Sample Processing

**Current:** Good parallelization at process level
**Improvement:** Batch small processes

```nextflow
// Instead of 1 MLST job per sample, batch 10 samples
MLST(assemblies.collate(10))
```

**Trade-off:** Harder to resume, but faster for many small samples

---

## Priority 3: User Experience Improvements

### 3.1 Interactive Results Dashboard 📊

**Create web-based dashboard for results:**

**Tool:** R Shiny or Streamlit

**Features:**
- Upload MultiQC, COMPASS summary TSV
- Interactive plots:
  - Prophage prevalence over time
  - AMR heatmap by serotype
  - MLST clustering
  - Plasmid-prophage co-occurrence
- Downloadable figures (publication-ready)

**Location:** `bin/launch_dashboard.R` or `bin/launch_dashboard.py`

### 3.2 Automated Result Parsing Scripts

**Problem:** Users have to manually parse TSVs

**Solution:** Python scripts for common analyses

**Examples:**
```python
# bin/parse_vibrant_summary.py
- Count prophages per sample
- Group by quality (high/medium/low)
- Output: prophage_counts.tsv

# bin/parse_sistr_serotypes.py
- Extract serovar distribution
- Group by time period
- Output: serotype_distribution.tsv

# bin/parse_mobsuite_plasmids.py
- Incompatibility group frequencies
- Plasmid size distribution
- Output: plasmid_summary.tsv

# bin/categorize_amr_by_location.py  # 🔥 KEY FOR PHAGE STUDIES
- AMR genes on chromosome vs plasmid vs prophage
- Cross-reference AMRFinder + MOB-suite + VIBRANT
- Output: amr_location_matrix.tsv
```

### 3.3 Summary Statistics Module

**Add final process that generates:**
- Sample counts (total, passed QC, failed)
- Average prophage count
- AMR gene distribution
- Serotype breakdown (if Salmonella)
- Top MLST STs

**Output:** `summary/pipeline_statistics.txt`

### 3.4 Improved MultiQC Integration

**Add custom MultiQC modules for:**
- VIBRANT (prophage counts)
- SISTR (serotype distribution)
- MOB-suite (plasmid types)

**Location:** `assets/multiqc_config.yaml`

---

## Priority 4: Robustness & Error Handling

### 4.1 Pre-flight Checks Module

**Validate inputs before running:**
```nextflow
process VALIDATE_INPUTS {
    input:
    path(samplesheet)

    script:
    """
    #!/usr/bin/env python3
    import pandas as pd

    # Check CSV format
    df = pd.read_csv('${samplesheet}')

    # Check required columns
    assert 'sample' in df.columns
    assert 'organism' in df.columns

    # Check no duplicate samples
    assert not df['sample'].duplicated().any()

    # Check files exist (if fasta mode)
    if 'fasta' in df.columns:
        for fasta in df['fasta']:
            assert os.path.exists(fasta), f"Missing: {fasta}"

    print("✅ Input validation passed")
    """
}
```

### 4.2 Sample-Level Error Reporting

**Track which samples failed and why:**
```nextflow
process TRACK_FAILURES {
    input:
    path(failed_logs)

    output:
    path("failed_samples_report.tsv")

    script:
    """
    # Parse .failed.log files
    # Create TSV: sample_id, process_failed, error_message
    """
}
```

### 4.3 Automatic Re-run with Adjusted Resources

**If SPAdes fails with OOM, retry with 2x memory:**
```nextflow
process ASSEMBLE_SPADES {
    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
    maxRetries 2
    memory = { 32.GB * task.attempt }  // 32GB, then 64GB, then 128GB
}
```

### 4.4 Checkpointing for Long Runs

**Save progress markers:**
```nextflow
// After every 100 samples assembled, write checkpoint
// Enables smarter -resume
```

---

## Priority 5: Data Integration & Metadata

### 5.1 Metadata Integration Throughout Pipeline

**Problem:** Metadata (serotype, source, date) not linked to results

**Solution:** Carry metadata in `meta` map

**Example:**
```nextflow
// In data_acquisition, add metadata
meta.serotype = sistr_result
meta.mlst_st = mlst_result
meta.collection_date = from_sra_metadata

// Pass to all downstream processes
// Outputs include metadata columns
```

### 5.2 Master Results Table

**Combine all results into one TSV:**

**Columns:**
- Sample ID
- Organism
- MLST ST
- Serotype (if Salmonella)
- Assembly stats (N50, contigs, length)
- BUSCO completeness
- Prophage count
- Prophage quality scores
- Plasmid count
- Plasmid incompatibility groups
- AMR gene count
- AMR classes
- Source, date, location (if available)

**Tool:** `bin/create_master_results_table.py`

### 5.3 Time-Series Data Formatting

**For temporal studies, format results by time:**
```
results/
├── by_month/
│   ├── 2020-01_summary.tsv
│   ├── 2020-02_summary.tsv
│   └── ...
├── temporal_trends/
│   ├── prophage_prevalence_over_time.tsv
│   ├── amr_emergence_timeline.tsv
│   └── serotype_distribution_monthly.tsv
```

---

## Quick Wins (Implement First)

### 1. Add Prokka (needed for pangenome)
- **Time:** 2-3 hours
- **Impact:** Unlocks panar00, better annotations
- **Files:** `modules/prokka.nf`, update `subworkflows/assembly.nf`

### 2. Result parsing scripts
- **Time:** 4-6 hours for 5 scripts
- **Impact:** Huge UX improvement
- **Files:** `bin/parse_*.py`

### 3. Conditional SISTR
- **Time:** 30 minutes
- **Impact:** Saves resources on non-Salmonella
- **Files:** `modules/sistr.nf` (add `when:` clause)

### 4. AMR location categorization script 🔥
- **Time:** 3-4 hours
- **Impact:** **Critical for phage studies** - answers "which AMR genes on prophages?"
- **Files:** `bin/categorize_amr_by_location.py`

### 5. ✅ Prophage-Encoded AMR Detection 🔥🔥🔥
- **Status:** **COMPLETED** (2026-03-27)
- **Time:** ~6 hours
- **Impact:** **CRITICAL** - Identifies phage-mediated AMR spread
- **Files:**
  - `bin/intersect_prophage_amr.py` - Single sample analysis
  - `bin/batch_prophage_amr_analysis.sh` - Batch processing for datasets
  - `PROPHAGE_AMR_ANALYSIS.md` - Comprehensive documentation
- **Methodology:** Implements coordinate intersection from *Genes* 2024, 16(5), 656
- **Features:**
  - Terminal region filtering (5kb buffer) to exclude host contamination
  - Identifies AMR genes within internal prophage regions (high-confidence)
  - Batch processing for large datasets (Vibrio 3,750, Salmonella 2,700, diverse 1,000)
  - Comprehensive reporting with positive sample identification
- **Next Steps:**
  - [ ] Test on Vibrio cholerae (3,750 samples) - Expected: ~1-5% prophage-AMR prevalence
  - [ ] Test on Salmonella (2,700 samples)
  - [ ] Test on diverse bacteria (1,000 samples)
  - [ ] Add Nextflow module wrapper (v1.3)
  - [ ] Create HTML summary visualization (Tab 16)
  - [ ] Publish findings if significant prophage-AMR detected
- **Scientific Significance:** Prophage-encoded AMR can be horizontally transferred via transduction, representing a high-risk mechanism for rapid AMR dissemination

### 6. Master results table
- **Time:** 4-5 hours
- **Impact:** Single file with all results, easy to analyze
- **Files:** `bin/create_master_results_table.py`, `modules/compile_results.nf`

---

## Long-Term Enhancements

### Phase 2: Advanced Analysis
- Pangenome (Panaroo)
- SNP calling (Snippy)
- Phylogenetic trees (IQ-TREE)
- Prophage integration site analysis

### Phase 3: Visualization
- Interactive dashboard (R Shiny/Streamlit)
- Temporal plots (automated)
- Geographic maps (if location data)
- Phylogenetic tree viewer

### Phase 4: Specialized Modules
- Plasmid reconstruction (Unicycler for hybrid assembly)
- Prophage sequence extraction and clustering
- HGT detection (custom scripts)
- Resistome profiling

### Phase 5: Large-Scale Surveillance (v1.4+) 🔬

#### 5.1 Prophage-AMR Correlation Analysis
**Rationale:** For metagenomic-scale surveillance studies (1,000-100,000+ samples)
- Statistical association between prophage abundance and AMR prevalence
- Population-level trends across time/geography/host
- Inspired by metagenomic studies using RGI + Spearman correlation

**Prerequisites:**
- Large multi-sample datasets (>500 samples recommended)
- Sample metadata (time, location, source, etc.)
- Completed COMPASS runs on all samples

**Tool:** `bin/analyze_prophage_amr_correlation.py`

**Features:**
```python
# Spearman correlation analyses:
- Prophage count vs Total AMR gene count
- Prophage count vs Prophage-encoded AMR genes
- Prophage quality score vs AMR prevalence
- Temporal trends (prophage/AMR over time)
- Geographic patterns (if location metadata)
- Host/source associations (clinical vs environmental)
```

**Outputs:**
- Correlation matrices with p-values
- Scatter plots with regression lines
- Heatmaps (samples × prophage/AMR metrics)
- Statistical significance tests
- Publication-ready figures

**Use Cases:**
1. **Surveillance**: "Are prophages increasing alongside AMR in clinical isolates?"
2. **Epidemiology**: "Do certain geographic regions show prophage-AMR co-occurrence?"
3. **Temporal**: "Is prophage-mediated AMR spreading over time?"
4. **Ecological**: "Do environmental samples differ from clinical in prophage-AMR?"

**Example Usage:**
```bash
# After running COMPASS on 10,000 E. coli isolates
python3 bin/analyze_prophage_amr_correlation.py \
    --compass_results results/ \
    --metadata sample_metadata.csv \
    --output correlation_analysis/ \
    --group_by collection_year,source_type \
    --min_samples 100
```

**Comparison to Current Approach:**
- **Current (v1.2.0)**: Direct detection - "Which AMR genes are IN prophages?" (mechanistic)
- **Future (v1.4+)**: Correlation analysis - "Do prophages ASSOCIATE with AMR?" (epidemiological)
- **Complementary**: Direct detection proves mechanism, correlation shows population trends

**Implementation Priority:** LOW (Phase 5)
- Requires large datasets (currently testing on 163-2,493 samples)
- Most valuable for national surveillance programs with 10,000+ isolates
- Research groups typically have <1,000 samples (use direct detection instead)

**Scientific Precedent:**
- Metagenomic studies with 100,000+ samples show prophage-ARG enrichment in human-impacted environments
- Our approach adapts this for isolate genomics surveillance

**When to Implement:**
- v1.4 or later
- After COMPASS deployed in national surveillance context
- When user datasets regularly exceed 1,000 samples
- Community requests correlation analysis features

**Related Papers:**
- Liao et al. 2024, Nature Communications - Prophage-encoded ARGs in human-impacted environments
- Various gut microbiome studies using RGI + correlation on metagenomic data

---

## Implementation Plan

### Week 1: Quick Wins
- [ ] Add Prokka module
- [ ] Create result parsing scripts (5x)
- [ ] Add conditional SISTR
- [ ] AMR location categorization
- [ ] Master results table

### Week 2: Performance
- [ ] Dynamic resource allocation
- [ ] Caching optimization
- [ ] Sample-level error tracking

### Week 3: New Modules
- [ ] Panaroo (pangenome)
- [ ] Snippy (SNP calling)
- [ ] IQ-TREE (phylogeny)

### Week 4: Integration & Testing
- [ ] Metadata propagation
- [ ] Dashboard prototype
- [ ] Full pipeline test (100 samples)
- [ ] Documentation updates

---

## Testing Strategy

### Unit Tests
- Each new module tested independently
- Use test_data/ samples
- Verify outputs match expected format

### Integration Tests
- Full pipeline with new modules
- 10 samples, 3 organisms
- Check all outputs generated

### Performance Tests
- 100 samples
- Compare runtime before/after optimizations
- Measure resource usage

### Validation Tests
- Compare results to known standards
- Use Salmonella reference genomes
- Verify AMR/virulence calls

---

## Documentation Updates Needed

### 1. New README sections
- Pangenome analysis
- SNP calling workflow
- Phylogenetic analysis
- Result parsing tools

### 2. Tutorial: "Analyzing Temporal Phage Data"
- Step-by-step guide
- Use Salmonella study as example
- Show parsing, plotting, interpretation

### 3. FAQ
- "How do I find AMR genes on prophages?"
- "How do I build a phylogenetic tree?"
- "How do I identify HGT events?"

### 4. Troubleshooting Guide
- Common errors and solutions
- Resource optimization tips
- Resume strategies for large runs

---

## Metrics for Success

### Performance
- [ ] 20% faster on 1,000 sample dataset
- [ ] 30% reduction in failed jobs
- [ ] Resume works 100% of the time

### Usability
- [ ] Master results table used by all studies
- [ ] AMR categorization script run on all 3 phage studies
- [ ] Dashboard deployed for Salmonella analysis

### Scientific Impact
- [ ] Pangenome analysis reveals gene acquisition patterns
- [ ] SNP calling identifies transmission clusters
- [ ] AMR-prophage-plasmid linkage quantified

---

## Next Steps

1. **Review this roadmap** with Tyler
2. **Prioritize** features (Quick Wins first?)
3. **Start implementing** on `claude/pipeline-improvements` branch
4. **Test incrementally** on small datasets
5. **Merge** to scratch/main when validated

---

**Branch:** `claude/pipeline-improvements`
**Status:** Planning complete, ready to implement
**Est. completion:** 4 weeks for core features

Let me know which features to prioritize and I'll start implementing! 🚀
