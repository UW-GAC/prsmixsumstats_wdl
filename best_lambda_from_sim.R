# Load the argparse library
library(argparse)
library(prsmixsumstats)
library(reshape2)
library(ggplot2)

# Create a parser object
parser <- ArgumentParser(description = "choose best lambda from simulations")

# Add arguments
parser$add_argument("--sumstats", type = "character", help = "Path to the summary statistics RDS file", required = TRUE)
parser$add_argument("--glmnet_fit", type = "character", help = "Path to the glmnet fit RDS file", required = TRUE)
parser$add_argument("--glmnet_auc", type = "character", help = "Path to the glmnet AUC RDS file", required = TRUE)
parser$add_argument("--fit_params", type = "character", help = "Path to the file with alpha ad lambda (for plotting)", required = TRUE)
parser$add_argument("--beta_names", type = "character", help = "Path to the file with beta names", required = TRUE)
parser$add_argument("--seed", type = "integer", help = "seed for simulations", default = 123)
parser$add_argument("--nsim", type = "integer", help = "number of simulations", default = 5)

# Parse the arguments
args <- parser$parse_args()
total_stats <- readRDS(args$sumstats)
fit_grid <- readRDS(args$glmnet_fit)
auc <- readRDS(args$glmnet_auc)
alpha_lambda <- readRDS(args$fit_params)
alpha_grid <- alpha_lambda$alpha_grid
lambda_frac <- alpha_lambda$lambda_frac
beta_names <- readRDS(args$beta_names)
seed <- args$seed
nsim <- args$nsim

sumst <- total_stats$sumstats
yvar <- total_stats$yvar
rm(total_stats)

set.seed(seed)

vmat <- make_var_matrix(sumst$xx, sumst$xy, yvar)

wishart_sim <- sim_sumstats(vmat, nsim=nsim)

eval_sim <- metrics_sim(wishart_sim, fit_grid, yvar)

loss_mean <- eval_sim$loss_mean
loss_sd <- eval_sim$loss_sd
index_alpha <- eval_sim$index_best[1]
index_lambda <- eval_sim$index_best[2]
index_long <- eval_sim$index_best[3]

# Convert to long format for plotting
colnames(loss_mean) <- lambda_frac
rownames(loss_mean) <- alpha_grid
mat_long <- melt(loss_mean)
names(mat_long) <- c("alpha", "lambda", "value")
mat_long$loss <- rep("above", nrow(mat_long))
mat_long$loss[index_long] <- "min-1sd"  


p <- ggplot(mat_long, aes(x = lambda, y = alpha, color = loss)) + 
  geom_point(aes(size = value)) +
  scale_color_manual(values = c("min-1sd" = "red", "above" = "black")) +
  labs(title = "mean loss across grid", x = "lambda", y = "alpha")
ggsave("mean_loss_grid.pdf", p, width=7, height=6)

## AUC of best model for training data
best_model <- list()
best_model$auc <- auc[index_alpha, index_lambda]

## more details about best beta
beta_best <- as.vector(fit_grid[[index_alpha, index_lambda]]$beta)
names(beta_best) <- beta_names
best_model$beta <- beta_best
best_model$beta_selected <- beta_best[abs(beta_best) > 1e-6]
saveRDS(best_model, file="best_model.rds")

p <- ggplot(tibble::tibble(beta_best), aes(beta_best)) + geom_histogram()
ggsave("hist_beta_best.pdf", p, width=7, height=6)

range(beta_best)
table(abs(beta_best) > 1e-6)
