version 1.0

workflow ensemble_effect {
    input {
        File sumstats
        File glmnet_fit
        File glmnet_metrics
    }

    call effect {
        input:
            sumstats = sumstats,
            glmnet_fit = glmnet_fit,
            glmnet_metrics = glmnet_metrics
    }

    output {
        File effect_file = effect.effect_file
    }
}


task effect {
    input {
        File sumstats
        File glmnet_fit
        File glmnet_metrics
    }

    command <<<
        wget https://raw.githubusercontent.com/UW-GAC/prsmixsumstats_wdl/refs/heads/effect/ensemble_effect.R
        Rscript ensemble_effect.R \
            --sumstats ~{sumstats} \
            --glmnet_fit ~{glmnet_fit} \
            --metrics ~{glmnet_metrics}
    >>>

    output {
        File effect_file = "pgs_effects_min_bic.rds"
    }

    runtime {
        docker: "uwgac/prsmixsumstats:0.3.3"
        memory: "16 GB"
        cpu: 4
    }
}
