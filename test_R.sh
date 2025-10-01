R -q --vanilla --args \
    --sumstats example_sumstats.rds \
    --maxiter 50 \
    < run_glmnet_sumstats.R

R -q --vanilla --args \
    --sumstats example_sumstats.rds \
    --glmnet_fit glmnet_sumstats_fit_grid.rds \
    --glmnet_auc glmnet_sumstats_auc.rds \
    --fit_params alpha_lambda.rds \
    --beta_names glmnet_sumstats_beta_names.rds \
    < best_lambda_from_sim.R
    