# prsmixsumstats_wdl
Workflow for running an elastic net model on summary statistics

This workflow implements the elastic net model from the [prsmixsumstats](https://github.com/UW-GAC/prsmixsumstats) R package.


input | description
--- | ---
sumstats | RDS file with summary statistics
trait_type | "binary" or "quant"
maxiter | (optional) maximum number of iterations to attempt for each (alpha,lambda), default 500


output | description
--- | ---
glmnet_fit | RDS file with grid of fits for a range of alpha and lambda
glmnet_metrics | metrics corresponding to each element of glmnet_fit: AUC, loss, nbeta (count where abs(beta) > 1e-6)
best_model | RDS file with list of two models: min_loss and min_bic
mean_loss_plot | plot showing mean loss for each model in the grid, with best models highlighted

## export_best_weights.wdl

This workflow provides a method to create a tar archive with best weights files from `prsmixsumstats`.
It is primarily useful for exporting multiple weight files from AnVIL.

input | description
--- | ---
weight_files | Array of files to include in the tar archive
output_weight_file_prefixes | Array of strings to use as the prefix for each weight file
out_tar_file_prefix | Prefix of the output tar file to create


output | description
--- | ---
tar_file | Tar file named with `output_tar_file_prefix`.tar

For use on AnVIL, it is suggested to use data tables with the following inputs:

- Ancestry-unadjusted models:
    - weight_files:  `this.analysis_unadjusteds.weight_file`
    - output_weight_file_prefixes: `this.analysis_unadjusteds.analysis_unadjusted_id`
    - out_tar_file_prefix: `this.analysis_unadjusted_set_id`
- Ancestry-adjusted models:
    - weight_files:  `this.analysis_adjusteds.weight_file`
    - output_weight_file_prefixes: `this.analysis_adjusteds.analysis_adjusted_id`
    - out_tar_file_prefix: `this.analysis_adjusted_set_id`
