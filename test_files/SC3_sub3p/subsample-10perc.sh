#!/bin/bash

# Define the folders
folders=("SC3_v3_NextGem_DI_CRISPR_A549_5K_gex" "SC3_v3_NextGem_DI_CRISPR_A549_5K_crispr")

for dir in "${folders[@]}"; do
    echo "Processing $dir..."
    mkdir -p "${dir}_subsampled_3p"
    
    for file in "$dir"/*.fastq.gz; do
        filename=$(basename "$file")
        echo "  Subsampling $filename..."
        # -s100 ensures the same reads are picked across R1 and R2
        seqtk sample -s100 "$file" 0.03 | gzip > "${dir}_subsampled_3p/$filename"
    done
done