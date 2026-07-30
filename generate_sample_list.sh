#!/bin/bash

echo "sample,r1_fastq,r2_fastq" > samples.csv

INPUT_DIR="raw"
total=$(ls "${INPUT_DIR}"/*.gz 2>/dev/null | wc -l)
n_sample=$((total / 2))

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