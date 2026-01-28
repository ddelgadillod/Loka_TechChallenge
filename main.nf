#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
========================================================================================
    GeneXOmics Perturb-seq Pipeline - Nextflow Implementation
========================================================================================
    Pipeline for processing 10x Genomics Perturb-seq data with CRISPR guide capture
    
    This version uses subworkflows for better modularity:
    - QC subworkflow: FastQC + MultiQC
    - CELLRANGER_ANALYSIS subworkflow: Cell Ranger Multi
    
    Author: Diego A Delgadillo-Duran
    Version: 1.0.0
========================================================================================
*/

// Print pipeline header
log.info """\
    ========================================
     P E R T U R B - S E Q   P I P E L I N E
    ========================================
    Version               : 1.0.0
    Gene Expression FASTQ : ${params.genex_fastq}
    CRISPR FASTQ          : ${params.crispr_fastq}
    Reference Genome      : ${params.reference}
    Feature Reference     : ${params.feature_reference}
    Output Directory      : ${params.outdir}
    ========================================
    """
    .stripIndent()

/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

// Check required parameters
if (!params.genex_fastq) {
    exit 1, "Gene expression FASTQ directory not specified! Use --genex_fastq"
}
if (!params.crispr_fastq) {
    exit 1, "CRISPR FASTQ directory not specified! Use --crispr_fastq"
}
if (!params.reference) {
    exit 1, "Reference genome not specified! Use --reference"
}
if (!params.feature_reference) {
    exit 1, "Feature reference not specified! Use --feature_reference"
}

/*
========================================================================================
    CREATE INPUT CHANNELS
========================================================================================
*/

// Create channels for FASTQ files
Channel
    .fromPath("${params.genex_fastq}/*fastq.gz")
    .set { genex_fastq_ch }

Channel
    .fromPath("${params.crispr_fastq}/*fastq.gz")
    .set { crispr_fastq_ch }

/*
========================================================================================
    IMPORT SUBWORKFLOWS
========================================================================================
*/

include { QC } from './subworkflows/qc'
include { CELLRANGER_ANALYSIS } from './subworkflows/cellranger_analysis'

/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {
    
    //
    // SUBWORKFLOW: Quality Control (FastQC + MultiQC)
    //
    QC(
        genex_fastq_ch,
        crispr_fastq_ch
    )
    
    //
    // SUBWORKFLOW: Cell Ranger Multi Analysis
    //
    CELLRANGER_ANALYSIS(
        params.genex_fastq,
        params.crispr_fastq,
        params.reference,
        params.feature_reference,
        params.cellranger_id,
        params.expect_cells
    )
}

/*
========================================================================================
    WORKFLOW COMPLETION
========================================================================================
*/

workflow.onComplete {
    log.info """\
        ========================================
        Pipeline completed!
        Status    : ${workflow.success ? 'SUCCESS' : 'FAILED'}
        Duration  : ${workflow.duration}
        Results   : ${params.outdir}
        ========================================
        """
        .stripIndent()
}

workflow.onError {
    log.error "Pipeline failed with error: ${workflow.errorMessage}"
}
