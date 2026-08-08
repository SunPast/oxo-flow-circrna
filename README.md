# oxo-flow-circrna

circRNA detection pipeline built on [oxo-flow](https://github.com/Traitome/oxo-flow).

## Quick Start (3 steps)

```bash
# 1. Setup
./scripts/setup.sh

# 2. Edit config.toml with your reference paths
#    Just set reference_dir="/path/to/your/GRCh38" and you're done!

# 3. Run
oxo-flow run circrna.oxoflow -j 16
```

## Features

- **4 detection methods**: CIRIquant, CIRCexplorer2, find_circ, circRNA_finder
- **Ensemble aggregation**: High-confidence calls detected by ≥2 methods
- **Single config file**: No need to edit multiple configuration files
- **Auto environment setup**: One script creates all conda environments
- **Comprehensive reports**: HTML reports with statistics and visualizations

## Reference Data Setup

Create a directory with this structure:

```
/data/references/GRCh38/
├── genome.fa              # Reference FASTA
├── genome.fa.fai          # FASTA index
├── genes.gtf              # Gene annotation (GENCODE)
├── hg38_ref.txt           # CIRCexplorer2 reference (run: fetch_ucsc.py hg38 > hg38_ref.txt)
├── bwa/                   # BWA index
│   └── genome.fa.bwt
├── bowtie2/               # Bowtie2 index
│   └── genome.fa.1.bt2
├── star/                  # STAR index
│   └── Genome
└── hisat2/                # HISAT2 index (for CIRIquant)
    └── genome.fa.ht2
```

Set `reference_dir = "/data/references/GRCh38"` in `config.toml`.

### Building Indices

```bash
# Create index directories
mkdir -p reference/{bwa,bowtie2,star,hisat2}

# BWA (for CIRIquant and CIRCexplorer2)
bwa index -p reference/bwa/genome.fa reference/genome.fa

# Bowtie2 (for find_circ)
bowtie2-build reference/genome.fa reference/bowtie2/genome.fa

# STAR (for circRNA_finder)
STAR --runMode genomeGenerate --genomeDir reference/star \
     --genomeFastaFiles reference/genome.fa --runThreadN 8

# HISAT2 (for CIRIquant)
hisat2-build reference/genome.fa reference/hisat2/genome.fa
```

## Configuration

### Minimal config.toml

```toml
[config]
reference_dir = "/data/references/GRCh38"
samples = "samples.csv"

[defaults]
threads = 8
memory = "16G"
```

### Input Data

Place your paired-end FASTQ files in the `raw/` directory before running the pipeline:

```
raw/
├── SAMPLE_01_1.fastq.gz
├── SAMPLE_01_2.fastq.gz
├── SAMPLE_02_1.fastq.gz
└── SAMPLE_02_2.fastq.gz
```

### Sample Discovery

Samples are auto-discovered from `raw/` using `sample_pattern` in `circrna.oxoflow`.
No CSV file needed — just place FASTQ files in `raw/`:

```
raw/
├── SAMPLE_01_1.fastq.gz
├── SAMPLE_01_2.fastq.gz
├── SAMPLE_02_1.fastq.gz
└── SAMPLE_02_2.fastq.gz
```

The sample list is available as `{config.samples_list}` in shell commands.

## Output

| File | Description |
|------|-------------|
| `results/{sample}.CIRI.bed` | CIRIquant calls |
| `results/{sample}.circexplorer2.bed` | CIRCexplorer2 calls |
| `results/{sample}.find_circ.bed` | find_circ calls |
| `results/{sample}.circRNA_finder.bed` | circRNA_finder calls |
| `results/{sample}.aggr.txt` | Aggregated calls per sample |
| `results/all_circRNA.tsv.gz` | Combined circRNAs across all samples |
| `results/circrna_report.html` | HTML report |
| `results/multiqc_report.html` | QC summary |

## Pipeline Architecture

```
FASTQ → fastp → [4 callers in parallel] → aggregate → report
              ↓
           MultiQC
```

## Requirements

- **oxo-flow** >= 0.5.0
- **Conda** or **Mamba**
- **Memory**: 32GB recommended (CIRIquant and circRNA_finder need 32GB each)
- **Disk**: 50GB+ for indices, varies for outputs

## Troubleshooting

### Memory warnings

If you see `may OOM` warnings, reduce the memory in config:

```toml
[defaults]
memory = "24G"
```

### Missing indices

Run the index building commands above. All indices must exist before running the pipeline.

### Conda environment errors

Run `./scripts/setup.sh` again or manually create environments:

```bash
conda env create -f envs/ciriquant.yaml -n circrna_ciriquant
```

## License

Apache 2.0

## References

- [CIRIquant](https://github.com/bioinfo-biols/CIRIquant)
- [CIRCexplorer2](https://circexplorer2.readthedocs.io/)
- [find_circ](https://github.com/marvin-jens/find_circ)
- [circRNA_finder](https://github.com/orzechoj/circRNA_finder)
- [Original pipeline](https://github.com/OncoHarmony-Network/circrna-pipeline)
