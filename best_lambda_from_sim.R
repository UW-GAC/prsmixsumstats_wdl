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
parser$add_argument("--fit_params", type = "character", help = "Path to the file with alpha ad lambda (for plotting)", required = TRUE)
parser$add_argument("--seed", type = "integer", help = "seed for simulations", default = 123)
parser$add_argument("--nsim", type = "integer", help = "number of simulations", default = 5)

# Parse the arguments
args <- parser$parse_args()
combo_sumstats <- readRDS(args$sumstats)
fit_grid <- readRDS(args$glmnet_fit)
alpha_lambda <- readRDS(args$fit_params)
alpha_grid <- alpha_lambda$alpha
lambda_frac <- alpha_lambda$lambda
seed <- args$seed
nsim <- args$nsim

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

set.seed(seed)

vmat <- make_var_matrix(sumstats)
time_begin <-  proc.time()
wishart_sim <- sim_sumstats(vmat, nsim=nsim)
print(proc.time() - time_begin)

loss_sim <- eval_sim(wishart_sim, fit_grid, sumstats$vary)

loss_mean <- loss_sim$loss_mean
loss_sd   <- loss_sim$loss_sd

grid_indices <- loss_indices(loss_mean, loss_sd)

# Convert to long format for plotting
colnames(loss_mean) <- lambda_frac
rownames(loss_mean) <- alpha_grid
mat_long <- melt(loss_mean)
names(mat_long) <- c("alpha", "lambda", "loss")

mat_long$label <- rep("above", nrow(mat_long))

index_mat_to_vec <- function(i,j,nrow){
  k <-  i+(j - 1)*nrow
  return(k)
}
kmin <- index_mat_to_vec(grid_indices$loss_min_index[1], grid_indices$loss_min_index[2], nrow(loss_mean))
mat_long$label[kmin] <- "min"

k1sd <- index_mat_to_vec(grid_indices$loss_1sd_index[1], grid_indices$loss_1sd_index[2], nrow(loss_mean))
mat_long$label[k1sd] <- "min+1sd"

titl <- paste0("Loss across grid")
p <- ggplot(mat_long, aes(x = lambda, y = alpha, color = label)) + 
  geom_point(aes(size = loss)) +
  scale_color_manual(values = c("min" = "red", "min+1sd" = "#40E0D0", "above" = "black")) +
  labs(title = titl, x = "lambda_frac", y = "alpha")
ggsave("mean_loss_grid.pdf", p, width=7, height=6)


## No. Beta's Selected

countmin <- table(abs(fit_grid[[grid_indices$loss_min_index[1], grid_indices$loss_min_index[2]]]$beta) > 1e-6)
count1sd <- table(abs(fit_grid[[grid_indices$loss_1sd_index[1], grid_indices$loss_1sd_index[2]]]$beta) > 1e-6)

print(rbind(countmin, count1sd))

## save best models
best_model <- list(
    min = fit_grid[[grid_indices$loss_min_index[1], grid_indices$loss_min_index[2]]],
    min_1sd = fit_grid[[grid_indices$loss_1sd_index[1], grid_indices$loss_1sd_index[2]]]
)
saveRDS(best_model, file="best_model.rds")
