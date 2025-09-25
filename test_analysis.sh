#!/bin/bash

# Simple test script to validate the R analysis script
echo "Testing R script with sample data..."

# Check if R is available
if ! command -v Rscript &> /dev/null; then
    echo "R is not available. This test requires R to be installed."
    exit 1
fi

# Check if required packages are available
Rscript -e "
required_packages <- c('glmnet', 'optparse', 'dplyr', 'ggplot2')
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly=TRUE)]
if (length(missing_packages) > 0) {
  cat('Missing required R packages:', paste(missing_packages, collapse=', '), '\n')
  quit(status=1)
}
cat('All required R packages are available\n')
"

if [ $? -ne 0 ]; then
    echo "Missing required R packages. Please install them first."
    exit 1
fi

# Create temporary test directory
TEST_DIR="/tmp/prsmix_test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Copy test data and script
cp /home/runner/work/prsmixsumstats_wdl/prsmixsumstats_wdl/example_data/sumstats.txt .
cp /home/runner/work/prsmixsumstats_wdl/prsmixsumstats_wdl/scripts/elastic_net_analysis.R .

# Run the analysis
echo "Running elastic net analysis..."
Rscript elastic_net_analysis.R --input sumstats.txt --output test_results --alpha 0.5 --nfolds 3

# Check if output files were created
if [ -f "test_results_coefficients.txt" ] && [ -f "test_results_performance.txt" ] && [ -f "test_results_plot.png" ]; then
    echo "SUCCESS: All output files were generated"
    echo "Generated files:"
    ls -la test_results_*
else
    echo "ERROR: Some output files are missing"
    ls -la
    exit 1
fi

# Clean up
rm -rf "$TEST_DIR"
echo "Test completed successfully!"