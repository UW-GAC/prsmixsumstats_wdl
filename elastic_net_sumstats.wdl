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
            glmnet_auc = run_glmnet_sumstats.glmnet_auc,
            fit_params = run_glmnet_sumstats.fit_params,
            beta_names = run_glmnet_sumstats.beta_names
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
        File glmnet_loss = "glmnet_sumstats_loss.rds"
        File glmnet_auc = "glmnet_sumstats_auc.rds"
        File glmnet_nbeta = "glmnet_sumstats_nbeta.rds"
        File beta_names = "glmnet_sumstats_beta_names.rds"
        File fit_params = "alpha_lambda.rds"
    }

    runtime {
        docker: "uwgac/prsmixsumstats:0.2.0"
        memory: "16 GB"
        cpu: 4
    }
}

task best_lambda_from_sim {
    input {
        File sumstats
        File glmnet_fit
        File glmnet_auc
        File fit_params
        File beta_names
        Int seed = 123
        Int nsim = 5
    }

    command <<<
        wget https://raw.githubusercontent.com/UW-GAC/prsmixsumstats_wdl/refs/heads/main/best_lambda_from_sim.R
        Rscript best_lambda_from_sim.R \
            --sumstats ~{sumstats} \
            --glmnet_fit ~{glmnet_fit} \
            --glmnet_auc ~{glmnet_auc} \
            --fit_params ~{fit_params} \
            --beta_names ~{beta_names} 
            --seed ~{seed} \
            --nsim ~{nsim}
    >>>

    output {
        File best_model = "best_model.rds"
        File mean_loss_plot = "mean_loss_grid.pdf"
        File hist_beta_plot = "hist_beta_best.pdf"
    }

    runtime {
        docker: "uwgac/prsmixsumstats:0.2.0"
        memory: "16 GB"
        cpu: 4
    }
}
