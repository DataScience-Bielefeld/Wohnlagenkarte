FROM rocker/r-ver

# Install additional system package(s), 
# otherwise the installation of R-packages will fail
RUN apt-get update && apt-get install -y \
    libpng-dev \
    && apt-get -y upgrade \
    && rm -rf /var/lib/apt/lists/*

RUN R -e 'install.packages(c("jsonlite", "rlang", "shiny", "leaflet", "dplyr", "sp", "RSQLite", "DBI", "R.utils", "RColorBrewer", "scales", "lattice"))'
