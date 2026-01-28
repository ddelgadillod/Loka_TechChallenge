#!/bin/bash -euo pipefail
# Create Cell Ranger config file
    cat > cellranger_config.csv << 'CONFIG_EOF'
[gene-expression]
reference,/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/refdata-cellranger-arc-GRCh38-2020-A-2.0.0
expect-cells,5000
create-bam,false

[feature]
reference,/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_sub3p_v3_feature_reference.csv

[libraries]
fastq_id,fastqs,feature_types,subsample_rate
SC3_v3_NextGem_DI_CRISPR_A549_5K_gex,/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_v3_NextGem_DI_CRISPR_A549_5K_gex_subsampled_3p,Gene Expression,
SC3_v3_NextGem_DI_CRISPR_A549_5K_crispr,/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_v3_NextGem_DI_CRISPR_A549_5K_crispr_subsampled_3p,CRISPR Guide Capture,
CONFIG_EOF

    echo "=== Cell Ranger Configuration ==="
    cat cellranger_config.csv
    echo "================================="
    
    echo "Using Cell Ranger command: cellranger"
    which cellranger || echo "Cell Ranger path: cellranger"

    # Run Cell Ranger Multi
    cellranger multi \
        --id="samples-ec" \
        --csv=cellranger_config.csv \
        --localcores=12 \
        --localmem=15 \
        --disable-ui

    # Copy config file with ID
    cp cellranger_config.csv samples-ec_config.csv

    echo "Cell Ranger Multi completed successfully"
