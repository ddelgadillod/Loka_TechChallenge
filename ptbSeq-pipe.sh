#!/bin/bash

# Configuración
jobThreads=12
jobMem=15
jobPath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge
idx=results

# Rutas de los archivos FASTQ
genexPath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_v3_NextGem_DI_CRISPR_A549_5K_gex_subsampled_3p
crisprPath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_v3_NextGem_DI_CRISPR_A549_5K_crispr_subsampled_3p

# Rutas para Cell Ranger
referencePath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/refdata-cellranger-arc-GRCh38-2020-A-2.0.0
featureReferencePath=/home/alejo/genexomics-perturbseq/round2/Loka_TechChallenge/test_files/SC3_sub3p/SC3_sub3p_v3_feature_reference.csv

# Directorio para Cell Ranger (en la ubicación actual)
cellrangerId="test_crm"
cellrangerWorkDir="."

# Crear directorios para QC
mkdir -p $jobPath/$idx/QC/genex
mkdir -p $jobPath/$idx/QC/crispr

# Paso 1: QC con FastQC
echo "Ejecutando FastQC para expresión génica..."
fastqc -o $jobPath/$idx/QC/genex --nogroup -t $jobThreads $genexPath/*fastq.gz

echo "Ejecutando FastQC para CRISPR..."
fastqc -o $jobPath/$idx/QC/crispr --nogroup -t $jobThreads $crisprPath/*fastq.gz

# Paso 2: MultiQC
echo "Ejecutando MultiQC..."
multiqc --outdir $jobPath/$idx/QC $jobPath/$idx/QC/

# Paso 3: Crear archivo de configuración para Cell Ranger
configFile="$cellrangerWorkDir/cellranger_config.csv"
echo "Creando archivo de configuración: $configFile"

cat > "$configFile" << EOF
[gene-expression]
reference,$referencePath
expect-cells,5000
create-bam,false

[feature]
reference,$featureReferencePath

[libraries]
fastq_id,fastqs,feature_types,subsample_rate
SC3_v3_NextGem_DI_CRISPR_A549_5K_gex,$genexPath,Gene Expression,
SC3_v3_NextGem_DI_CRISPR_A549_5K_crispr,$crisprPath,CRISPR Guide Capture,
EOF

echo "Archivo de configuración creado exitosamente."

# Paso 4: Cambiar al directorio de trabajo para Cell Ranger
cd "$cellrangerWorkDir"

# Paso 5: Ejecutar Cell Ranger Multi
echo "Ejecutando Cell Ranger Multi..."
cellranger-10.0.0/bin/cellranger multi \
  --id="$cellrangerId" \
  --csv="cellranger_config.csv" \
  --localcores=$jobThreads \
  --localmem=$jobMem \
  --disable-ui

# Paso 6: Mover resultados al directorio final
if [ -d "$cellrangerId" ]; then
    echo "Moviendo resultados al directorio de resultados..."
    mv "$cellrangerId" "$jobPath/$idx/"
    
    # También mover el archivo de configuración
    mv cellranger_config.csv "$jobPath/$idx/${cellrangerId}_config.csv"
    
    echo "Análisis completado. Resultados en: $jobPath/$idx/$cellrangerId"
    echo "Configuración guardada en: $jobPath/$idx/${cellrangerId}_config.csv"
else
    echo "Cell Ranger no produjo resultados esperados."
fi

echo "Proceso finalizado."
