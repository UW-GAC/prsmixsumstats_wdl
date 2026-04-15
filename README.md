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
