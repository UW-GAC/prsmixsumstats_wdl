version 1.0 

workflow get_sample_counts {
    input {
        File sumstat_file
        String trait_type
        String cohort
        Int mem_gb
        Int disk_size
    }

    if (trait_type == "binary") {
        call parse_file_1 {
            input:
                file_input = sumstat_file,
                mem_gb = mem_gb,
                disk_size = disk_size,
        }
    }

    if (trait_type == "quant") {
        call parse_file_2 {
            input:
                file_input = sumstat_file,
                mem_gb = mem_gb,
                disk_size = disk_size,
        }
    }

    call parse_file_3 {
        input:
            file_input = sumstat_file,
            prefix = cohort,
            mem_gb = mem_gb,
            disk_size = disk_size,
    }
    
    output {
        Int? n_total = select_first([parse_file_1.n_total, parse_file_2.n_total])
        Int? n_cases = parse_file_1.n_cases
        Int? n_controls = parse_file_1.n_controls
        Int? n_missing = select_first([parse_file_1.n_missing, parse_file_2.n_missing])
        Int? n_subj = select_first([parse_file_1.n_subj, parse_file_2.n_subj])
        Float? ysum = parse_file_2.ysum
        File colsum_file = parse_file_3.colsum_file
    }

}


task parse_file_1 {
    input {
      File file_input
      Int mem_gb
      Int disk_size
    }
    command <<<
        R << RSCRIPT
            library(tidyverse)
            this_rds_file <- readRDS("~{file_input}")
            this_nobs <- attr(this_rds_file, "nobs")
            this_cases <- attr(this_rds_file, "ysum")
            this_controls <- this_nobs-this_cases
            this_missing <- attr(this_rds_file, "nmiss")
            this_subj <- attr(this_rds_file, "nsubj")

            cat(this_nobs, file="n_total.txt")
            cat(this_cases, file="n_cases.txt")
            cat(this_controls, file="n_controls.txt")
            cat(this_missing, file="n_missing.txt")
            cat(this_subj, file="n_subj.txt")
            
        RSCRIPT
    >>>
    output {
        Int n_total = read_int("n_total.txt")
        Int n_cases = read_int("n_cases.txt")
        Int n_controls = read_int("n_controls.txt")
        Int n_missing = read_int("n_missing.txt")
        Int n_subj = read_int("n_subj.txt")
        
    }
    runtime {
        docker: "rocker/tidyverse:4"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
    }
}

task parse_file_2 {
    input{
        File file_input
        Int mem_gb
        Int disk_size
    }
    command <<<
        R << RSCRIPT
            library(tidyverse)
            this_rds_file <- readRDS("~{file_input}")
            this_nobs <- attr(this_rds_file, "nobs")
            this_missing <- attr(this_rds_file, "nmiss")
            this_subj <- attr(this_rds_file, "nsubj")
            this_ysum <- attr(this_rds_file, "ysum")

            cat(this_nobs, file="n_total.txt")
            cat(this_missing, file="n_missing.txt")
            cat(this_subj, file="n_subj.txt")
            cat(this_ysum, file="ysum.txt")

        RSCRIPT
    >>>
    output {
        Int n_total = read_int("n_total.txt")
        Int n_missing = read_int("n_missing.txt")
        Int n_subj = read_int("n_subj.txt")
        Float ysum = read_float("ysum.txt")
    }
    runtime {
        docker: "rocker/tidyverse:4"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
    }
}

task parse_file_3 {
    input{
        File file_input
        File prefix
        Int mem_gb
        Int disk_size
    }
    command <<<
        R << RSCRIPT
            library(tidyverse)
            this_rds_file <- readRDS("~{file_input}")
            this_colsum <- attr(this_rds_file, "colsum")

            x <- this_colsum
            x_f <- x[!grepl("PGS|PC", names(x))]

            df_covars <- data.frame(
                name = names(x_f),
                value = unname(x_f)
            )
            colsum_file <- paste0("~{prefix}", "_colsum.tsv)
            write.table(df_covars, colsum_file, sep = "\t", row.names = FALSE)

        RSCRIPT
    >>>
    output {
        File colsum_file = "~{prefix}_colsum.tsv"
    }
    runtime {
        docker: "rocker/tidyverse:4"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
    }

}