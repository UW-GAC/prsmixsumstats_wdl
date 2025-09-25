version 1.0

workflow prsmixsumstats {
  input {
    File sumstats_file
    String output_prefix = "prsmix_results"
    Float alpha = 0.5
    Int nfolds = 5
    String docker_image = "rocker/tidyverse:4.3.0"
  }

  call elastic_net_model {
    input:
      sumstats_file = sumstats_file,
      output_prefix = output_prefix,
      alpha = alpha,
      nfolds = nfolds,
      docker_image = docker_image
  }

  output {
    File model_coefficients = elastic_net_model.coefficients
    File model_performance = elastic_net_model.performance
    File model_plot = elastic_net_model.plot
  }
}

task elastic_net_model {
  input {
    File sumstats_file
    String output_prefix
    Float alpha
    Int nfolds
    String docker_image
  }

  command {
    Rscript /scripts/elastic_net_analysis.R \
      --input "${sumstats_file}" \
      --output "${output_prefix}" \
      --alpha ${alpha} \
      --nfolds ${nfolds}
  }

  runtime {
    docker: docker_image
  }

  output {
    File coefficients = "${output_prefix}_coefficients.txt"
    File performance = "${output_prefix}_performance.txt"
    File plot = "${output_prefix}_plot.png"
  }
}