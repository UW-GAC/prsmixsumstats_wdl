FROM r-base:4.5.1

RUN apt-get -y update
RUN apt-get -y install python3 python3-pip

RUN Rscript -e 'install.packages(c("remotes", "argparse", "rWishart", "reshape2", "ggplot2"))'
RUN Rscript -e 'remotes::install_github("UW-GAC/prsmixsumstats", upgrade=FALSE)'
