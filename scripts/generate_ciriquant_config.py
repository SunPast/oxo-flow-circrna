#!/usr/bin/env python3
"""
Generate CIRIquant configuration from main config.toml.
This script reads config.toml and creates config/ciriquant_hg38.yml
so users only need to edit one configuration file.
"""

import os
import sys

try:
    import tomli
except ImportError:
    # Python 3.11+ has tomllib built-in
    import tomllib as tomli


def generate_ciriquant_config(config_path="config.toml", output_path="config/ciriquant_hg38.yml"):
    """Generate CIRIquant YAML config from main TOML config."""

    if not os.path.exists(config_path):
        print(f"Error: {config_path} not found")
        sys.exit(1)

    with open(config_path, "rb") as f:
        config = tomli.load(f)

    cfg = config.get("config", {})

    # Get reference directory or individual paths
    ref_dir = cfg.get("reference_dir", "")

    if ref_dir:
        # Derive paths from reference_dir
        fasta = os.path.join(ref_dir, "genome.fa")
        gtf = os.path.join(ref_dir, "genes.gtf")
        bwa_index = fasta  # BWA uses FASTA as index base
        hisat_index = fasta  # HISAT2 also uses FASTA as base
    else:
        # Use explicit paths
        fasta = cfg.get("reference_fasta", "/data/references/GRCh38/genome.fa")
        gtf = cfg.get("gene_annotation", "/data/references/GRCh38/genes.gtf")
        bwa_index = cfg.get("bwa_index", fasta)
        hisat_index = cfg.get("hisat2_index", fasta)

    # Generate YAML content
    yaml_content = f"""# CIRIquant configuration for hg38/GRCh38
# Auto-generated from config.toml - DO NOT EDIT MANUALLY

name: hg38

tools:
  bwa: bwa
  hisat2: hisat2
  stringtie: stringtie
  samtools: samtools

reference:
  fasta: {fasta}
  gtf: {gtf}
  bwa_index: {bwa_index}
  hisat_index: {hisat_index}
"""

    # Write output
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write(yaml_content)

    print(f"Generated: {output_path}")
    return output_path


if __name__ == "__main__":
    generate_ciriquant_config()