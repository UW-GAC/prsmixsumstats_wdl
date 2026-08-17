library(AnVIL)
library(readr)
library(argparser)
remotes::install_github("UW-GAC/prsmixsumstats")
library(prsmixsumstats)

# Create a parser object
parser <- arg_parser("combine sumstats")

# Add arguments
parser <- add_argument(parser, "--trait", type = "character", help = "trait")
parser <- add_argument(parser, "--trait_type", type = "character", help = "trait type (binary or quant)")
parser <- add_argument(parser, "--cluster", type = "character", help = "cluster")
parser <- add_argument(parser, "--adjusted", type = "character", help = "adjusted (TRUE or FALSE)")
parser <- add_argument(parser, "--drop_scores_file", type = "character", help = "file with scores to drop")
parser <- add_argument(parser, "--workspace", type = "character", help = "workspace name to fetch table of sumstats")
parser <- add_argument(parser, "--namespace", type = "character", help = "namespace to fetch table of sumstats")

# Parse the arguments
args <- parse_args(parser)

this_trait <- args$trait
trait_type <- args$trait_type
clust <- args$cluster
adjusted <- as.logical(args$adjusted)
drop_scores_file <- args$drop_scores_file
workspace <- args$workspace
namespace <- args$namespace
log <- "log.txt"

file_str <- if (adjusted) "sumstats_adjusted" else "sumstats_unadjusted"

sumst_tbl <- avtable(file_str, name=workspace, namespace=namespace) %>%
  filter(analysis == this_trait)

drop_scores <- readLines(drop_scores_file)
if (!adjusted) drop_scores <- paste0(drop_scores, "_SUM")
length(drop_scores)

drop_cols <- function(sumst_comb, drop) {
  nc1 <- ncol(sumst_comb$sumstats$xx)
  sumst_comb$sumstats <- drop_cols_sumstats(sumst_comb$sumstats, drop)
  sumst_comb$beta_multiplier <- sumst_comb$beta_multiplier[colnames(sumst_comb$sumstats$xx)]
  stopifnot(all(colnames(sumst_comb$sumstats$xx) == names(sumst_comb$beta_multiplier)))
  nc2 <- ncol(sumst_comb$sumstats$xx)
  cat(paste("dropped", nc1 - nc2, "columns"), "\n", file=log, append=TRUE)
  cat(paste("new ncol:", nc2), "\n", file=log, append=TRUE)
  return(sumst_comb)
}

cat(clust, "\n", file=log)
this <- sumst_tbl %>%
  filter(cluster == clust) 
files <- this %>%
  select(sumstat_file)
for (f in unique(unlist(files))) {
  local_file <- basename(f)
  suppressWarnings(gsutil_cp(f, local_file))
}

sumst_list <- list()
drop_list <- list()
for (i in 1:nrow(this)) {
  print(this[[paste0(file_str, "_id")]][i])
  cat(this[[paste0(file_str, "_id")]][i], "\n", file=log, append=TRUE)
  sumst <- readRDS(basename(this$sumstat_file[i]))
  covars <- colnames(sumst$xx)[!grepl("^PGS", colnames(sumst$xx))]
  cat(sort(covars), "\n", file=log, append=TRUE)
  pgs <- colnames(sumst$xx)[grepl("^PGS", colnames(sumst$xx))]
  cat(head(pgs), "\n", file=log, append=TRUE)
  # rename columns with incorrect names
  if ("bmi" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "bmi", "BMI")
  }
  if ("BMI_FINAL" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "BMI_FINAL", "BMI")
  }
  if ("Age" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "Age", "age")
  }
  if ("Age2" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "Age2", "age2")
  }
  if ("Sex" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "Sex", "sex")
  }
  if ("smoke_ever" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "smoke_ever", "smoking_ever")
  }
  if ("smoke_never" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "smoke_never", "smoking_never")
  }
  if ("systolic" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "systolic", "SBP")
  }
  if ("diastolic" %in% colnames(sumst$xx)) {
    sumst <- rename_col_sumstats(sumst, "diastolic", "DBP")
  }
  if (!adjusted) {
    # check that scores end with "_SUM"
    for (p in pgs) {
      if (!grepl("_SUM$", p)) {
        sumst <- rename_col_sumstats(sumst, p, paste0(p, "_SUM"))
      }
    }
  }
  sumst_list[[i]] <- sumst
}

# don't drop covariates even if they have small variance
covars <- colnames(sumst$xx)[!grepl("^PGS", colnames(sumst$xx))]
cat("don't drop covars:", "\n", file=log, append=TRUE)
cat(covars, "\n", file=log, append=TRUE)

sumst_comb <- combine_sumstats(sumst_list, no_drop=covars)

# remove AoU and excluded scores
sumst_comb <- drop_cols(sumst_comb, drop_scores)

# check that we are not missing any covariates
drop <- sumst_comb$incomplete_cols[!grepl("^PGS", sumst_comb$incomplete_cols)]
if (length(drop) > 0) {
  cat("drop:", "\n", file=log, append=TRUE)
  cat(drop, "\n", file=log, append=TRUE)
  sumst_comb <- drop_cols(sumst_comb, drop)
}

covars <- colnames(sumst_comb$sumstats$xx)[!grepl("^PGS", colnames(sumst_comb$sumstats$xx))]
cat("covars:", "\n", file=log, append=TRUE)
cat(sort(covars), "\n", file=log, append=TRUE)

# penalty factor should be 0 for covariates and 1 for PGS
penalty_factor <- rep(0, ncol(sumst_comb$sumstats$xx))
names(penalty_factor) <- colnames(sumst_comb$sumstats$xx)
penalty_factor[grepl("^PGS", names(penalty_factor))] <- 1
sumst_comb$penalty_factor <- penalty_factor

cat(paste("number of incomplete PRS:", length(sumst_comb$incomplete_cols)), "\n", file=log, append=TRUE)
cat(paste("number of PRS with no variation:", length(sumst_comb$near_zero_var)), "\n", file=log, append=TRUE)

cat(str(sumst_comb$sumstats), "\n", file=log, append=TRUE)
cat(head(colnames(sumst_comb$sumstats$xx)), "\n", file=log, append=TRUE)
cat(tail(colnames(sumst_comb$sumstats$xx)), "\n", file=log, append=TRUE)
saveRDS(sumst_comb, "combined_sumstats.rds")

nobs <- attr(sumst_comb$sumstats, "nobs")
writeLines(as.character(nobs), "nobs.txt")

if (trait_type == "quant") {
  avg_y <- attr(sumst_comb$sumstats, "ysum") / nobs
  cat("y_avg:", avg_y, "\n", file=log, append=TRUE)
} else {
  ncase <- nobs - attr(sumst_comb$sumstats, "ysum")
  nctrl <- nobs - ncase
  cat("n_case:", ncase, "\n", file=log, append=TRUE)
  cat("n_ctrl:", nctrl, "\n", file=log, append=TRUE)
}
covar_avg <- attr(sumst_comb$sumstats, "colsum")[covars] / nobs
cat("covar_avg:", "\n", file=log, append=TRUE)
for (i in seq_along(covar_avg)) cat(names(covar_avg)[i], ":", covar_avg[i], "\n", file=log, append=TRUE)
