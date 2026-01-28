#!/usr/bin/env nextflow

/*
========================================================================================
    QC SUBWORKFLOW
========================================================================================

*/

process FASTQC_GENEX {
    tag "genex"
    publishDir "${params.outdir}/qc/fastqc/genex", mode: params.publish_dir_mode
    
    input:
    path fastq_files
    
    output:
    path "*.{html,zip}", emit: fastqc_results
    
    when:
    !params.skip_fastqc
    
    script:
    // Determine which fastqc command to use
    def fastqc_cmd = params.fastqc_path ?: 'fastqc'
    
    """
    mkdir -p fastqc_output
    
    ${fastqc_cmd} \\
        --outdir fastqc_output \\
        --threads ${task.cpus} \\
        --nogroup \\
        ${fastq_files}
    
    mv fastqc_output/* .
    """
}

process FASTQC_CRISPR {
    tag "crispr"
    publishDir "${params.outdir}/qc/fastqc/crispr", mode: params.publish_dir_mode
    
    input:
    path fastq_files
    
    output:
    path "*.{html,zip}", emit: fastqc_results
    
    when:
    !params.skip_fastqc
    
    script:
    // Determine which fastqc command to use
    def fastqc_cmd = params.fastqc_path ?: 'fastqc'
    
    """
    mkdir -p fastqc_output
    
    ${fastqc_cmd} \\
        --outdir fastqc_output \\
        --threads ${task.cpus} \\
        --nogroup \\
        ${fastq_files}
    
    mv fastqc_output/* .
    """
}

process MULTIQC {
    publishDir "${params.outdir}/qc/multiqc", mode: params.publish_dir_mode
    
    input:
    path fastqc_files
    
    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data", emit: data
    
    when:
    !params.skip_multiqc
    
    script:
    // Determine which multiqc command to use
    def multiqc_cmd = params.multiqc_path ?: 'multiqc'
    
    """
    ${multiqc_cmd} \\
        --filename multiqc_report.html \\
        --force \\
        --interactive \\
        .
    """
}

workflow QC {
    take:
    genex_fastq_ch
    crispr_fastq_ch
    
    main:
    // Collect all gene expression FASTQ files
    genex_fastq_collected = genex_fastq_ch.collect()
    
    // Collect all CRISPR FASTQ files
    crispr_fastq_collected = crispr_fastq_ch.collect()
    
    // Run FastQC on gene expression FASTQs
    FASTQC_GENEX(genex_fastq_collected)
    
    // Run FastQC on CRISPR FASTQs
    FASTQC_CRISPR(crispr_fastq_collected)
    
    // Combine all FastQC results
    all_fastqc_results = FASTQC_GENEX.out.fastqc_results
        .mix(FASTQC_CRISPR.out.fastqc_results)
        .collect()
    
    // Run MultiQC on all FastQC results
    MULTIQC(all_fastqc_results)
    
    emit:
    multiqc_report = MULTIQC.out.report
    multiqc_data   = MULTIQC.out.data
}
