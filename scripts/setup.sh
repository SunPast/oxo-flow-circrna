#!/bin/bash
# oxo-flow-circrna Setup Script
# Run this once after cloning to prepare your environment

set -e

echo "=================================================="
echo "  oxo-flow-circrna Setup"
echo "=================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for required tools
echo -e "\n${YELLOW}[1/4] Checking dependencies...${NC}"

check_tool() {
    if command -v "$1" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 ($(command -v $1))"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 (not found)"
        return 1
    fi
}

MISSING=0
check_tool oxo-flow || MISSING=1
check_tool conda || check_tool mamba || check_tool micromamba || MISSING=1

if [ $MISSING -eq 1 ]; then
    echo -e "\n${RED}Missing required tools. Please install:${NC}"
    echo "  - oxo-flow: cargo install oxo-flow --git https://github.com/Traitome/oxo-flow"
    echo "  - conda/mamba/micromamba: https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

# Create user config if not exists
echo -e "\n${YELLOW}[2/4] Creating configuration files...${NC}"

if [ ! -f config.toml ]; then
    cp config/config.example.toml config.toml
    echo -e "  ${GREEN}✓${NC} Created config.toml from template"
else
    echo -e "  ${GREEN}✓${NC} config.toml already exists"
fi

if [ ! -f samples.csv ]; then
    cp samplesheet.example.csv samples.csv
    echo -e "  ${GREEN}✓${NC} Created samples.csv from template"
else
    echo -e "  ${GREEN}✓${NC} samples.csv already exists"
fi

# Create conda environments
echo -e "\n${YELLOW}[3/4] Creating conda environments...${NC}"
echo "  This may take 10-20 minutes on first run"

ENV_MANAGER="conda"
if command -v mamba &> /dev/null; then
    ENV_MANAGER="mamba"
fi

if command -v micromamba &> /dev/null; then
    ENV_MANAGER="micromamba"
fi

ENV_DIRS=("envs" ".envs")
ENV_DIR="envs"
for d in "${ENV_DIRS[@]}"; do
    if [ -d "$d" ]; then
        ENV_DIR="$d"
        break
    fi
done

for env_file in "$ENV_DIR"/*.yaml; do
    env_name=$(basename "$env_file" .yaml)
    echo -n "  Creating $env_name... "
    if $ENV_MANAGER env create -f "$env_file" --name "circrna_$env_name" -y 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC} (failed)"
        FAILED=1
    fi
done

# Generate CIRIquant config
echo -e "\n${YELLOW}[4/4] Generating CIRIquant config...${NC}"

if command -v python3 &> /dev/null; then
    if python3 scripts/generate_ciriquant_config.py; then
        echo -e "  ${GREEN}✓${NC} CIRIquant config generated"
    else
        echo -e "  ${YELLOW}⚠${NC} Could not auto-generate (see errors above). Edit config/ciriquant_hg38.yml manually"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Python3 not found. Edit config/ciriquant_hg38.yml manually"
fi

# Summary
echo -e "\n=================================================="
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Edit config.toml with your reference paths"
echo "  2. Edit samples.csv with your sample names"
echo "  3. Run: oxo-flow validate circrna.oxoflow"
echo "  4. Run: oxo-flow run circrna.oxoflow -j 16"
echo ""
echo "=================================================="
