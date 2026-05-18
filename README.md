# oxo-flow-circrna

A circRNA detection and analysis pipeline built on [oxo-flow](https://github.com/Traitome/oxo-flow).

## Overview

This pipeline detects circRNAs from paired-end RNA-seq FASTQ files using four complementary methods:
- **CIRIquant** - Alignment-based detection using BWA and HISAT2
- **CIRCexplorer2** - Junction-based detection using BWA
- **find_circ** - Anchor-based detection using Bowtie2
- **circRNA_finder** - Chimeric read detection using STAR

Results from all methods are aggregated to produce reliable, high-confidence circRNA calls.

## Quick Start

```bash
# 1. Configure the pipeline
cp config/config.example.toml config.toml
# Edit config.toml with your reference paths

# 2. Validate
oxo-flow validate circrna.oxoflow

# 3. Run
oxo-flow run circrna.oxoflow -j 16
```

## Documentation

See [docs/](docs/) for detailed documentation.

## License

Apache 2.0 - See [LICENSE](LICENSE)
