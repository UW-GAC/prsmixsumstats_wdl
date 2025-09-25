#!/usr/bin/env Rscript

# Load required libraries
suppressPackageStartupMessages({
  library(optparse)
  library(glmnet)
  library(dplyr)
  library(ggplot2)
})

# Define command line options
option_list <- list(
  make_option(c("--input"), type="character", default=NULL,
              help="Input summary statistics file", metavar="FILE"),
  make_option(c("--output"), type="character", default="prsmix_results",
              help="Output prefix for results files", metavar="PREFIX"),
  make_option(c("--alpha"), type="double", default=0.5,
              help="Elastic net mixing parameter [default %default]", metavar="ALPHA"),
  make_option(c("--nfolds"), type="integer", default=5,
              help="Number of cross-validation folds [default %default]", metavar="NFOLDS")
)

# Parse arguments
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Check required arguments
if (is.null(opt$input)) {
  print_help(opt_parser)
  stop("Input file must be specified", call.=FALSE)
}

cat("Loading summary statistics from:", opt$input, "\n")

# Read summary statistics
sumstats <- read.table(opt$input, header=TRUE, stringsAsFactors=FALSE)

# Basic validation
required_cols <- c("SNP", "BETA", "SE", "P")
missing_cols <- setdiff(required_cols, colnames(sumstats))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse=", "))
}

cat("Loaded", nrow(sumstats), "variants\n")

# Filter variants (basic QC)
sumstats_clean <- sumstats %>%
  filter(!is.na(BETA), !is.na(SE), SE > 0, P > 0, P < 1) %>%
  mutate(Z = BETA / SE)

cat("After QC:", nrow(sumstats_clean), "variants\n")

# Prepare matrix for elastic net
# Using Z-scores as predictors and simulating a phenotype for demonstration
set.seed(42)
X <- matrix(sumstats_clean$Z, ncol=1)
colnames(X) <- "Z_score"

# For demonstration, create a simulated phenotype
# In practice, this would come from actual phenotype data
y <- rnorm(nrow(X), mean = 0.1 * X[,1], sd = 1)

cat("Running elastic net regression with alpha =", opt$alpha, "\n")

# Fit elastic net model with cross-validation
cv_fit <- cv.glmnet(X, y, alpha=opt$alpha, nfolds=opt$nfolds, standardize=TRUE)

# Extract coefficients at lambda.1se
coef_1se <- coef(cv_fit, s="lambda.1se")

# Create results data frame
coefficients_df <- data.frame(
  Feature = rownames(coef_1se),
  Coefficient = as.numeric(coef_1se),
  Lambda = cv_fit$lambda.1se
)

# Remove intercept row for cleaner output
coefficients_df <- coefficients_df[coefficients_df$Feature != "(Intercept)", ]

cat("Writing coefficients to:", paste0(opt$output, "_coefficients.txt"), "\n")
write.table(coefficients_df, 
            file=paste0(opt$output, "_coefficients.txt"),
            row.names=FALSE, quote=FALSE, sep="\t")

# Model performance metrics
performance_df <- data.frame(
  Metric = c("Lambda.min", "Lambda.1se", "CV.MSE.min", "CV.MSE.1se", "Alpha", "N.vars"),
  Value = c(cv_fit$lambda.min, cv_fit$lambda.1se, 
            min(cv_fit$cvm), cv_fit$cvm[cv_fit$index["1se",]],
            opt$alpha, nrow(sumstats_clean))
)

cat("Writing performance metrics to:", paste0(opt$output, "_performance.txt"), "\n")
write.table(performance_df,
            file=paste0(opt$output, "_performance.txt"),
            row.names=FALSE, quote=FALSE, sep="\t")

# Create cross-validation plot
cat("Creating CV plot:", paste0(opt$output, "_plot.png"), "\n")
png(paste0(opt$output, "_plot.png"), width=800, height=600)
plot(cv_fit, main=paste("Cross-Validation for Elastic Net (alpha =", opt$alpha, ")"))
dev.off()

cat("Analysis complete!\n")
cat("Output files:\n")
cat("  -", paste0(opt$output, "_coefficients.txt"), "\n")
cat("  -", paste0(opt$output, "_performance.txt"), "\n")
cat("  -", paste0(opt$output, "_plot.png"), "\n")