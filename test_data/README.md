# Test Data

This directory should contain small test datasets for pipeline validation.

## Required Files

For a minimal test, you need:

1. **Reference files** (subset of chr21):
   - `test_genome.fa` - Small reference genome
   - `test_genes.gtf` - Gene annotation
   - `hg38_ref.txt` - CIRCexplorer2 reference

2. **Sample data**:
   - `SAMPLE_1_1.fastq.gz` - Read 1
   - `SAMPLE_1_2.fastq.gz` - Read 2

## Generating Test Data

You can use the CIRIquant test data as a starting point:

```bash
# Download CIRIquant test data
wget https://github.com/Kevinzjy/CIRIquant/releases/download/v0.2.0/test_data.tar.gz
tar xzf test_data.tar.gz
```

## Running Tests

```bash
# Validate workflow
oxo-flow validate circrna.oxoflow

# Dry run
oxo-flow dry-run circrna.oxoflow

# Run with test data (adjust config first)
oxo-flow run circrna.oxoflow -j 4
```
