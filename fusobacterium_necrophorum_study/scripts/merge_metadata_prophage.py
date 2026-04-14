#!/usr/bin/env python3
"""
Merge SRA metadata with prophage counts
Analyze prophage burden associations with host, species, isolation source
"""
import pandas as pd
import sys

def main():
    print("Loading data...")

    # Load prophage counts
    prophage_file = '/fastscratch/tylerdoe/fusobacterium_results/analysis/prophage_counts_per_sample.tsv'
    prophage = pd.read_csv(prophage_file, sep='\t', header=None, names=['sample', 'prophage_count'])
    print(f"Loaded {len(prophage)} samples with prophage counts")

    # Load metadata
    metadata_file = 'data/fusobacterium_metadata.tsv'
    metadata = pd.read_csv(metadata_file, sep='\t')
    print(f"Loaded metadata for {len(metadata)} samples")

    # Merge
    merged = prophage.merge(metadata, left_on='sample', right_on='accession', how='left')
    print(f"Merged dataset: {len(merged)} samples")

    # Save full merged dataset
    output_file = 'data/fusobacterium_metadata_prophage_merged.tsv'
    merged.to_csv(output_file, sep='\t', index=False)
    print(f"\n✓ Saved merged data to {output_file}")

    # Analysis 1: Prophage Load by Host
    print("\n" + "="*70)
    print("ANALYSIS 1: Prophage Load by Host Species")
    print("="*70)
    host_stats = merged.groupby('host')['prophage_count'].agg(['count', 'mean', 'std', 'min', 'max'])
    host_stats = host_stats.sort_values('count', ascending=False)
    print(host_stats)

    # Analysis 2: Prophage Load by Subspecies
    print("\n" + "="*70)
    print("ANALYSIS 2: Prophage Load by Fusobacterium Subspecies")
    print("="*70)
    subspecies_stats = merged.groupby('sub_species')['prophage_count'].agg(['count', 'mean', 'std', 'min', 'max'])
    subspecies_stats = subspecies_stats.sort_values('count', ascending=False)
    print(subspecies_stats)

    # Analysis 3: Prophage Load by Isolation Source
    print("\n" + "="*70)
    print("ANALYSIS 3: Prophage Load by Isolation Source (Top 20)")
    print("="*70)
    source_stats = merged.groupby('isolation_source')['prophage_count'].agg(['count', 'mean', 'std', 'min', 'max'])
    source_stats = source_stats.sort_values('count', ascending=False).head(20)
    print(source_stats)

    # Analysis 4: Human vs Bovine Comparison
    print("\n" + "="*70)
    print("ANALYSIS 4: Human vs Bovine (Cattle) Prophage Load")
    print("="*70)
    human = merged[merged['host'] == 'Homo sapiens']['prophage_count']
    bovine = merged[merged['host'] == 'Bos taurus']['prophage_count']

    if len(human) > 0 and len(bovine) > 0:
        print(f"Human (n={len(human)}): {human.mean():.2f} ± {human.std():.2f} prophages/genome")
        print(f"Bovine (n={len(bovine)}): {bovine.mean():.2f} ± {bovine.std():.2f} prophages/genome")

        # Simple t-test
        from scipy import stats
        try:
            t_stat, p_val = stats.ttest_ind(human, bovine, equal_var=False)
            print(f"T-test: t={t_stat:.3f}, p={p_val:.4f}")
            if p_val < 0.05:
                print("★ SIGNIFICANT DIFFERENCE between human and bovine isolates!")
            else:
                print("No significant difference between human and bovine isolates")
        except:
            print("(Could not perform t-test - scipy not available)")

    # Analysis 5: F. necrophorum focus (your professor's interest)
    print("\n" + "="*70)
    print("ANALYSIS 5: F. necrophorum (Bovine Liver Abscess Pathogen)")
    print("="*70)
    necrophorum = merged[merged['sub_species'] == 'necrophorum']
    if len(necrophorum) > 0:
        print(f"F. necrophorum samples: {len(necrophorum)}")
        print(f"Prophage load: {necrophorum['prophage_count'].mean():.2f} ± {necrophorum['prophage_count'].std():.2f}")
        print(f"Hosts: {necrophorum['host'].value_counts().to_dict()}")
        print(f"Sources: {necrophorum['isolation_source'].value_counts().to_dict()}")
    else:
        print("No F. necrophorum samples found in dataset")

    # Analysis 6: Oral vs GI Tract
    print("\n" + "="*70)
    print("ANALYSIS 6: Oral vs GI Tract Prophage Load")
    print("="*70)

    # Define oral sources
    oral_keywords = ['oral', 'saliva', 'dental', 'plaque', 'mouth', 'tonsil']
    gi_keywords = ['stool', 'feces', 'colon', 'gut', 'intestin', 'ileum', 'caecum']

    oral = merged[merged['isolation_source'].str.lower().str.contains('|'.join(oral_keywords), na=False)]
    gi = merged[merged['isolation_source'].str.lower().str.contains('|'.join(gi_keywords), na=False)]

    if len(oral) > 0:
        print(f"Oral cavity (n={len(oral)}): {oral['prophage_count'].mean():.2f} ± {oral['prophage_count'].std():.2f} prophages/genome")

    if len(gi) > 0:
        print(f"GI tract (n={len(gi)}): {gi['prophage_count'].mean():.2f} ± {gi['prophage_count'].std():.2f} prophages/genome")

    print("\n" + "="*70)
    print("Analysis complete!")
    print("="*70)

if __name__ == "__main__":
    main()
