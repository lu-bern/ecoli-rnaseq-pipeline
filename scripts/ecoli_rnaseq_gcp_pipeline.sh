#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/pipeline.env"

if [[ -f "${CONFIG_FILE}" ]]; then
  echo "Sourcing pipeline configuration from ${CONFIG_FILE}"
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
fi

WORKDIR="${WORKDIR:-${ROOT_DIR}/work}"
FASTQ_DIR="${FASTQ_DIR:-${WORKDIR}/raw_fastq}"
REFERENCE_DIR="${REFERENCE_DIR:-${WORKDIR}/reference}"
RESULTS_DIR="${RESULTS_DIR:-${WORKDIR}/results}"
THREADS="${THREADS:-4}"
BOWTIE2_INDEX_PREFIX="${BOWTIE2_INDEX_PREFIX:-ecoli_k12}"
ANNOTATION_GFF="${ANNOTATION_GFF:-GCF_000005845.2_ASM584v2_genomic.gff}"
GENOME_FASTA="${GENOME_FASTA:-GCF_000005845.2_ASM584v2_genomic.fna}"

mkdir -p "${REFERENCE_DIR}" "${FASTQ_DIR}" "${RESULTS_DIR}/aligned" "${RESULTS_DIR}/counts" "${RESULTS_DIR}/qc/raw_fastq" "${RESULTS_DIR}/qc/alignment"

echo "-------------------------------------------------------"
echo "PHASE 1: Checking reference data and working directories"
echo "-------------------------------------------------------"

if [[ ! -f "${REFERENCE_DIR}/${GENOME_FASTA}" || ! -f "${REFERENCE_DIR}/${ANNOTATION_GFF}" ]]; then
  echo "ERROR: Reference files missing in ${REFERENCE_DIR}"
  echo "Required files: ${GENOME_FASTA} and ${ANNOTATION_GFF}"
  exit 1
fi

if ! compgen -G "${FASTQ_DIR}/*_1.fastq.gz" > /dev/null; then
  echo "ERROR: No paired-end FASTQ files found in ${FASTQ_DIR}."
  exit 1
fi

echo "Found reference files: ${GENOME_FASTA} and ${ANNOTATION_GFF}"

echo "-------------------------------------------------------"
echo "PHASE 2: FastQC and MultiQC raw read QC"
echo "-------------------------------------------------------"
if command -v fastqc >/dev/null 2>&1; then
  fastqc -o "${RESULTS_DIR}/qc/raw_fastq" "${FASTQ_DIR}"/*_1.fastq.gz "${FASTQ_DIR}"/*_2.fastq.gz
  if command -v multiqc >/dev/null 2>&1; then
    multiqc "${RESULTS_DIR}/qc/raw_fastq" -o "${RESULTS_DIR}/qc"
  fi
else
  echo "FastQC is not installed. Skipping raw read QC."
fi

echo "-------------------------------------------------------"
echo "PHASE 3: Building/Checking Bowtie2 index"
echo "-------------------------------------------------------"
if [[ ! -f "${REFERENCE_DIR}/${BOWTIE2_INDEX_PREFIX}.1.bt2" ]]; then
  bowtie2-build "${REFERENCE_DIR}/${GENOME_FASTA}" "${REFERENCE_DIR}/${BOWTIE2_INDEX_PREFIX}" --threads "${THREADS}"
else
  echo "Index already exists. Skipping build."
fi

echo "-------------------------------------------------------"
echo "PHASE 4: Alignment, sorting, featureCounts, and alignment QC"
echo "-------------------------------------------------------"

for forward_fastq in "${FASTQ_DIR}"/*_1.fastq.gz; do
  [ -e "${forward_fastq}" ] || continue

  SAMPLENAME="$(basename "${forward_fastq}" _1.fastq.gz)"
  REVERSE="${FASTQ_DIR}/${SAMPLENAME}_2.fastq.gz"

  if [[ ! -f "${REVERSE}" ]]; then
    echo "Skipping ${SAMPLENAME}: missing reverse mate ${REVERSE}."
    continue
  fi

  echo ">>> Processing paired-end sample: ${SAMPLENAME}"

  bowtie2 -x "${REFERENCE_DIR}/${BOWTIE2_INDEX_PREFIX}" \
    -1 "${forward_fastq}" \
    -2 "${REVERSE}" \
    -S "${RESULTS_DIR}/aligned/${SAMPLENAME}.sam" \
    --threads "${THREADS}"

  samtools view -Sb "${RESULTS_DIR}/aligned/${SAMPLENAME}.sam" | \
    samtools sort -o "${RESULTS_DIR}/aligned/${SAMPLENAME}_sorted.bam"

  if command -v samtools >/dev/null 2>&1; then
    samtools flagstat "${RESULTS_DIR}/aligned/${SAMPLENAME}_sorted.bam" > "${RESULTS_DIR}/qc/alignment/${SAMPLENAME}.flagstat.txt"
  fi

  featureCounts -p --countReadPairs \
    -a "${REFERENCE_DIR}/${ANNOTATION_GFF}" \
    -o "${RESULTS_DIR}/counts/${SAMPLENAME}_counts.txt" \
    -t CDS \
    -g locus_tag \
    "${RESULTS_DIR}/aligned/${SAMPLENAME}_sorted.bam"

  rm -f "${RESULTS_DIR}/aligned/${SAMPLENAME}.sam"
done

echo "-------------------------------------------------------"
echo "PHASE 5: Counts summary"
echo "-------------------------------------------------------"
printf "%-20s | %-15s\n" "Sample Name" "Assigned Reads"
echo "---------------------|---------------------------------"

for count_file in "${RESULTS_DIR}/counts"/*_counts.txt; do
  [ -e "${count_file}" ] || continue
  SNAME="$(basename "${count_file}" _counts.txt)"
  VAL="$(awk 'NR>2 {sum+=$7} END {print sum}' "${count_file}")"
  printf "%-20s | %-15s\n" "${SNAME}" "${VAL}"
done

echo "-------------------------------------------------------"
echo "Pipeline execution finished successfully."
echo "Raw QC reports are in: ${RESULTS_DIR}/qc/"
echo "Counts are in: ${RESULTS_DIR}/counts/"
echo "Alignment results are in: ${RESULTS_DIR}/aligned/"
echo "-------------------------------------------------------"
