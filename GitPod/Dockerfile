FROM rocker/r-ver

RUN mkdir -p /home/gitpod/R/library \
    && R -e 'install.packages(c("jsonlite", "rlang", "shiny", "leaflet", "dplyr", "sp", "RSQLite", "DBI", "R.utils", "RColorBrewer", "scales", "lattice"), lib = "/home/gitpod/R/library")'
