# prsmixsumstats_wdl
Workflow for running an elastic net model on summary statistics

This workflow implements the elastic net model from the [prsmixsumstats](https://github.com/UW-GAC/prsmixsumstats) R package. 


input | description
--- | ---
sumstats | RDS file with summary statistics
maxiter | (optional) maximum number of iterations to attempt for each (alpha,lambda), default 500
seed | (optional) seed for simulations, default 123
nsim | (optional) number of simulations to generate, default 5


output | description
--- | ---
glmnet_fit | RDS file with grid of fits for a range of alpha and lambda
glmnet_metrics | metrics corresponding to each element of glmnet_fit: AUC, loss, nbeta (count where abs(beta) > 1e-6)
best_model | RDS file with list of two models: min and min_1sd
