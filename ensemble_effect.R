library(argparse)
library(prsmixsumstats)

# Create a parser object
parser <- ArgumentParser(description = "choose best model from grid of alpha and lambda")

# Add arguments
parser$add_argument("--sumstats", type = "character", help = "Path to the summary statistics RDS file", required = TRUE)
parser$add_argument("--glmnet_fit", type = "character", help = "Path to the glmnet fit RDS file", required = TRUE)
parser$add_argument("--metrics", type = "character", help = "Path to the metrics RDS file", required = TRUE)

# Parse the arguments
args <- parser$parse_args()
combo_sumstats <- readRDS(args$sumstats)
fit_grid <- readRDS(args$glmnet_fit)
metrics_obs <- readRDS(args$metrics)

if ("sumstats" %in% names(combo_sumstats)) {
  sumstats <- combo_sumstats$sumstats
} else if (is(combo_sumstats, "sumstats")) {
  sumstats <- combo_sumstats
} else {
  stop("Input file must be a sumstats object or a list with a sumstats element")
}
rm(combo_sumstats)

min_bic <- fit_grid[[metrics_obs$bic_min_index[1], metrics_obs$bic_min_index[2]]]
beta_bic <- min_bic$beta
is_pgs <- grepl("^PGS", names(beta_bic))
fit_effects <- pgs_ensemble_sumstats(sumstats, beta = beta_bic,  
                                     trait_type = "binary", 
                                     index_pgs = which(is_pgs), 
                                     index_covar = which(!is_pgs))

saveRDS(fit_effects, "pgs_effects_min_bic.rds")

