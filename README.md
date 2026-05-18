# oxo-flow-circrna

A circRNA detection and analysis pipeline built on [oxo-flow](https://github.com/Traitome/oxo-flow).

## Overview

This pipeline detects circRNAs from paired-end RNA-seq FASTQ files using four complementary methods:
- **CIRIquant** - Alignment-based detection using BWA and HISAT2
- **CIRCexplorer2** - Junction-based detection using BWA
- **find_circ** - Anchor-based detection using Bowtie2
- **circRNA_finder** - Chimeric read detection using STAR

Results from all methods are aggregated to produce reliable, high-confidence circRNA calls.

## Features

- **Multi-method ensemble**: Combines 4 complementary circRNA detection tools
- **High-confidence calls**: Requires detection by >=2 methods with position tolerance
- **Gene annotation**: Maps circRNAs to gene symbols using GTF annotation
- **Comprehensive reports**: HTML reports with method comparison and statistics
- **Reproducible**: Conda environment management for each tool
- **Modular architecture**: Sub-workflow modules for easy customization

## Requirements

### Software
- oxo-flow >= 0.5.0
- Conda or Mamba (recommended)

### Reference Files
- Reference genome FASTA (e.g., GRCh38)
- Gene annotation GTF (e.g., GENCODE v34)
- Pre-built indices:
  - BWA index
  - Bowtie2 index
  - STAR index
  - HISAT2 index (for CIRIquant)

## Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_ORG/oxo-flow-circrna.git
cd oxo-flow-circrna

# Install oxo-flow (if not already installed)
cargo install oxo-flow --git https://github.com/Traitome/oxo-flow
```

## Quick Start

```bash
# 1. Configure the pipeline
cp config/config.example.toml config.toml
# Edit config.toml with your reference paths

# 2. Create samples.csv
# Format: sample,r1_fastq,r2_fastq

# 3. Validate the workflow
oxo-flow validate circrna.oxoflow

# 4. Run the pipeline
oxo-flow run circrna.oxoflow -j 16
```

## Configuration

### Main Configuration File

Create `config.toml` from the example:

```toml
[config]
# Reference genome and annotation
reference_fasta = "/path/to/GRCh38.primary_assembly.genome.fa"
gene_annotation = "/path/to/gencode.v34.annotation.gtf"

# Index paths
bwa_index = "/path/to/GRCh38.primary_assembly.genome.fa"
bowtie2_index = "/path/to/GRCh38.primary_assembly.bt2"
star_index = "/path/to/STAR_index"

# Tool configurations
ciriquant_config = "config/ciriquant_hg38.yml"
circexplorer2_ref = "/path/to/hg38_ref.txt"

[defaults]
threads = 8
memory = "16G"
```

### Sample Sheet Format

Create `samples.csv`:

```csv
sample,r1_fastq,r2_fastq
SAMPLE_01,raw/SAMPLE_01_1.fastq.gz,raw/SAMPLE_01_2.fastq.gz
SAMPLE_02,raw/SAMPLE_02_1.fastq.gz,raw/SAMPLE_02_2.fastq.gz
```

## Pipeline Architecture

```
FASTQ Input
     |
   fastp (QC + Trimming)
     |
  +--+--+--+--+
  |  |  |  |  |
  |  |  |  |  +-- circRNA_finder --> .circRNA_finder.bed
  |  |  |  +----- find_circ -----------> .find_circ.bed
  |  |  +-------- CIRCexplorer2 --------> .circexplorer2.bed
  |  +----------- CIRIquant -------------> .CIRI.bed
  |
  +-- MultiQC --> multiqc_report.html

All BED files --> Aggregate --> all_circRNA.tsv.gz
                        |
                     Annotate
                        |
                     Report --> circrna_report.html
```

### Modules

| Module | File | Description |
|--------|------|-------------|
| QC | `rules/qc.oxoflow` | fastp trimming + MultiQC |
| Callers | `rules/callers.oxoflow` | All 4 circRNA detection tools |
| Annotation | `rules/annotation.oxoflow` | Placeholder for future use |
| Aggregation | `rules/aggregation.oxoflow` | Ensemble aggregation |
| Report | `rules/report.oxoflow` | HTML report generation |

## Output Files

### Per-Sample Outputs
- `{sample}.CIRI.bed` - CIRIquant circRNA calls (7 columns)
- `{sample}.circexplorer2.bed` - CIRCexplorer2 calls (5 columns)
- `{sample}.find_circ.bed` - find_circ calls (6 columns)
- `{sample}.circRNA_finder.bed` - circRNA_finder calls (5 columns)
- `{sample}.aggr.txt` - Aggregated circRNA calls for sample

### Final Outputs
- `all_circRNA.tsv.gz` - Combined circRNAs across all samples
- `circrna_report.html` - Comprehensive HTML report
- `multiqc_report.html` - QC metrics summary

### Aggregated Output Format

`all_circRNA.tsv.gz` columns:
- `chr` - Chromosome
- `start` - Start position (0-based)
- `end` - End position
- `strand` - Strand (+/-)
- `gene` - Gene symbol
- `tool` - Detecting tools (comma-separated)
- `count` - Average junction read counts
- `sample` - Sample identifier

## Environment Files

Each tool has its own conda environment:

| Environment | File | Tools |
|------------|------|-------|
| fastp | `envs/fastp.yaml` | fastp |
| multiqc | `envs/multiqc.yaml` | MultiQC |
| ciriquant | `envs/ciriquant.yaml` | CIRIquant, BWA, HISAT2, StringTie |
| circexplorer2 | `envs/circexplorer2.yaml` | CIRCexplorer2, BWA |
| findcirc | `envs/findcirc.yaml` | find_circ, Bowtie2 |
| circrna_finder | `envs/circrna_finder.yaml` | circRNA_finder, STAR |
| annotation | `envs/annotation.yaml` | R, data.table |
| report | `envs/report.yaml` | R, rmarkdown, ggplot2, plotly |

## Testing

```bash
# Validate workflow structure
oxo-flow validate circrna.oxoflow

# Dry-run to preview execution
oxo-flow dry-run circrna.oxoflow

# View DAG
oxo-flow graph circrna.oxoflow | dot -Tpng > dag.png
```

See `test_data/README.md` for information on obtaining test data.

## Troubleshooting

### Common Issues

1. **Memory warnings**: Reduce `memory` in config if OOM occurs
2. **Missing indices**: Pre-build all required indices before running
3. **Environment setup**: Ensure conda/mamba is properly configured

### Logs

- Check `.oxo-flow/` directory for execution logs
- Each rule outputs to `results/{sample}.{tool}/` directories

## References

- [CIRIquant](https://github.com/bioinfo-biols/CIRIquant)
- [CIRCexplorer2](https://circexplorer2.readthedocs.io/)
- [find_circ](https://github.com/marvin-jens/find_circ)
- [circRNA_finder](https://github.com/orzechoj/circRNA_finder)
- [Original Pipeline](https://github.com/OncoHarmony-Network/circrna-pipeline)

## License

Apache 2.0 - See [LICENSE](LICENSE)

## Acknowledgments

This pipeline is based on the [circrna-pipeline](https://github.com/OncoHarmony-Network/circrna-pipeline) project and reimplemented using oxo-flow for improved reproducibility and performance.
