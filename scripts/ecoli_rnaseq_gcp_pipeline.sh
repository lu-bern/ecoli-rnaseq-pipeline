#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/pipeline.env"

if [[ -f "${CONFIG_FILE}" ]]; then
    echo "Sourcing pipeline configuration from ${CONFIG_FILE}"
    source "${CONFIG_FILE}"
fi

# Define the main working directory and fallback defaults
WORKDIR="${WORKDIR:-/mnt/data/rnaseq/work}"
THREADS="${THREADS:-4}"
BOWTIE2_INDEX_PREFIX="${BOWTIE2_INDEX_PREFIX:-ecoli_k12}"
ANNOTATION_GFF="${ANNOTATION_GFF:-GCF_000005845.2_ASM584v2_genomic.gff}"
GENOME_FASTA="${GENOME_FASTA:-GCF_000005845.2_ASM584v2_genomic.fna}"

# --- 1. VALIDATION & SETUP ---
# Ensure directories exist
mkdir -p ${WORKDIR}/reference ${WORKDIR}/raw_fastq ${WORKDIR}/results/aligned ${WORKDIR}/results/counts

echo "-------------------------------------------------------"
echo "PHASE 1: Verifying Local GCF Reference Files"
echo "-------------------------------------------------------"

# Corrected path: removed extra /work/
if [[ -f "${WORKDIR}/reference/${GENOME_FASTA}" && -f "${WORKDIR}/reference/${ANNOTATION_GFF}" ]]; then
    echo "Found reference files: ${GENOME_FASTA} and ${ANNOTATION_GFF}"
else
    echo "ERROR: Reference files missing in ${WORKDIR}/reference/"
    echo "Check for: ${GENOME_FASTA} and ${ANNOTATION_GFF}"
    exit 1
fi

echo "-------------------------------------------------------"
echo "PHASE 2: Building/Checking Bowtie2 Index"
echo "-------------------------------------------------------"
if [ ! -f "${WORKDIR}/reference/${BOWTIE2_INDEX_PREFIX}.1.bt2" ]; then
    bowtie2-build "${WORKDIR}/reference/${GENOME_FASTA}" "${WORKDIR}/reference/${BOWTIE2_INDEX_PREFIX}" --threads $THREADS
else
    echo "Index already exists. Skipping build."
fi
echo "-------------------------------------------------------"
echo "PHASE 3: Running Alignment & Counting"
echo "-------------------------------------------------------"

# Only loop through the _1 files
for forward_fastq in ${WORKDIR}/raw_fastq/*_1.fastq.gz; do
    [ -e "$forward_fastq" ] || continue
    
    # Correctly identify the sample name and the reverse mate
    SAMPLENAME=$(basename "$forward_fastq" _1.fastq.gz)
    REVERSE="${WORKDIR}/raw_fastq/${SAMPLENAME}_2.fastq.gz"
    
    echo ">>> Processing paired-end sample: $SAMPLENAME"
    
    # 1. Alignment (Paired-End) - Using both -1 and -2
    bowtie2 -x "${WORKDIR}/reference/${BOWTIE2_INDEX_PREFIX}" \
            -1 "$forward_fastq" \
            -2 "$REVERSE" \
            -S "${WORKDIR}/results/aligned/${SAMPLENAME}.sam" \
            --threads $THREADS

    # 2. Convert to BAM and Sort
    samtools view -Sb "${WORKDIR}/results/aligned/${SAMPLENAME}.sam" | \
    samtools sort -o "${WORKDIR}/results/aligned/${SAMPLENAME}_sorted.bam"
    
    # 3. Feature Counting
    # -p and --countReadPairs are essential for paired-end data
    featureCounts -p --countReadPairs \
                  -a "${WORKDIR}/reference/${ANNOTATION_GFF}" \
                  -o "${WORKDIR}/results/counts/${SAMPLENAME}_counts.txt" \
                  -t CDS \
                  -g locus_tag \
                  "${WORKDIR}/results/aligned/${SAMPLENAME}_sorted.bam"    

    rm "${WORKDIR}/results/aligned/${SAMPLENAME}.sam"
done

echo "-------------------------------------------------------"
echo "                FINAL CALCULATION SUMMARY              "
echo "-------------------------------------------------------"
printf "%-20s | %-15s\n" "Sample Name" "Gene Counts"
echo "---------------------|---------------------------------"

# Loop through the generated count files and extract the number of assigned reads
for count_file in ${WORKDIR}/results/counts/*_counts.txt; do
    [ -e "$count_file" ] || continue
    
    # Get the basename for the display
    SNAME=$(basename "$count_file" _counts.txt)
    
    # Extract the total assigned reads from the featureCounts summary (last column, second line)
    # This grabs the sum of successfully assigned reads for that sample
    VAL=$(awk 'NR>2 {sum+=$7} END {print sum}' "$count_file")
    
    printf "%-20s | %-15s\n" "$SNAME" "$VAL"
done
echo "-------------------------------------------------------"
echo "Pipeline execution finished successfully."
echo "Final counts are in: ${WORKDIR}/results/counts/"
echo "-------------------------------------------------------"
