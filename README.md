# oxo-flow-circrna

circRNA detection pipeline built on [oxo-flow](https://github.com/Traitome/oxo-flow).

## Quick Start (3 steps)

```bash
# 1. Set reference_dir in circrna.oxoflow (the only path you need to configure)
#    reference_dir = "/data/references/GRCh38"

# 2. Place paired FASTQ files in raw/
#    raw/SAMPLE_01_1.fastq.gz, raw/SAMPLE_01_2.fastq.gz, ...

# 3. Run — indexes and environments are auto-built on first run
oxo-flow run circrna.oxoflow -j 16
```

**That's it.** No manual index building. No CSV files. No setup script required.

## Features

- **4 detection methods**: CIRIquant, CIRCexplorer2, find_circ, circRNA_finder
- **Ensemble aggregation**: High-confidence calls detected by >=2 methods
- **Auto-built indexes**: BWA, Bowtie2, STAR, HISAT2 indexes built automatically on first run
- **Tolerant callers**: Aggregation works even if some callers fail (2+ methods sufficient)
- **Single config**: Set `reference_dir` — all paths auto-derived
- **Sample auto-discovery**: Place FASTQ files in `raw/`, no CSV needed
- **Comprehensive reports**: HTML reports with statistics and visualizations

## Reference Data

Place your reference files in a directory with this structure:

```
/data/references/GRCh38/
├── genome.fa              # Reference FASTA (required)
├── genes.gtf              # Gene annotation (GENCODE, required)
└── hg38_ref.txt           # CIRCexplorer2 reference (optional: fetch_ucsc.py hg38 > hg38_ref.txt)
```

Set `reference_dir = "/data/references/GRCh38"` in `circrna.oxoflow`.

**All indexes are auto-built on first run** — BWA, Bowtie2, STAR, HISAT2, FASTA index,
and sequence dictionary. No manual index building needed.

> To skip auto-building (e.g., indexes already exist): `oxo-flow run circrna.oxoflow --skip-ref-build`

## Configuration

### circrna.oxoflow (the only file you need to edit)

```toml
[config]
# The only path you need to set:
reference_dir = "/data/references/GRCh38"

# Optional: override individual paths if your layout differs
# reference_fasta = "/custom/path/genome.fa"
# gene_annotation = "/custom/path/genes.gtf"
```

All other paths (bwa_index, bowtie2_index, star_index, hisat2_index, minimap2_index, gatk_dict, samtools_faidx) are auto-derived from `reference_dir`.

### Input Data

Place your paired-end FASTQ files in the `raw/` directory:

```
raw/
├── SAMPLE_01_1.fastq.gz
├── SAMPLE_01_2.fastq.gz
├── SAMPLE_02_1.fastq.gz
└── SAMPLE_02_2.fastq.gz
```

Samples are auto-discovered via `sample_pattern = "raw/{sample}_1.fastq.gz"`.
The sample list is available as `{config.samples_list}` in shell commands.
No CSV file needed.

## Output

| File | Description |
|------|-------------|
| `results/{sample}.CIRI.bed` | CIRIquant calls |
| `results/{sample}.circexplorer2.bed` | CIRCexplorer2 calls |
| `results/{sample}.find_circ.bed` | find_circ calls |
| `results/{sample}.circRNA_finder.bed` | circRNA_finder calls |
| `results/{sample}.aggr.txt` | Aggregated calls per sample |
| `results/results_circRNA.tsv.gz` | Combined circRNAs across all samples |
| `results/circrna_report.html` | HTML report |
| `results/multiqc_report.html` | QC summary |

## Pipeline Architecture

```
FASTQ → fastp → [4 callers in parallel] → aggregate → report
              ↓
           MultiQC
```

Callers are independent — aggregation works with 2+ of 4 methods succeeding.

## Requirements

- **oxo-flow** >= 0.9.0
- **Conda / Mamba / Micromamba** (auto-detected)
- **Memory**: 32GB recommended (CIRIquant and circRNA_finder need 32GB each)
- **Disk**: 50GB+ for indices, varies for outputs

## Troubleshooting

### Index building fails

If a tool is not installed, the auto-build will report which command failed.
Install the missing tool and re-run:
```bash
oxo-flow run circrna.oxoflow -j 16
```
Already-built indexes are tracked and never rebuilt unnecessarily.

### Memory warnings

Reduce the memory in config:
```toml
[defaults]
memory = "24G"
```

### Conda environment errors

```bash
# Re-create a specific environment
conda env create -f envs/ciriquant.yaml -n circrna_ciriquant

# Or run with --skip-env-setup if environments are pre-built
oxo-flow run circrna.oxoflow --skip-env-setup
```

### Some callers failed

The pipeline tolerates caller failures — aggregation runs as long as 2+ methods
produce output. Check individual caller logs in `results/{sample}.XXX/`.

## Custom Indexes

To add a custom index, declare it in `circrna.oxoflow`:

```toml
[[references]]
name = "my_index"
source = "{reference_dir}/genome.fa"
output = "{reference_dir}/my_index/idx"
build = "my_tool index {source} {output}"
description = "Custom index for my pipeline"
```

See [oxo-flow [[references]] docs](https://traitome.github.io/oxo-flow/reference/workflow-format/#references) for details.

## License

Apache 2.0

## References

- [CIRIquant](https://github.com/bioinfo-biols/CIRIquant)
- [CIRCexplorer2](https://circexplorer2.readthedocs.io/)
- [find_circ](https://github.com/marvin-jens/find_circ)
- [circRNA_finder](https://github.com/orzechoj/circRNA_finder)
- [oxo-flow engine](https://github.com/Traitome/oxo-flow)
