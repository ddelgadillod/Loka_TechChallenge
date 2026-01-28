#/bin/bash



jobThreads=12
jobMem=15
jobPath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge
idx=results
genexPath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_v3_NextGem_DI_CRISPR_A549_5K_gex_subsampled_3p
crisprPath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_v3_NextGem_DI_CRISPR_A549_5K_crispr_subsampled_3p



mkdir -p $jobPath/$idx/QC/genex
mkdir -p $jobPath/$idx/QC/crispr


fastqc -o $jobPath/$idx/QC/genex --nogroup -t $jobThreads $genexPath/*fastq.gz
fastqc -o $jobPath/$idx/QC/crispr --nogroup -t $jobThreads $crisprPath/*fastq.gz

multiqc --outdir $jobPath/$idx/QC $jobPath/$idx/QC/