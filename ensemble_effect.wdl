version 1.0

import "elastic_net_sumstats.wdl" as tasks

workflow ensemble_effect {
    input {
        File sumstats
        File glmnet_fit
        File glmnet_metrics
    }

    call tasks.estimate_effect {
        input:
            sumstats = sumstats,
            glmnet_fit = glmnet_fit,
            glmnet_metrics = glmnet_metrics
    }

    output {
        File effect_file = estimate_effect.effect_file
    }
}
