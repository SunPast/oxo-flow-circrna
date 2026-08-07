#!/bin/bash
set -euo pipefail

INPUT_DIR="raw"
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: ${INPUT_DIR}/ directory not found. Create it and place paired FASTQ files there." >&2
    exit 1
fi

echo "sample,r1_fastq,r2_fastq" > samples.csv

shopt -s nullglob
gz_files=("${INPUT_DIR}"/*.gz)
shopt -u nullglob

if [ ${#gz_files[@]} -eq 0 ]; then
    echo "Error: no .gz files found in ${INPUT_DIR}/. Place paired-end FASTQ files there." >&2
    exit 1
fi

n_sample=$((${#gz_files[@]} / 2))
echo "${n_sample} samples found."

for r1 in "${INPUT_DIR}"/*_1.fastq.gz; do
  sample=$(basename "$r1" "_1.fastq.gz")
  r2="${INPUT_DIR}/${sample}_2.fastq.gz"
  if [ -f "$r2" ]; then
    echo "$sample,${r1},${r2}" >> samples.csv
  else
    echo "Warning: ${r2} not found. Skip ${sample}" >&2
  fi
done
