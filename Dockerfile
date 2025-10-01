FROM rocker/tidyverse:4

RUN Rscript -e 'remotes::install_cran(c("argparser", "rWishart", "reshape2"))'
RUN Rscript -e 'remotes::install_github("UW-GAC/prsmixsumstats", upgrade=FALSE)'
