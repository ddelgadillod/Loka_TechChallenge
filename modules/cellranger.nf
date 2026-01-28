/*
========================================================================================
    CELLRANGER_MULTI Module
========================================================================================

*/

process CELLRANGER_MULTI {
    tag "$cellranger_id"
    label 'process_high'
    label 'process_long'
    
    publishDir "${params.outdir}", mode: params.publish_dir_mode
    
    input:
    val(genex_fastq_dir)
    val(crispr_fastq_dir)
    val(reference)
    val(feature_reference)
    val(cellranger_id)
    val(expect_cells)
    
    output:
    path "${cellranger_id}"              , emit: results
    path "${cellranger_id}_config.csv"   , emit: config
    path "${cellranger_id}/outs"         , emit: outs
    path "${cellranger_id}/outs/web_summary.html", emit: web_summary, optional: true
    
    script:
    // Get base names for FASTQ directories
    def genex_name = new File(genex_fastq_dir).name
    def crispr_name = new File(crispr_fastq_dir).name
    
    // Extract sample names (remove trailing paths)
    def genex_sample = genex_name.replaceAll(/_subsampled.*/, '')
    def crispr_sample = crispr_name.replaceAll(/_subsampled.*/, '')
    
    """
    # Create Cell Ranger config file
    cat > cellranger_config.csv << EOF
[gene-expression]
reference,${reference}
expect-cells,${expect_cells}
create-bam,${params.create_bam}

[feature]
reference,${feature_reference}

[libraries]
fastq_id,fastqs,feature_types,subsample_rate
${genex_sample},${genex_fastq_dir},Gene Expression,
${crispr_sample},${crispr_fastq_dir},CRISPR Guide Capture,
EOF

    echo "=== Cell Ranger Configuration ==="
    cat cellranger_config.csv
    echo "================================="
    
    # Run Cell Ranger Multi
    ${params.cellranger_path} multi \\
        --id="${cellranger_id}" \\
        --csv=cellranger_config.csv \\
        --localcores=${task.cpus} \\
        --localmem=${task.memory ? task.memory.toGiga() : 15} \\
        --disable-ui
    
    # Copy config file with ID
    cp cellranger_config.csv ${cellranger_id}_config.csv
    
    echo "Cell Ranger Multi completed successfully"
    """
    
    stub:
    """
    # Create stub output structure
    mkdir -p ${cellranger_id}/outs
    touch ${cellranger_id}/outs/web_summary.html
    touch ${cellranger_id}/outs/filtered_feature_bc_matrix.h5
    
    cat > cellranger_config.csv << EOF
[gene-expression]
reference,${reference}
expect-cells,${expect_cells}

[feature]
reference,${feature_reference}

[libraries]
fastq_id,fastqs,feature_types
stub_genex,${genex_fastq_dir},Gene Expression
stub_crispr,${crispr_fastq_dir},CRISPR Guide Capture
EOF
    
    cp cellranger_config.csv ${cellranger_id}_config.csv
    """
}
