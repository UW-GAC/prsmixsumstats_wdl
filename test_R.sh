R -q --vanilla --args \
    --sumstats example_sumstats.rds \
    --maxiter 10 \
    --test \
    < run_glmnet_sumstats.R

R -q --vanilla --args \
    --sumstats example_sumstats.rds \
    --glmnet_fit glmnet_sumstats_fit_grid.rds \
    --metrics glmnet_sumstats_metrics.rds \
    --fit_params alpha_lambda.rds \
    < select_best_model.R
    