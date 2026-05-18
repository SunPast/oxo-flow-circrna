#!/bin/bash
# Reference path resolver for circRNA pipeline
# Sources this file to get resolved paths from reference_dir

# This function resolves individual paths from reference_dir
# Usage: source scripts/resolve_paths.sh
# Then use: $REFERENCE_FASTA, $GENE_ANNOTATION, etc.

resolve_reference_paths() {
    local config_file="${1:-config.toml}"

    # Default values
    REFERENCE_DIR=""
    REFERENCE_FASTA=""
    GENE_ANNOTATION=""
    BWA_INDEX=""
    HISAT2_INDEX=""
    BOWTIE2_INDEX=""
    STAR_INDEX=""
    CIRCEXPLORER2_REF=""

    if [ ! -f "$config_file" ]; then
        echo "Warning: $config_file not found, using environment variables"
        return 1
    fi

    # Parse TOML (simple grep-based parser)
    REFERENCE_DIR=$(grep -E '^reference_dir\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')
    REFERENCE_DIR=$(echo "$REFERENCE_DIR" | sed "s/^['\"]//;s/['\"]$//")

    # Check for explicit overrides first
    REFERENCE_FASTA=$(grep -E '^reference_fasta\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')
    GENE_ANNOTATION=$(grep -E '^gene_annotation\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')
    BWA_INDEX=$(grep -E '^bwa_index\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')
    HISAT2_INDEX=$(grep -E '^hisat2_index\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')
    BOWTIE2_INDEX=$(grep -E '^bowtie2_index\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')
    STAR_INDEX=$(grep -E '^star_index\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')
    CIRCEXPLORER2_REF=$(grep -E '^circexplorer2_ref\s*=' "$config_file" | sed "s/.*=\s*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/" | tr -d '"')

    # Derive from reference_dir if not explicitly set
    if [ -n "$REFERENCE_DIR" ]; then
        [ -z "$REFERENCE_FASTA" ] && REFERENCE_FASTA="$REFERENCE_DIR/genome.fa"
        [ -z "$GENE_ANNOTATION" ] && GENE_ANNOTATION="$REFERENCE_DIR/genes.gtf"
        [ -z "$BWA_INDEX" ] && BWA_INDEX="$REFERENCE_DIR/bwa/genome.fa"
        [ -z "$HISAT2_INDEX" ] && HISAT2_INDEX="$REFERENCE_DIR/hisat2/genome.fa"
        [ -z "$BOWTIE2_INDEX" ] && BOWTIE2_INDEX="$REFERENCE_DIR/bowtie2/genome.fa"
        [ -z "$STAR_INDEX" ] && STAR_INDEX="$REFERENCE_DIR/star"
        [ -z "$CIRCEXPLORER2_REF" ] && CIRCEXPLORER2_REF="$REFERENCE_DIR/hg38_ref.txt"
    fi

    export REFERENCE_DIR REFERENCE_FASTA GENE_ANNOTATION BWA_INDEX HISAT2_INDEX BOWTIE2_INDEX STAR_INDEX CIRCEXPLORER2_REF
}

# Automatically resolve if config.toml exists
if [ -f "config.toml" ]; then
    resolve_reference_paths "config.toml"
fi
