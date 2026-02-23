# Load the argparse library
library(argparse)
library(prsmixsumstats)
library(reshape2)
library(ggplot2)

# Create a parser object
parser <- ArgumentParser(description = "choose best model from grid of alpha and lambda")

# Add arguments
parser$add_argument("--sumstats", type = "character", help = "Path to the summary statistics RDS file", required = TRUE)
parser$add_argument("--glmnet_fit", type = "character", help = "Path to the glmnet fit RDS file", required = TRUE)
parser$add_argument("--metrics", type = "character", help = "Path to the metrics RDS file", required = TRUE)
parser$add_argument("--fit_params", type = "character", help = "Path to the file with alpha and lambda (for plotting)", required = TRUE)

# Parse the arguments
args <- parser$parse_args()
combo_sumstats <- readRDS(args$sumstats)
fit_grid <- readRDS(args$glmnet_fit)
metrics_obs <- readRDS(args$metrics)
alpha_lambda <- readRDS(args$fit_params)
alpha_grid <- alpha_lambda$alpha
lambda_frac <- alpha_lambda$lambda

if ("sumstats" %in% names(combo_sumstats)) {
  sumstats <- combo_sumstats$sumstats
  beta_multiplier <- combo_sumstats$beta_multiplier
} else if (is(combo_sumstats, "sumstats")) {
  sumstats <- combo_sumstats
  beta_multiplier <- 1
} else {
  stop("Input file must be a sumstats object or a list with a sumstats element")
}
rm(combo_sumstats)

# Convert to long format for plotting

colnames(metrics_obs$loss_ssq) <- lambda_frac
rownames(metrics_obs$loss_ssq) <- alpha_grid
mat_long <- melt(metrics_obs$loss_ssq)

names(mat_long) <- c("alpha", "lambda", "loss")
mat_long$label <- rep("above", nrow(mat_long))

k <- index_mat_to_vec(metrics_obs$loss_min_index[1],metrics_obs$loss_min_index[2], nrow(metrics_obs$loss_ssq))
mat_long$label[k] <- "min-loss"

k <- index_mat_to_vec(metrics_obs$bic_min_index[1],metrics_obs$bic_min_index[2] , nrow(metrics_obs$loss_ssq))
mat_long$label[k] <- "min-bic"

titl <- paste0("Loss Across Grid")

p <- ggplot(mat_long, aes(x = lambda, y = alpha, color = label)) + 
  geom_point(aes(size = loss)) +
  scale_color_manual(values = c("min-loss" = "red", "min-bic" = "#40E0D0", "above" = "black")) +
  labs(title = titl, x = "lambda_frac", y = "alpha")

ggsave("mean_loss_grid.pdf", p, width=7, height=6)


## No. Beta's Selected

min_loss <- fit_grid[[metrics_obs$loss_min_index[1], metrics_obs$loss_min_index[2]]]
min_bic <- fit_grid[[metrics_obs$bic_min_index[1], metrics_obs$bic_min_index[2]]]

count_bic <- table(abs(min_bic$beta) > 0)
count_loss <- table(abs(min_loss$beta) > 0)
print(rbind(count_bic, count_loss))


## multiply by beta_multiplier to get back to original scale
stopifnot(all(names(min_loss$beta) == names(beta_multiplier)))
stopifnot(all(names(min_bic$beta) == names(beta_multiplier)))
min_loss$beta <- min_loss$beta * beta_multiplier
min_bic$beta <- min_bic$beta * beta_multiplier


## save best models
best_model <- list(
    min_loss = min_loss,
    min_bic = min_bic
)
saveRDS(best_model, file="best_model.rds")
