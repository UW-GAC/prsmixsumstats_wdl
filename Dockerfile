FROM rocker/tidyverse:4.5

RUN Rscript -e 'install.packages("remotes")'
RUN Rscript -e 'remotes::install_cran(c("argparse", "rWishart", "reshape2"))'
RUN Rscript -e 'remotes::install_github("UW-GAC/prsmixsumstats", upgrade=FALSE)'
