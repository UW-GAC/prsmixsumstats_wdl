# prsmixsumstats_wdl
Workflow for running an elastic net model on summary statistics

This repository contains a WDL (Workflow Description Language) workflow that runs an R script to perform elastic net regression analysis on GWAS summary statistics data.

## Overview

The workflow performs the following steps:
1. Takes GWAS summary statistics as input
2. Performs quality control on the data
3. Runs elastic net regression with cross-validation
4. Outputs model coefficients, performance metrics, and a visualization

## Files

- `prsmixsumstats.wdl`: Main WDL workflow definition
- `scripts/elastic_net_analysis.R`: R script that performs the elastic net analysis
- `Dockerfile`: Docker container definition with required R packages
- `inputs.json`: Example input parameters file
- `example_data/sumstats.txt`: Sample summary statistics data

## Input Format

The summary statistics file should be tab-delimited with the following required columns:
- `SNP`: SNP identifier
- `BETA`: Effect size
- `SE`: Standard error of effect size
- `P`: P-value

Optional columns:
- `CHR`: Chromosome
- `POS`: Position
- `A1`: Effect allele
- `A2`: Reference allele

## Usage

### Using Cromwell

1. Install Cromwell workflow engine
2. Build the Docker image (optional - will use rocker/tidyverse by default):
   ```bash
   docker build -t prsmixsumstats:latest .
   ```
3. Run the workflow:
   ```bash
   java -jar cromwell.jar run prsmixsumstats.wdl --inputs inputs.json
   ```

### Parameters

- `sumstats_file`: Path to summary statistics file
- `output_prefix`: Prefix for output files (default: "prsmix_results")
- `alpha`: Elastic net mixing parameter, 0=ridge, 1=lasso (default: 0.5)
- `nfolds`: Number of cross-validation folds (default: 5)
- `docker_image`: Docker image to use (default: "rocker/tidyverse:4.3.0")

## Outputs

- `*_coefficients.txt`: Model coefficients
- `*_performance.txt`: Cross-validation performance metrics
- `*_plot.png`: Cross-validation error plot

## Requirements

- WDL workflow engine (Cromwell recommended)
- Docker
- R packages: glmnet, optparse, dplyr, ggplot2 (included in Docker image)
