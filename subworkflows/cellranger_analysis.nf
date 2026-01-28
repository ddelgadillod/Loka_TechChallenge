#!/usr/bin/env nextflow

/*
========================================================================================
    CELLRANGER_ANALYSIS SUBWORKFLOW - FIXED
========================================================================================
    Runs Cell Ranger Multi for Perturb-seq data analysis
    Supports both local installations and containers
    
    IMPORTANT: All inputs are 'val' type to preserve full paths
========================================================================================
*/

process CELLRANGER_MULTI {
    tag "$sample_id"
    publishDir "${params.outdir}/cellranger", mode: params.publish_dir_mode
    
    input:
    val genex_fastq_dir
    val crispr_fastq_dir
    val reference
    val feature_reference
    val sample_id
    val expect_cells
    
    output:
    path "${sample_id}/outs/*", emit: results
    path "${sample_id}_config.csv", emit: config
    
    script:
    // Determine which cellranger command to use
    def cellranger_cmd = params.cellranger_path ?: 'cellranger'
    
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
genex,${genex_fastq_dir},Gene Expression,
crispr,${crispr_fastq_dir},CRISPR Guide Capture,
CONFIG_EOF

    echo "=== Cell Ranger Configuration ==="
    cat cellranger_config.csv
    echo "================================="
    
    echo "Using Cell Ranger command: ${cellranger_cmd}"
    which ${cellranger_cmd} || echo "Cell Ranger path: ${cellranger_cmd}"

    # Run Cell Ranger Multi
    ${cellranger_cmd} multi \\
        --id="${sample_id}" \\
        --csv=cellranger_config.csv \\
        --localcores=${task.cpus} \\
        --localmem=${task.memory.toGiga()} \\
        --disable-ui

    # Copy config file with ID
    cp cellranger_config.csv ${sample_id}_config.csv

    echo "Cell Ranger Multi completed successfully"
    """
}

workflow CELLRANGER_ANALYSIS {
    take:
    genex_fastq_dir
    crispr_fastq_dir
    reference_dir
    feature_reference_file
    sample_id
    expect_cells
    
    main:
    // Pass all values directly - no channel creation
    CELLRANGER_MULTI(
        genex_fastq_dir,
        crispr_fastq_dir,
        reference_dir,
        feature_reference_file,
        sample_id,
        expect_cells
    )
    
    emit:
    results = CELLRANGER_MULTI.out.results
    config  = CELLRANGER_MULTI.out.config
}
