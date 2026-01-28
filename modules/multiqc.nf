/*
========================================================================================
    MULTIQC Module
========================================================================================
*/

process MULTIQC {
    label 'process_low'
    
    publishDir "${params.outdir}/QC", mode: params.publish_dir_mode
    
    input:
    path(qc_files)
    
    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data"        , emit: data
    
    script:
    """
    multiqc \\
        --outdir . \\
        --filename multiqc_report.html \\
        --force \\
        .
    """
    
    stub:
    """
    mkdir multiqc_data
    touch multiqc_report.html
    """
}
