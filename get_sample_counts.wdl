version 1.0

workflow get_sample_counts {
    input {
        File sumstat_file
        String trait_type
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
    
    output {
        Int? n_total = select_first([parse_file_1.n_total, parse_file_2.n_total])
        Int? n_cases = parse_file_1.n_cases
        Int? n_controls = parse_file_1.n_controls
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
            this_rds_file <- readRDS(file_input)
            this_nobs <- attr(this_rds_file, "nobs")
            this_cases <- attr(this_rds_file, "ysum")
            this_controls <- this_nobs-this_ysum

            cat(this_nobs, file="n_total.txt")
            cat(this_cases, file="n_cases.txt")
            cat(this_controls, file="n_controls.txt")
            
        RSCRIPT
    >>>
    output {
        Int n_total = read_int("n_total.txt")
        Int n_cases = read_int("n_cases.txt")
        Int n_controls = read_int("n_controls.txt")
        
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
            this_rds_file <- readRDS(file_input)
            this_nobs <- attr(this_rds_file, "nobs")

            cat(this_nobs, file="n_total.txt")
        RSCRIPT
    >>>
    output {
        Int n_total = read_int("n_total.txt")
    }
    runtime {
        docker: "rocker/tidyverse:4"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"  
    }
}