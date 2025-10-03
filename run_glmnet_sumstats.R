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

# Parse the arguments
args <- parser$parse_args()
total_stats <- readRDS(args$sumstats)
maxiter <- args$maxiter

if ("sumstats" %in% names(total_stats)) {
  sumst <- total_stats$sumstats
  yvar <- total_stats$yvar
} else if (is(total_stats, "sumstats")) {
  sumst <- total_stats
  yvar <- 1
} else {
  stop("Input file must be a sumstats object or a list with a sumstats element")
}
rm(total_stats)

if (!attr(sumst, "centered")) {
  stop("sumstats must be centered")
}

penalty_factor <- rep(1,ncol(sumst$xx))

## alpha weights abs(beta) and (1-alpha) weights beta^2
alpha_grid <- seq(from=0.9, to=0.1, by= -0.1)
lambda_frac <- seq(from=1, to=0.05, by= -.05)

nlambda <- length(lambda_frac)
nalpha <- length(alpha_grid)

## note 2-dimensional grid of fits. Each fit is a list
## and all fits arranged as matrix (of lists)
fit_grid <- matrix(list(), nrow=nalpha, ncol=nlambda)

beta_init <- rep(0, ncol(sumst$xx))

for(i in 1:nalpha){
 
  alpha <- alpha_grid[i]
  lambda_max <- max(abs(sumst$xy))/alpha
  lambda_grid <- lambda_max * lambda_frac
 
  cat("================ alpha = ", alpha, ", lambda.frac = ", lambda_frac[1], " ==================\n")

  fit_grid[[i,1]] <- glmnet_sumstats(sumst, beta_init, alpha=alpha, lambda=lambda_grid[1], 
                                penalty_factor, maxiter=maxiter, tol=1e-7,f.adj=2.0, verbose=TRUE)
  for(j in 2:nlambda){
    ptm <- proc.time()
    cat("================ alpha = ", alpha, ", lambda.frac = ", lambda_frac[j], " ==================\n")

  ## use warm start for next fit
  beta_init <- fit_grid[[i,j-1]]$beta
  fit_grid[[i, j]] <-  glmnet_sumstats(sumst, beta_init, alpha=alpha, lambda=lambda_grid[j], 
                                    penalty_factor, maxiter=maxiter, tol=1e-7,f.adj=32.0, verbose=TRUE)
  ## print(proc.time() - ptm)
  }
}

## compute auc, loss, nbeta for each fit
ysum <- attr(sumst, "ysum")
nobs <- attr(sumst, "nobs")
ncase <- ysum
ncont <- nobs - ncase
auc <- nbeta <- loss <- matrix(0, nalpha, nlambda)
for(i in 1:nalpha){
  for(j in 1:nlambda){
  beta <- as.vector(fit_grid[[i,j]]$beta)
  tmp <- auc_glmnet_sumstats(beta, sumst$xx, yvar, ncase, ncont)
  auc[i,j] <- tmp$auc
  loss[i,j] <- yvar - 2*t(beta) %*% sumst$xy +  t(beta) %*% sumst$xx %*% beta
  nbeta[i,j] <- sum( abs(fit_grid[[i,j]]$beta) > 1e-6)
  } 
}

saveRDS(fit_grid, file="glmnet_sumstats_fit_grid.rds")
saveRDS(loss, file="glmnet_sumstats_loss.rds")
saveRDS(auc, file="glmnet_sumstats_auc.rds")
saveRDS(nbeta, file="glmnet_sumstats_nbeta.rds")
saveRDS(colnames(sumst$xx), file="glmnet_sumstats_beta_names.rds")
saveRDS(list(alpha=alpha_grid, lambda=lambda_frac), file="alpha_lambda.rds")
