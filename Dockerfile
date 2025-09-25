FROM rocker/tidyverse:4.3.0

# Install additional R packages needed for elastic net analysis
RUN R -e "install.packages(c('glmnet', 'optparse'), repos='https://cran.rstudio.com/')"

# Create scripts directory and copy R script
RUN mkdir -p /scripts
COPY scripts/elastic_net_analysis.R /scripts/

# Make script executable
RUN chmod +x /scripts/elastic_net_analysis.R

WORKDIR /data