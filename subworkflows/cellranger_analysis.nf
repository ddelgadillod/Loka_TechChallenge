#!/usr/bin/env nextflow

/*
========================================================================================
    CELLRANGER_ANALYSIS SUBWORKFLOW - Enhanced with Sample IDs
========================================================================================

*/

process CELLRANGER_MULTI {
    tag "${cellranger_id}"
    publishDir "${params.outdir}/cellranger", mode: params.publish_dir_mode
    
    input:
    val genex_fastq_dir
    val crispr_fastq_dir
    val reference
    val feature_reference
    val cellranger_id
    val expect_cells
    val genex_sample_id      // NEW: Sample ID from params
    val crispr_sample_id     // NEW: Sample ID from params
    
    output:
    path "${cellranger_id}/outs/*", emit: results
    path "${cellranger_id}_config.csv", emit: config
    
    script:
    // Determine which cellranger command to use
    def cellranger_cmd = params.cellranger_path ?: 'cellranger'
    def memory_gb = task.memory ? task.memory.toGiga() : 15
    
    """
    # Create Cell Ranger config file
    cat > cellranger_config.csv << 'CONFIG_EOF'
[gene-expression]
reference,${reference}
expect-cells,${expect_cells}
create-bam,${params.create_bam}

[feature]
reference,${feature_reference}

[libraries]
fastq_id,fastqs,feature_types,subsample_rate
${genex_sample_id},${genex_fastq_dir},Gene Expression,
${crispr_sample_id},${crispr_fastq_dir},CRISPR Guide Capture,
CONFIG_EOF

    echo "=== Cell Ranger Configuration ==="
    cat cellranger_config.csv
    echo "================================="
    
    echo "Using Cell Ranger command: ${cellranger_cmd}"
    which ${cellranger_cmd} || echo "Cell Ranger path: ${cellranger_cmd}"

    # Run Cell Ranger Multi
    ${cellranger_cmd} multi \\
        --id="${cellranger_id}" \\
        --csv=cellranger_config.csv \\
        --localcores=${task.cpus} \\
        --localmem=${memory_gb} \\
        --disable-ui

    # Copy config file with ID
    cp cellranger_config.csv ${cellranger_id}_config.csv

    echo "Cell Ranger Multi completed successfully"
    """
}

workflow CELLRANGER_ANALYSIS {
    take:
    genex_fastq_dir
    crispr_fastq_dir
    reference_dir
    feature_reference_file
    cellranger_id
    expect_cells
    genex_sample_id      // NEW: Pass sample IDs
    crispr_sample_id     // NEW: Pass sample IDs
    
    main:
    // Pass all values including sample IDs
    CELLRANGER_MULTI(
        genex_fastq_dir,
        crispr_fastq_dir,
        reference_dir,
        feature_reference_file,
        cellranger_id,
        expect_cells,
        genex_sample_id,
        crispr_sample_id
    )
    
    emit:
    results = CELLRANGER_MULTI.out.results
    config  = CELLRANGER_MULTI.out.config
}
