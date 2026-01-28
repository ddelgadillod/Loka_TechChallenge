/*
========================================================================================
    FASTQC Module
========================================================================================
*/

process FASTQC {
    tag "$sample_type"
    label 'process_medium'
    
    publishDir "${params.outdir}/QC/${sample_type}", mode: params.publish_dir_mode
    
    input:
    path(fastq_files)
    val(sample_type)
    
    output:
    path "*.html", emit: html
    path "*.zip" , emit: zip
    
    script:
    """
    mkdir -p fastqc_output
    
    fastqc \\
        --outdir fastqc_output \\
        --threads ${task.cpus} \\
        --nogroup \\
        ${fastq_files}
    

    mv fastqc_output/* .
    """
    
    stub:
    """
    mkdir -p fastqc_output
    touch fastqc_output/test_fastqc.html
    touch fastqc_output/test_fastqc.zip
    mv fastqc_output/* .
    """
}
