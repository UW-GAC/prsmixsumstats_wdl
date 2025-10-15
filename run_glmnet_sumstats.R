library(argparse)
library(prsmixsumstats)

# Create a parser object
parser <- ArgumentParser(description = "run glmnet on summary statistics")

# Add arguments
parser$add_argument("--sumstats", type = "character", help = "Path to the summary statistics file", required = TRUE)
#parser$add_argument("--beta_init", type = "numeric", help = "beta_init", required = TRUE)
#parser$add_argument("--alpha", type = "numeric", help = "alpha", required = TRUE)
#parser$add_argument("--lambda", type = "numeric", help = "lambda", required = TRUE)
#parser$add_argument("--penalty_factor", type = "numeric", help = "penalty_factor")
parser$add_argument("--maxiter", type = "integer", help = "maxiter", default = 500)
parser$add_argument("--test", action = "store_true", help = "test run with smaller grid for alpha and lambda")

# Parse the arguments
args <- parser$parse_args()
combo_sumstats <- readRDS(args$sumstats)
maxiter <- args$maxiter

if ("sumstats" %in% names(combo_sumstats)) {
  sumstats <- combo_sumstats$sumstats
  sumstats$vary <- combo_sumstats$yvar
} else if (is(combo_sumstats, "sumstats")) {
  sumstats <- combo_sumstats
  sumstats$vary <- 1
} else {
  stop("Input file must be a sumstats object or a list with a sumstats element")
}
rm(combo_sumstats)

if (!attr(sumstats, "centered")) {
  stop("sumstats must be centered")
}

penalty_factor <- rep(1,ncol(sumstats$xx))


## alpha weights abs(beta) and (1-alpha) weights beta^2
alpha_grid <- (10:1)/10
lambda_frac <- exp(seq(from=log(1), to=log(.05), length=20))
if (args$test) {
    alpha_grid <- seq(from=0.9, to=0.1, by= -0.3)
    lambda_frac <- exp(seq(from=log(1), to=log(.05), length=4))     
}

nlambda <- length(lambda_frac)
nalpha <- length(alpha_grid)

## note 2-dimensional grid of fits. Each fit is a list
## and all fits arranged as matrix (of lists)

fit_grid <- matrix(list(), nrow=nalpha, ncol=nlambda)

beta_zero <- rep(0, ncol(sumstats$xx))
max_xy <- max(abs(sumstats$xy))

time_begin <-  proc.time()
for(i in 1:nalpha){
  alpha <- alpha_grid[i]
  lambda_max <- max_xy/alpha
  
  for(j in 1:nlambda){
    lambda <- lambda_frac[j]*lambda_max
    cat("================ alpha = ", alpha, ", lambda.frac = ", lambda_frac[j], ", lambda = ", lambda, " ==================\n")
    
    if(i==1 & j==1){
      beta_init <- beta_zero
    } else if (i > 1 & j == 1){
      beta_init <- fit_grid[[i-1,j]]$beta   ## use warm start for next fit
    } else {
      beta_init <- fit_grid[[i,j-1]]$beta   ## use warm start for next fit
    }
    
    ptm <- proc.time()
    fit_grid[[i,j]] <-  glmnet_sumstats(sumstats, beta_init, alpha=alpha, lambda=lambda, penalty_factor,  maxiter=500, tol=1e-5, verbose=FALSE)
    print(proc.time() - ptm)
  }
}
print(proc.time() - time_begin)

metrics_train <- metrics_sumstats(sumstats, fit_grid)

saveRDS(fit_grid, file="glmnet_sumstats_fit_grid.rds")
saveRDS(metrics_train, file="glmnet_sumstats_metrics.rds")
saveRDS(list(alpha=alpha_grid, lambda=lambda_frac), file="alpha_lambda.rds")
