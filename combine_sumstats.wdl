version 1.0

workflow combine_sumstats {
    input {
        String trait
        String trait_type
        String cluster
        Boolean adjusted
        File drop_scores_file = "gs://fc-a8511200-791a-4375-bccf-fbe41ac3f9f6/drop_scores_AoU_excl.txt"
        String workspace = "PRIMED_LEGACY_analysis"
        String namespace = "primed-analysis"
    }

    call combine {
        input:
            trait = trait,
            trait_type = trait_type,
            cluster = cluster,
            adjusted = adjusted,
            drop_scores_file = drop_scores_file,
            workspace = workspace,
            namespace = namespace
    }

    output {
        File combined_sumstats = combine.sumstats
        File combine_log = combine.log
        Int nobs = combine.nobs
    }
}


task combine {
    input {
        String trait
        String trait_type
        String cluster
        Boolean adjusted
        File drop_scores_file
        String workspace
        String namespace
    }

    command <<<
        wget wget https://raw.githubusercontent.com/UW-GAC/prsmixsumstats_wdl/refs/heads/combine_sumstats/combine_sumstats.R
        Rscript combine_sumstats.R --trait ~{trait} --trait_type ~{trait_type} --cluster ~{cluster} --adjusted ~{adjusted} \
            --drop_scores_file ~{drop_scores_file} --workspace ~{workspace} --namespace ~{namespace}
    >>>

    output {
        File sumstats = "combined_sumstats.rds"
        File log = "log.txt"
        Int nobs = read_int("nobs.txt")
    }

    runtime {
        docker: "uwgac/anvildatamodels:0.8.1"
        memory: "32 GB"
        disks: "local-disk 100 SSD"
    }
}
