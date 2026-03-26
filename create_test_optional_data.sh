#!/bin/bash
# Create dummy optional module data to make tabs 13-15 appear

set -e  # Exit on error
set -x  # Print commands as they execute

OUTDIR="data/validation/etec_results_v1.2.0"

echo "========================================"
echo "Creating dummy optional module data"
echo "========================================"
echo "Target directory: $OUTDIR"
echo ""

# Create dummy Panaroo data
mkdir -p ${OUTDIR}/panaroo
cat > ${OUTDIR}/panaroo/gene_presence_absence.csv << 'EOF'
Gene,Non-unique Gene name,Annotation,No. isolates,No. sequences,Avg sequences per isolate,E36,E562,E925,E1373,E1441,E1649,E1779,E2980
gene_0001,geneA,Hypothetical protein,8,8,1.0,1,1,1,1,1,1,1,1
gene_0002,geneB,DNA polymerase,8,8,1.0,1,1,1,1,1,1,1,1
gene_0003,geneC,Transport protein,7,7,1.0,1,1,1,1,1,1,1,0
gene_0004,geneD,Toxin,6,6,1.0,1,1,1,1,1,1,0,0
gene_0005,geneE,Adhesin,5,5,1.0,1,1,1,1,1,0,0,0
gene_0006,geneF,Resistance,3,3,1.0,1,1,1,0,0,0,0,0
gene_0007,geneG,Plasmid,2,2,1.0,1,1,0,0,0,0,0,0
gene_0008,geneH,Unique,1,1,1.0,1,0,0,0,0,0,0,0
EOF

# Create dummy IQ-TREE data
mkdir -p ${OUTDIR}/iqtree
cat > ${OUTDIR}/iqtree/alignment.treefile << 'EOF'
((E36:0.001,E562:0.002):0.003,(E925:0.001,(E1373:0.002,E1441:0.001):0.003):0.002,((E1649:0.001,E1779:0.002):0.003,E2980:0.001):0.002);
EOF

# Create dummy Snippy data
mkdir -p ${OUTDIR}/snippy
cat > ${OUTDIR}/snippy/core.txt << 'EOF'
	E36	E562	E925	E1373	E1441	E1649	E1779	E2980
E36	0	12	45	67	89	102	134	156
E562	12	0	38	55	77	94	122	148
E925	45	38	0	23	41	58	86	112
E1373	67	55	23	0	18	35	63	89
E1441	89	77	41	18	0	17	45	71
E1649	102	94	58	35	17	0	28	54
E1779	134	122	86	63	45	28	0	26
E2980	156	148	112	89	71	54	26	0
EOF

echo ""
echo "========================================"
echo "✅ DONE - Created dummy optional module data"
echo "========================================"
echo "Created in: ${OUTDIR}"
echo ""
echo "Verifying files..."
ls -lh ${OUTDIR}/panaroo/gene_presence_absence.csv
ls -lh ${OUTDIR}/iqtree/alignment.treefile
ls -lh ${OUTDIR}/snippy/core.txt
echo ""
echo "Now run: bash test_compass_summary_v1.2.0.sh"
echo "Tabs 13-15 should appear!"
