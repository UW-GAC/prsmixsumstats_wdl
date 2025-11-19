version 1.0

workflow elastic_net_sumstats {
    input {
        File sumstats
    }

    call run_glmnet_sumstats {
        input:
            sumstats = sumstats
    }

    call select_best_model {
        input:
            sumstats = sumstats,
            glmnet_fit = run_glmnet_sumstats.glmnet_fit,
            glmnet_metrics = run_glmnet_sumstats.glmnet_metrics,
            fit_params = run_glmnet_sumstats.fit_params
    }

    output {
        File glmnet_fit = run_glmnet_sumstats.glmnet_fit
        File glmnet_metrics = run_glmnet_sumstats.glmnet_metrics
        File best_model = select_best_model.best_model
        File mean_loss_plot = select_best_model.mean_loss_plot
    }
}


task run_glmnet_sumstats {
    input {
        File sumstats
        Int maxiter = 500
    }

    command <<<
        wget https://raw.githubusercontent.com/UW-GAC/prsmixsumstats_wdl/refs/heads/new_glmnet/run_glmnet_sumstats.R
        Rscript run_glmnet_sumstats.R --sumstats ~{sumstats} --maxiter ~{maxiter}
    >>>

    output {
        File glmnet_fit = "glmnet_sumstats_fit_grid.rds"
        File glmnet_metrics = "glmnet_sumstats_metrics.rds"
        File fit_params = "alpha_lambda.rds"
    }

    runtime {
        docker: "uwgac/prsmixsumstats:0.1.0"
        memory: "16 GB"
        cpu: 4
    }
}


task select_best_model {
    input {
        File sumstats
        File glmnet_fit
        File glmnet_metrics
        File fit_params
    }

    command <<<
        wget https://raw.githubusercontent.com/UW-GAC/prsmixsumstats_wdl/refs/heads/new_glmnet/select_best_model.R
        Rscript select_best_model.R \
            --sumstats ~{sumstats} \
            --glmnet_fit ~{glmnet_fit} \
            --glmnet_metrics ~{glmnet_metrics} \
            --fit_params ~{fit_params}
    >>>

    output {
        File best_model = "best_model.rds"
        File mean_loss_plot = "mean_loss_grid.pdf"
    }

    runtime {
        docker: "uwgac/prsmixsumstats:0.1.0"
        memory: "16 GB"
        cpu: 4
    }
}
