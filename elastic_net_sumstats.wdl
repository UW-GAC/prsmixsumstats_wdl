version 1.0

workflow elastic_net_sumstats {
    input {
        File sumstats
    }

    call run_glmnet_sumstats {
        input:
            sumstats = sumstats
    }

    call best_lambda_from_sim {
        input:
            sumstats = sumstats,
            glmnet_fit = run_glmnet_sumstats.glmnet_fit,
            fit_params = run_glmnet_sumstats.fit_params
    }

    output {
        File glmnet_fit = run_glmnet_sumstats.glmnet_fit
        File glmnet_metrics = run_glmnet_sumstats.glmnet_metrics
        File best_model = best_lambda_from_sim.best_model
        File mean_loss_plot = best_lambda_from_sim.mean_loss_plot
    }
}

task run_glmnet_sumstats {
    input {
        File sumstats
        Int maxiter = 500
    }

    command <<<
        wget https://raw.githubusercontent.com/UW-GAC/prsmixsumstats_wdl/refs/heads/main/run_glmnet_sumstats.R
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

task best_lambda_from_sim {
    input {
        File sumstats
        File glmnet_fit
        File fit_params
        Int seed = 123
        Int nsim = 5
    }

    command <<<
        wget https://raw.githubusercontent.com/UW-GAC/prsmixsumstats_wdl/refs/heads/main/best_lambda_from_sim.R
        Rscript best_lambda_from_sim.R \
            --sumstats ~{sumstats} \
            --glmnet_fit ~{glmnet_fit} \
            --fit_params ~{fit_params} \
            --seed ~{seed} \
            --nsim ~{nsim}
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
