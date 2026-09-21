library(argparse)
library(prsmixsumstats)

# Create a parser object
parser <- ArgumentParser(description = "choose best model from grid of alpha and lambda")

# Add arguments
parser$add_argument("--sumstats", type = "character", help = "Path to the summary statistics RDS file", required = TRUE)
parser$add_argument("--glmnet_fit", type = "character", help = "Path to the glmnet fit RDS file", required = TRUE)
parser$add_argument("--metrics", type = "character", help = "Path to the metrics RDS file", required = TRUE)
parser$add_argument("--trait_type", type = "character", help = "binary or quant", required = TRUE)

# Parse the arguments
args <- parser$parse_args()
combo_sumstats <- readRDS(args$sumstats)
fit_grid <- readRDS(args$glmnet_fit)
metrics_obs <- readRDS(args$metrics)
trait_type <- args$trait_type

if ("sumstats" %in% names(combo_sumstats)) {
  sumstats <- combo_sumstats$sumstats
  beta_multiplier <- combo_sumstats$beta_multiplier
} else if (is(combo_sumstats, "sumstats")) {
  sumstats <- combo_sumstats
  beta_multiplier <- rep(1, length(ncol(sumstats$xx)))
} else {
  stop("Input file must be a sumstats object or a list with a sumstats element")
}
rm(combo_sumstats)

min_bic <- fit_grid[[metrics_obs$bic_min_index[1], metrics_obs$bic_min_index[2]]]
beta_bic <- min_bic$beta
is_pgs <- grepl("^PGS", names(beta_bic))

if (sum(beta_bic[is_pgs]) > 0) {
  fit_effects <- tryCatch({
    pgs_ensemble_sumstats(sumstats, beta = beta_bic,  
      beta_multiplier = beta_multiplier, trait_type = trait_type)
    }, error = function(e) {print(e); return(NULL)})
  fit_marginal <- tryCatch({
    pgs_marginal_sumstats(sumstats, beta = beta_bic,  
      trait_type = trait_type)
  }, error = function(e) {print(e); return(NULL)})
} else {
  fit_effects <- NULL
  fit_marginal <- NULL
}
saveRDS(fit_effects, "pgs_effects_min_bic.rds")
saveRDS(fit_marginal, "pgs_marginal_min_bic.rds")

